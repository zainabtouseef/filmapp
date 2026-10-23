"""Upload supplied photos through CineConnect's scanner, then link live profiles."""

from __future__ import annotations

import hashlib
import json
import subprocess
import time
from pathlib import Path

import requests


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "output"
PHOTO_DIR = OUTPUT / "profile-photos"
PRIVATE = OUTPUT / "private"
CREDS = PRIVATE / "CineConnect_New_Logins_2026-10-17.txt"
PROGRESS = PRIVATE / "CineConnect_Oct17_Photo_Uploads.json"
API = "https://cineconnect.net/api/v1"
KEY = "/Users/abdulbasit/Downloads/abc123.txt"
HOST = "root@srv951538.hstgr.cloud"
SOURCES = [
    ("ghalib.mirza", "WhatsApp Image 2026-10-16 at 15.41.19.jpeg"),
    ("clubhouse.lahore", "WhatsApp Image 2026-10-16 at 16.00.49.jpeg"),
    ("clubhouse.lahore", "WhatsApp Image 2026-10-16 at 16.00.58.jpeg"),
    ("clubhouse.lahore", "WhatsApp Image 2026-10-16 at 16.01.10.jpeg"),
    ("clubhouse.lahore", "WhatsApp Image 2026-10-16 at 16.01.53.jpeg"),
    ("usmanraaj4", "WhatsApp Image 2026-10-16 at 16.39.45.jpeg"),
]


def request_data(session: requests.Session, method: str, url: str, **kwargs: object) -> dict:
    response = session.request(method, url, timeout=45, **kwargs)
    if not response.ok:
        try:
            code = response.json().get("error", {}).get("code", "request_failed")
        except ValueError:
            code = "request_failed"
        raise RuntimeError(f"{method} {url.split('?')[0]}: HTTP {response.status_code} ({code})")
    return response.json()["data"]


def credentials() -> dict[str, str]:
    result = {}
    for line in CREDS.read_text().splitlines()[1:]:
        parts = {}
        for entry in line.split(" | ")[1:]:
            key, value = entry.split(": ", 1)
            parts[key] = value
        result[parts["username"]] = parts["password"]
    return result


def save_progress(progress: dict) -> None:
    PROGRESS.write_text(json.dumps(progress, indent=2) + "\n")
    PROGRESS.chmod(0o600)


def ready_file(session: requests.Session, file_id: str) -> dict:
    for _ in range(90):
        file = request_data(session, "GET", f"{API}/files/{file_id}")["file"]
        if file["scan_status"] == "clean" and file["processing_status"] == "ready":
            return file
        if file["scan_status"] not in {"pending", "clean"} or file["processing_status"] not in {"pending", "ready"}:
            raise RuntimeError(f"Scan failed for {file_id}: {file['scan_status']}")
        time.sleep(2)
    raise RuntimeError(f"Scan timed out for {file_id}")


def main() -> None:
    missing = [name for _, name in SOURCES if not (PHOTO_DIR / name).is_file()]
    if missing:
        raise SystemExit("Missing photos in output/profile-photos/: " + ", ".join(missing))

    passwords = credentials()
    progress = json.loads(PROGRESS.read_text()) if PROGRESS.exists() else {}
    sessions: dict[str, requests.Session] = {}
    manifest = []
    for username, name in SOURCES:
        source = PHOTO_DIR / name
        checksum = hashlib.sha256(source.read_bytes()).hexdigest()
        if username not in sessions:
            session = requests.Session()
            login = request_data(session, "POST", f"{API}/auth/login",
                                 json={"email": username, "password": passwords[username]})
            session.headers["Authorization"] = f"Bearer {login['tokens']['access_token']}"
            sessions[username] = session
        session = sessions[username]

        saved = progress.get(name)
        if saved and saved.get("checksum") == checksum and saved.get("username") == username:
            file_id = saved["file_id"]
        else:
            presign = request_data(session, "POST", f"{API}/uploads/presign", json={
                "purpose": "location_media" if username == "clubhouse.lahore" else "profile_media",
                "mime_type": "image/jpeg", "original_name": name,
                "size_bytes": source.stat().st_size,
            })
            with source.open("rb") as stream:
                binary = request_data(session, "PUT", presign["upload_url"],
                                      data=stream, headers={"Content-Type": "image/jpeg"})
            if binary["checksum_sha256"] != checksum:
                raise RuntimeError(f"Upload bytes differ: {name}")
            complete = request_data(
                session, "POST", f"{API}/uploads/{presign['upload_session_id']}/complete"
            )
            file_id = complete["file"]["public_id"]
            progress[name] = {"username": username, "checksum": checksum, "file_id": file_id}
            save_progress(progress)

        file = ready_file(session, file_id)
        if not file.get("public_url"):
            raise RuntimeError(f"Ready file has no public URL: {file_id}")
        manifest.append({"username": username, "name": name, "checksum": checksum, "file_id": file_id})
        print(username, name, "clean and ready", flush=True)

    server_script = r'''
import hashlib
import json
from sqlalchemy import select
from app import create_app
from app.extensions import db
from app.models.identity import User
from app.models.files import FileAsset
from app.models.marketplace import UserProfile, MarketplaceListing, ListingMedia
from app.models.operations import LocationProperty
from app.services.local_storage import resolve_path

manifest = json.loads(MANIFEST_JSON)
app = create_app()
with app.app_context():
    targets = {}
    for item in manifest:
        user = db.session.scalar(select(User).where(User.username == item['username']))
        if user is None:
            raise RuntimeError('User missing: ' + item['username'])
        profile = db.session.scalar(select(UserProfile).where(UserProfile.user_id == user.id))
        if profile is None:
            raise RuntimeError('Profile missing: ' + item['username'])
        kind = 'location' if item['username'] == 'clubhouse.lahore' else 'actor'
        listing = db.session.scalar(select(MarketplaceListing).where(
            MarketplaceListing.owner_user_id == user.id, MarketplaceListing.listing_type == kind
        ))
        if listing is None:
            raise RuntimeError('Listing missing: ' + item['username'])
        if kind == 'location':
            location = db.session.scalar(select(LocationProperty).where(
                LocationProperty.public_id == listing.profile_entity_id,
                LocationProperty.owner_user_id == user.id
            ))
            if location is None:
                raise RuntimeError('Location listing is unlinked')
        file = db.session.scalar(select(FileAsset).where(FileAsset.public_id == item['file_id']))
        if file is None or file.owner_user_id != user.id:
            raise RuntimeError('File missing or owned by another account')
        if file.checksum_sha256 != item['checksum'] or file.mime_type != 'image/jpeg':
            raise RuntimeError('File identity mismatch: ' + item['name'])
        if file.visibility != 'public' or file.scan_status != 'clean' or file.processing_status != 'ready':
            raise RuntimeError('File is not approved for public display: ' + item['name'])
        if hashlib.sha256(resolve_path(file).read_bytes()).hexdigest() != item['checksum']:
            raise RuntimeError('Stored bytes mismatch: ' + item['name'])
        targets.setdefault(item['username'], (profile, listing, []))[2].append(file)

    for username, (profile, listing, files) in targets.items():
        profile.avatar_file_id = files[0].id
        if username == 'clubhouse.lahore':
            profile.cover_file_id = files[0].id
        existing = {media.file_id: media for media in listing.media}
        for order, file in enumerate(files, start=1):
            media = existing.get(file.id)
            if media is None:
                media = ListingMedia(listing_id=listing.id, file_id=file.id)
                db.session.add(media)
            media.sort_order = order
            media.is_cover = order == 1
    db.session.commit()
    for username, (_, _, files) in targets.items():
        print(username, 'photos_attached', len(files))
'''
    server_script = "MANIFEST_JSON = " + repr(json.dumps(manifest)) + "\n" + server_script
    result = subprocess.run(
        ["ssh", "-i", KEY, "-o", "BatchMode=yes", HOST,
         "cd /var/www/cineconnect-net && docker compose exec -T api python -"],
        input=server_script, text=True, capture_output=True, check=True
    )
    print(result.stdout, end="")

    for item in manifest:
        session = sessions[item["username"]]
        file = request_data(session, "GET", f"{API}/files/{item['file_id']}")["file"]
        response = session.get(file["public_url"], timeout=30)
        response.raise_for_status()
        if hashlib.sha256(response.content).hexdigest() != item["checksum"]:
            raise RuntimeError(f"Public bytes differ: {item['name']}")
    print("All six public images returned their original bytes")


if __name__ == "__main__":
    main()
