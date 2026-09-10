from flask import Flask

from app.models.files import FileAsset
from app.services.local_storage import public_url_for


def _public_file(*, checksum: str | None = None) -> FileAsset:
    return FileAsset(
        public_id="FILE-TEST",
        owner_user_id="00000000-0000-0000-0000-000000000001",
        storage_key="demo/campaign.jpg",
        bucket="public",
        mime_type="image/jpeg",
        size_bytes=128,
        checksum_sha256=checksum,
        visibility="public",
        scan_status="clean",
        processing_status="ready",
        original_name="campaign.jpg",
    )


def test_public_url_uses_content_checksum_as_cache_version() -> None:
    app = Flask(__name__)
    app.config["PUBLIC_MEDIA_BASE_URL"] = "https://media.test"
    file = _public_file(checksum="ABCDEF0123456789")

    with app.app_context():
        assert public_url_for(file) == (
            "https://media.test/demo/campaign.jpg?v=abcdef012345"
        )


def test_non_public_file_has_no_public_url() -> None:
    app = Flask(__name__)
    app.config["PUBLIC_MEDIA_BASE_URL"] = "https://media.test"
    file = _public_file(checksum="abcdef0123456789")
    file.visibility = "private"

    with app.app_context():
        assert public_url_for(file) is None
