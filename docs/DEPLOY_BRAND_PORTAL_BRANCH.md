# Deploy runbook — `refactor/theme-system` (Brand portal + CinePlanner)

This branch adds the Brand campaign workspace (BR‑08…BR‑11), the shared
`TalentProfileShowcase` profile hero, the CinePlanner production console, and
marketplace equipment/crew listings. Everything below is what is **new or
changed** for a deploy; the rest of your existing
[`DEPLOYMENT_INPUTS.md`](DEPLOYMENT_INPUTS.md) process is unchanged.

Local verification passing on this branch:

| Check | Result |
|---|---|
| `flutter analyze` | **No issues found** (0) |
| `flutter test` | **738 / 738 pass** |
| `flutter build web --release` | builds (`build/web`) |
| `ruff check backend` | **All checks passed** (whole tree) |
| `ruff format --check backend` | **clean** (whole tree) |
| `mypy backend/app` | **0 errors** |
| backend unit tests | **24 / 24 pass** |
| backend `test_brand_portal_flow.py` + `test_cineplanner_flow.py` | **4 / 4 pass** |

Not runnable here (Docker Desktop won't start on this machine): the ~40
MySQL/Redis integration tests — your GitHub `Backend` workflow runs them.

---

## 0. Before anything — rotate the leaked SSH key

The `abc123 (2).txt` private key (`root@srv951538`) was pasted into a chat and
must be treated as compromised.

```bash
# on the server, logged in through a session you already trust
ssh-keygen -lf ~/.ssh/authorized_keys                 # identify the bad key line
sed -i.bak '/<comment-or-fingerprint-of-leaked-key>/d' ~/.ssh/authorized_keys
# add a fresh key you generate locally:
#   ssh-keygen -t ed25519 -f ~/.ssh/cineconnect_deploy -C "deploy@cineconnect"
# then paste the new .pub into authorized_keys
```

Recommended hardening while you are there: `PermitRootLogin no` +
`PasswordAuthentication no` in `/etc/ssh/sshd_config`, deploy as a non‑root
`deploy` user with `sudo` only for the docker commands.

---

## 1. New environment variables (`/var/www/cineconnect/release/backend/.env`)

Append (values from `backend/.env.example`):

```ini
# Backend only — never expose via Flutter --dart-define or web assets
OPENAI_API_KEY=
OPENAI_SCREENPLAY_MODEL=gpt-5-mini
CINEPLANNER_AI_PARALLELISM=4
CINEPLANNER_AI_ENABLED=true
```

Decision required:

- **If you have an OpenAI key** → set `OPENAI_API_KEY=sk-…`. CinePlanner's
  screenplay breakdown / scheduling AI will work.
- **If you do not** → set `CINEPLANNER_AI_ENABLED=false`. The console still
  loads (productions, budget, schedule, call sheets, team) — only the AI
  breakdown button is inert.

> `Config.validate()` raises `OPENAI_API_KEY is required when CinePlanner AI is
> enabled` **only when `APP_ENV=production`**. Your server runs
> `APP_ENV=development`/`staging`, so a missing key will not block boot today —
> but the AI calls will fail at runtime until one of the two options above is
> applied.

No other new env vars. `CORS_ALLOWED_ORIGINS`, DB, Redis, storage: unchanged.

---

## 2. Sync code

```bash
# from your machine, with the NEW deploy key
rsync -az --delete \
  --exclude '.venv' --exclude '__pycache__' --exclude '.dart_tool' \
  --exclude 'build' --exclude '.git' \
  ./ deploy@cine.nalexustechnologies.com:/var/www/cineconnect/release/
```

(Or `git fetch && git checkout refactor/theme-system && git pull` if the server
has a checkout. This branch is currently **uncommitted working tree** — commit
it first; see §6.)

---

## 3. Database migration (required)

One new Alembic revision:
`backend/migrations/versions/c1e2f3a4b5c6_cineplanner_production_console.py`
(CinePlanner tables: productions, script versions, scenes, characters,
elements, cast/crew, locations, shoot days, budget lines, call sheets,
schedule events, conflicts, AI jobs, audit log).

```bash
cd /var/www/cineconnect/release
docker run --rm --network host --env-file backend/.env \
  -w /app cineconnect-api \
  flask --app app.wsgi db upgrade -d migrations
```

Roll back (if needed): `flask --app app.wsgi db downgrade -d migrations -1`.

---

## 4. Rebuild & restart containers

```bash
cd /var/www/cineconnect/release
docker build -f backend/Dockerfile -t cineconnect-api .

for c in cineconnect-api cineconnect-worker cineconnect-scheduler; do
  docker rm -f "$c" 2>/dev/null || true
done

docker run -d --name cineconnect-api --network host --restart unless-stopped \
  --env-file backend/.env -v /var/www/cineconnect/storage:/data/storage \
  cineconnect-api \
  gunicorn --bind 127.0.0.1:5002 --workers 2 --threads 4 --timeout 60 \
  --access-logfile - app.wsgi:app

docker run -d --name cineconnect-worker --network host --restart unless-stopped \
  --env-file backend/.env -v /var/www/cineconnect/storage:/data/storage \
  cineconnect-api \
  celery -A app.celery_app:celery worker --loglevel=INFO --concurrency=2

docker run -d --name cineconnect-scheduler --network host --restart unless-stopped \
  --env-file backend/.env cineconnect-api \
  celery -A app.celery_app:celery beat --loglevel=INFO
```

Smoke test:

```bash
curl -fsS https://cine.nalexustechnologies.com/api/v1/health
curl -fsS https://cine.nalexustechnologies.com/api/v1/openapi.yaml | head -c 200
```

---

## 5. Frontend web build

```bash
# on a machine with Flutter 3.44.x
flutter pub get
flutter build web --release --dart-define=CINECONNECT_API_BASE_URL=https://cine.nalexustechnologies.com/api/v1
rsync -az --delete build/web/ \
  deploy@cine.nalexustechnologies.com:<your Flutter-web document root>
```

Use the same document root your current production web build is served from
(the Nginx vhost keeps `/var/www/cineconnect/bootstrap` as a placeholder and
proxies `/` to the API — confirm where the built SPA actually lands in your
setup before overwriting).

---

## 6. Demo data (optional, for the guided Brand walkthrough)

Seeds the **"Nova Cola Winter Stories"** end‑to‑end journey: brand project +
5 requirements (talent/model/crew/location/equipment), a 5‑candidate shortlist,
5 bookings spanning `sent → viewed → under_negotiation → accepted → secured`,
conversations, notifications, and an approved Brand KYC.

Prerequisite: demo seed slices 1–3 must already be applied (they create
`brand01@demo.cine.nalexustechnologies.com`, city Lahore, role `brand_sponsor`,
and the base listings this script references).

```bash
docker run --rm --network host --env-file backend/.env \
  -e CINECONNECT_ALLOW_DEMO_SEED=1 \
  -w /app cineconnect-api \
  python scripts/seed_brand_portal_demo.py
```

Demo login after seeding: `brand01@demo.cine.nalexustechnologies.com` /
`CineDemo@2026!`

The script is idempotent (`ensure(...)` upserts) — safe to re‑run.

---

## 7. Commit the branch

The working tree is currently uncommitted. Suggested split:

```bash
git add backend/ docs/ .github/workflows/flutter.yml
git commit -m "Add CinePlanner console + brand marketplace API; fix mypy/lint debt"

git add lib/ test/ web/
git commit -m "Add brand campaign workspace, shared talent showcase hero, Flutter CI"
```

CI added this pass: `.github/workflows/flutter.yml` runs
`flutter analyze` + `flutter test` + `flutter build web` (pinned Flutter
3.44.8) on every push touching `lib/`, `test/`, `web/`, or `pubspec*`.

Your existing `Backend` workflow (`ruff check` / `ruff format --check` /
`mypy` / integration `pytest`) is now green tree‑wide — it had been failing
on ~230 lint findings in `migrations/` and `scripts/`, which are resolved
this pass (real dead code removed; generated Alembic files and sys.path
bootstrap scripts covered by `[tool.ruff.lint.per-file-ignores]`).

---

## Rollback

- Frontend: `rsync` the previous `build/web` back.
- Backend: `docker run … <previous image tag>` for the three containers.
- DB: `flask --app app.wsgi db downgrade -d migrations -1` (drops the
  CinePlanner tables; Brand portal itself uses only pre‑existing tables, so a
  Brand‑only deploy can skip the migration entirely if you also disable the
  CinePlanner route).
