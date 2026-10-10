"""Disposable local integration UI fixture; never targets a hosted database."""
from __future__ import annotations

import os
from urllib.parse import urlparse

from app import create_app

database = urlparse(os.environ.get("DATABASE_URL", ""))
if database.hostname != "127.0.0.1" or database.path != "/cineconnect_qa":
    raise SystemExit("QA launcher requires the isolated local cineconnect_qa database")
if os.environ.get("APP_ENV") != "test":
    raise SystemExit("QA launcher requires APP_ENV=test")

app = create_app()
client = app.test_client()
response = client.post("/api/v1/auth/register", json={
    "email": "director-ui-qa@example.com",
    "password": "LocalCineQA2026!",
    "display_name": "Local QA Director",
    "initial_role": "director_producer",
    "terms_version": "local-test-only",
})
if response.status_code not in {201, 409}:
    raise SystemExit(f"Unable to prepare local QA account ({response.status_code})")

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=15002, debug=False)
