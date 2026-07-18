# CineConnect API

Flask, MySQL 8.4, Redis, Celery, and S3-compatible object storage foundation.

## Local start

Create the ignored local environment file from `.env.example`, then:

```bash
docker compose up -d mysql redis minio
docker compose run --rm api flask --app app.wsgi db upgrade -d migrations
docker compose up --build api worker scheduler
```

The API is available at `http://127.0.0.1:5000/api/v1`.

## Verification

```bash
.venv/bin/ruff check backend
.venv/bin/ruff format --check backend
.venv/bin/mypy --config-file backend/pyproject.toml backend/app
.venv/bin/pytest backend/tests/unit --cov=backend/app

RUN_INTEGRATION_TESTS=1 \
TEST_DATABASE_URL='mysql+pymysql://cineconnect:local-only-password@127.0.0.1:3307/cineconnect?charset=utf8mb4' \
TEST_REDIS_URL='redis://127.0.0.1:6380/15' \
.venv/bin/pytest backend/tests
```

Never point tests at production. Sandbox payments are forbidden when
`APP_ENV=production`.
