from __future__ import annotations

import os
import uuid

import pytest
from flask.testing import FlaskClient
from sqlalchemy import select

from app.extensions import db
from app.models.files import FileAsset
from app.models.identity import Role, User
from app.models.kyc import KycSubmission

pytestmark = [
    pytest.mark.integration,
    pytest.mark.skipif(
        os.getenv("RUN_INTEGRATION_TESTS") != "1",
        reason="Set RUN_INTEGRATION_TESTS=1 with MySQL and Redis running.",
    ),
]


def _register(client: FlaskClient) -> tuple[dict[str, str], str]:
    return _register_role(client, "actor_talent")


def _register_role(client: FlaskClient, role: str) -> tuple[dict[str, str], str]:
    email = f"market-{uuid.uuid4().hex[:12]}@example.com"
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "password": "StrongPass123!",
            "display_name": "Marketplace Talent",
            "initial_role": role,
            "terms_version": "2026-07",
        },
    )
    assert response.status_code == 201, response.text
    token = response.json["data"]["tokens"]["access_token"]
    return {"Authorization": f"Bearer {token}"}, response.json["data"]["user"][
        "public_id"
    ]


def _approve_actor_kyc(client: FlaskClient, user_public_id: str) -> None:
    with client.application.app_context():
        user = db.session.execute(
            select(User).where(User.public_id == user_public_id)
        ).scalar_one()
        role = db.session.execute(
            select(Role).where(Role.code == "actor_talent")
        ).scalar_one()
        db.session.add(
            KycSubmission(
                user_id=user.id,
                role_id=role.id,
                status="approved",
                risk_level="low",
            )
        )
        db.session.commit()


def _file_for_user(
    client: FlaskClient,
    user_public_id: str,
    *,
    scan_status: str = "clean",
    processing_status: str = "ready",
) -> str:
    with client.application.app_context():
        user = db.session.execute(
            select(User).where(User.public_id == user_public_id)
        ).scalar_one()
        file = FileAsset(
            owner_user_id=user.id,
            storage_key=f"portfolio/{uuid.uuid4().hex}.jpg",
            bucket="local-private",
            mime_type="image/jpeg",
            size_bytes=123456,
            checksum_sha256="1" * 64,
            visibility="public",
            scan_status=scan_status,
            processing_status=processing_status,
            original_name="headshot.jpg",
        )
        db.session.add(file)
        db.session.commit()
        return file.public_id


def test_profile_talent_and_marketplace_listing_flow(client: FlaskClient) -> None:
    headers, user_public_id = _register(client)

    cities = client.get("/api/v1/cities")
    assert cities.status_code == 200
    lahore = next(
        city
        for city in cities.json["data"]["cities"]
        if city["public_id"] == "CITY-LHE"
    )

    base_profile = client.patch(
        "/api/v1/me/profile",
        headers=headers,
        json={
            "bio": "Actor focused on TVCs, drama and branded content.",
            "city_id": lahore["public_id"],
            "website_url": "https://example.com/portfolio",
            "profile_visibility": "public",
        },
    )
    assert base_profile.status_code == 200, base_profile.text
    assert base_profile.json["data"]["profile"]["city"]["name"] == "Lahore"

    talent = client.patch(
        "/api/v1/talent/profile",
        headers=headers,
        json={
            "screen_name": "Ali Marketplace",
            "age_range": "28-35",
            "gender_identity": "male",
            "height_cm": 180,
            "experience_years": 8,
            "availability_status": "available",
            "day_rate_minor": 14000000,
            "currency": "PKR",
            "languages": [
                {"language": "Urdu", "proficiency": "native"},
                {"language": "English", "proficiency": "professional"},
            ],
        },
    )
    assert talent.status_code == 200, talent.text
    assert talent.json["data"]["talent_profile"]["screen_name"] == "Ali Marketplace"

    blocked = client.post(
        "/api/v1/marketplace/listings",
        headers=headers,
        json={
            "listing_type": "talent",
            "title": "Ali Marketplace — Actor",
            "summary": "Lead actor for drama, TVC and branded campaign shoots.",
            "city_id": lahore["public_id"],
        },
    )
    assert blocked.status_code == 403
    assert blocked.json["error"]["code"] == "marketplace.kyc_required"

    _approve_actor_kyc(client, user_public_id)
    file_id = _file_for_user(client, user_public_id)
    portfolio = client.post(
        "/api/v1/portfolio",
        headers=headers,
        json={
            "profile_type": "talent",
            "title": "Drama Headshot",
            "category": "headshot",
            "file_id": file_id,
            "status": "published",
            "is_cover": True,
            "sort_order": 1,
        },
    )
    assert portfolio.status_code == 201, portfolio.text
    portfolio_id = portfolio.json["data"]["item"]["public_id"]

    portfolio_list = client.get(
        "/api/v1/portfolio?profile_type=talent", headers=headers
    )
    assert portfolio_list.status_code == 200
    assert any(
        item["public_id"] == portfolio_id
        for item in portfolio_list.json["data"]["items"]
    )

    published = client.post(
        "/api/v1/marketplace/listings",
        headers=headers,
        json={
            "listing_type": "talent",
            "title": "Ali Marketplace — Actor",
            "summary": "Lead actor for drama, TVC and branded campaign shoots.",
            "city_id": lahore["public_id"],
            "portfolio_item_ids": [portfolio_id],
        },
    )
    assert published.status_code == 201, published.text
    listing_id = published.json["data"]["listing"]["public_id"]
    assert published.json["data"]["listing"]["media"][0]["file"]["public_id"] == file_id

    search = client.get("/api/v1/marketplace/listings?type=talent&q=Ali")
    assert search.status_code == 200
    assert any(
        item["public_id"] == listing_id for item in search.json["data"]["listings"]
    )

    detail = client.get(f"/api/v1/marketplace/listings/{listing_id}")
    assert detail.status_code == 200
    assert detail.json["data"]["listing"]["title"] == "Ali Marketplace — Actor"
    assert detail.json["data"]["listing"]["media"][0]["caption"] == "Drama Headshot"

    facets = client.get("/api/v1/marketplace/facets")
    assert facets.status_code == 200
    assert any(
        item["type"] == "talent" for item in facets.json["data"]["listing_types"]
    )


def test_portfolio_media_validation_update_and_direct_listing_media(
    client: FlaskClient,
) -> None:
    headers, user_public_id = _register(client)

    missing_profile = client.get("/api/v1/portfolio", headers=headers)
    assert missing_profile.status_code == 409

    talent = client.patch(
        "/api/v1/talent/profile",
        headers=headers,
        json={"screen_name": "Media Actor", "currency": "PKR"},
    )
    assert talent.status_code == 200, talent.text

    bad_profile_type = client.get(
        "/api/v1/portfolio?profile_type=crew", headers=headers
    )
    assert bad_profile_type.status_code == 422

    pending_file_id = _file_for_user(
        client,
        user_public_id,
        scan_status="pending",
        processing_status="pending",
    )
    blocked_file = client.post(
        "/api/v1/portfolio",
        headers=headers,
        json={
            "title": "Pending Media",
            "category": "showreel",
            "file_id": pending_file_id,
        },
    )
    assert blocked_file.status_code == 422

    file_id = _file_for_user(client, user_public_id)
    thumbnail_id = _file_for_user(client, user_public_id)
    created = client.post(
        "/api/v1/portfolio",
        headers=headers,
        json={
            "title": "Direct Media Reel",
            "category": "showreel",
            "file_id": file_id,
            "thumbnail_file_id": thumbnail_id,
            "status": "draft",
            "duration_seconds": 91,
            "sort_order": 4,
        },
    )
    assert created.status_code == 201, created.text
    item_id = created.json["data"]["item"]["public_id"]
    assert created.json["data"]["item"]["thumbnail_file"]["public_id"] == thumbnail_id

    patched = client.patch(
        f"/api/v1/portfolio/{item_id}",
        headers=headers,
        json={
            "title": "Published Direct Media Reel",
            "status": "published",
            "is_cover": True,
            "sort_order": 1,
        },
    )
    assert patched.status_code == 200, patched.text
    assert patched.json["data"]["item"]["status"] == "published"

    _approve_actor_kyc(client, user_public_id)
    published = client.post(
        "/api/v1/marketplace/listings",
        headers=headers,
        json={
            "listing_type": "talent",
            "title": "Media Actor",
            "summary": "Actor with a clean portfolio reel ready for producers.",
            "media_file_ids": [file_id, file_id],
        },
    )
    assert published.status_code == 201, published.text
    assert len(published.json["data"]["listing"]["media"]) == 1
    assert published.json["data"]["listing"]["media"][0]["caption"] is None

    missing = client.patch(
        "/api/v1/portfolio/PORT-DOES-NOT-EXIST",
        headers=headers,
        json={"title": "Nope"},
    )
    assert missing.status_code == 404

    deleted = client.delete(f"/api/v1/portfolio/{item_id}", headers=headers)
    assert deleted.status_code == 200
    assert deleted.json["data"]["deleted"] is True


def test_saved_searches_result_count_and_shortlists(client: FlaskClient) -> None:
    actor_headers, actor_public_id = _register(client)
    director_headers, _director_public_id = _register_role(client, "director_producer")

    lahore = next(
        city
        for city in client.get("/api/v1/cities").json["data"]["cities"]
        if city["public_id"] == "CITY-LHE"
    )
    profile = client.patch(
        "/api/v1/talent/profile",
        headers=actor_headers,
        json={
            "screen_name": "Shortlist Actor",
            "currency": "PKR",
            "languages": [{"language": "Urdu", "proficiency": "native"}],
        },
    )
    assert profile.status_code == 200, profile.text
    _approve_actor_kyc(client, actor_public_id)
    published = client.post(
        "/api/v1/marketplace/listings",
        headers=actor_headers,
        json={
            "listing_type": "talent",
            "title": "Shortlist Actor",
            "summary": "Verified actor available for shortlist testing.",
            "city_id": lahore["public_id"],
        },
    )
    assert published.status_code == 201, published.text
    listing_id = published.json["data"]["listing"]["public_id"]

    count = client.post(
        "/api/v1/marketplace/result-count",
        json={"listing_type": "talent", "city_id": lahore["public_id"], "q": "Actor"},
    )
    assert count.status_code == 200
    assert count.json["data"]["count"] >= 1

    saved = client.post(
        "/api/v1/saved-searches",
        headers=director_headers,
        json={
            "name": "Lahore actors",
            "listing_type": "talent",
            "city_id": lahore["public_id"],
            "query_text": "Actor",
            "filters": {"availability": "available"},
            "notify_enabled": True,
        },
    )
    assert saved.status_code == 201, saved.text
    saved_id = saved.json["data"]["saved_search"]["public_id"]
    saved_list = client.get("/api/v1/saved-searches", headers=director_headers)
    assert saved_list.status_code == 200
    assert any(
        item["public_id"] == saved_id
        for item in saved_list.json["data"]["saved_searches"]
    )

    board = client.post(
        "/api/v1/shortlists",
        headers=director_headers,
        json={"name": "Lead father shortlist"},
    )
    assert board.status_code == 201, board.text
    board_id = board.json["data"]["shortlist"]["public_id"]

    item = client.post(
        f"/api/v1/shortlists/{board_id}/items",
        headers=director_headers,
        json={"listing_id": listing_id, "rank": 1, "notes": "Strong fit"},
    )
    assert item.status_code == 201, item.text
    item_id = item.json["data"]["item"]["public_id"]

    duplicate = client.post(
        f"/api/v1/shortlists/{board_id}/items",
        headers=director_headers,
        json={"listing_id": listing_id, "rank": 2, "notes": "Updated note"},
    )
    assert duplicate.status_code == 200
    assert duplicate.json["data"]["item"]["rank"] == 2

    patched = client.patch(
        f"/api/v1/shortlist-items/{item_id}",
        headers=director_headers,
        json={"rank": 3, "status": "selected", "notes": "Selected for callback"},
    )
    assert patched.status_code == 200
    assert patched.json["data"]["item"]["status"] == "selected"

    boards = client.get("/api/v1/shortlists", headers=director_headers)
    assert boards.status_code == 200
    assert boards.json["data"]["shortlists"][0]["items"][0]["public_id"] == item_id

    other_headers, _ = _register_role(client, "director_producer")
    forbidden_by_scope = client.patch(
        f"/api/v1/shortlist-items/{item_id}",
        headers=other_headers,
        json={"status": "archived"},
    )
    assert forbidden_by_scope.status_code == 404

    deleted_item = client.delete(
        f"/api/v1/shortlist-items/{item_id}", headers=director_headers
    )
    assert deleted_item.status_code == 200
    deleted_search = client.delete(
        f"/api/v1/saved-searches/{saved_id}", headers=director_headers
    )
    assert deleted_search.status_code == 200
