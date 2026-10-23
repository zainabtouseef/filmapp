from __future__ import annotations

import json
from datetime import timedelta
from types import SimpleNamespace
from unittest.mock import patch

import pytest
from sqlalchemy import select

from app.extensions import db
from app.models.base import utc_now
from app.models.cineplanner import CineProduction, CineScene
from app.models.cineplanner_access import CineAssistantMessage, CineMembership
from app.models.files import FileAsset
from app.models.identity import Role, User, UserRole
from app.security import hash_password, issue_token_pair
from app.services.cineplanner_ai import _request_section_stage, _request_stage
from app.services.cineplanner_editor import (
    editor_context,
    latest_script,
    prepare_changes,
)
from app.services.cineplanner_source import (
    SourceScene,
    SourceSection,
    merge_results,
    sections,
    source_scenes,
)
from tests.unit.test_cineplanner_edits import production as production
from tests.unit.test_cineplanner_edits import request


def _owner():
    p = db.session.scalar(select(CineProduction))
    return p, db.session.get(User, p.owner_user_id)


def _activate(app, *, used=0, expired=False):
    app.config["CINEPLANNER_BILLING_ENABLED"] = True
    with app.app_context():
        _, owner = _owner()
        row = CineMembership(
            user_id=owner.id,
            access_mode="subscription",
            period_start=utc_now(),
            period_end=utc_now() + timedelta(days=-1 if expired else 28),
            alterations_used=used,
        )
        db.session.add(row)
        db.session.commit()


def _proposal(app, *, add=False):
    with app.app_context():
        p, owner = _owner()
        scene = db.session.scalar(
            select(CineScene)
            .where(CineScene.production_id == p.id)
            .order_by(CineScene.sort_order)
        )
        scene.source_text = "Original dialogue and action."
        db.session.flush()
        context = editor_context(p, "Improve scene one", scene.public_id)
        raw = {
            "resource": "scenes",
            "action": "add" if add else "update",
            "target_id": None if add else scene.public_id,
            "fields_json": json.dumps(
                {
                    "scene_number": "900",
                    "slugline": "INT. NEW ROOM - DAY",
                    "source_text": "New original scene.",
                    "summary": "Added scene.",
                }
                if add
                else {"summary": "A carefully revised summary."}
            ),
        }
        message = CineAssistantMessage(
            production_id=p.id,
            user_id=owner.id,
            script_version_id=latest_script(p).id,
            role="assistant",
            status="proposed",
            content="Review before applying.",
            changes_json=prepare_changes(context, [raw]),
        )
        db.session.add(message)
        db.session.commit()
        return message.public_id, scene.public_id


def test_preview_is_redacted_and_other_endpoints_cannot_bypass(app, client, production):
    app.config["CINEPLANNER_BILLING_ENABLED"] = True
    snapshot = request(client, production, "GET")
    assert snapshot["access"]["full_access"] is False
    assert len(snapshot["scenes"]) == 3
    assert len(snapshot["characters"]) <= 3
    assert snapshot["budget"] is None
    assert all(e["category"] in {"props", "wardrobe"} for e in snapshot["elements"])
    for path in [
        "/reports/scenes",
        "/schedule",
        "/assistant/messages",
        "/screenplay.pdf",
        "/audit-logs",
    ]:
        request(client, production, "GET", path, expected=402)
    request(
        client,
        production,
        "PATCH",
        "/scenes/" + snapshot["scenes"][0]["public_id"],
        {"summary": "bypass"},
        expected=402,
    )


def test_private_key_validates_server_hash_and_does_not_leak(app, client, production):
    app.config.update(
        CINEPLANNER_BILLING_ENABLED=True,
        CINEPLANNER_UNLOCK_HASH=hash_password("fixture-private-access"),
    )
    url = "/api/v1/cineplanner/membership/unlock"
    assert (
        client.post(url, headers=production["headers"], json={"key": "bad"}).status_code
        == 403
    )
    response = client.post(
        url, headers=production["headers"], json={"key": "fixture-private-access"}
    )
    assert response.status_code == 200
    assert response.json["data"]["access"]["unlimited_alterations"]
    assert (
        "fixture-private-access" not in response.text and "argon2" not in response.text
    )
    assert len(request(client, production, "GET")["scenes"]) > 3


def test_payment_review_activates_exact_plan_and_is_idempotent(app, client, production):
    app.config["CINEPLANNER_BILLING_ENABLED"] = True
    with app.test_request_context():
        _, owner = _owner()
        role = Role(code="finance_admin", name="Finance", portal_route="/finance")
        reviewer = User(
            email="reviewer@example.com",
            display_name="Finance Reviewer",
            password_hash="fixture",
            terms_version="2026",
        )
        reviewer.roles.append(UserRole(role=role, status="active", is_primary=True))
        file = FileAsset(
            owner_user_id=owner.id,
            storage_key="receipts/test.pdf",
            bucket=app.config["OBJECT_STORAGE_BUCKET_PRIVATE"],
            mime_type="application/pdf",
            size_bytes=10,
            checksum_sha256="a" * 64,
            visibility="private",
            scan_status="clean",
            processing_status="ready",
            original_name="receipt.pdf",
        )
        db.session.add_all([reviewer, file])
        db.session.flush()
        finance = {"Authorization": "Bearer " + issue_token_pair(reviewer).access_token}
        db.session.commit()
        file_id = file.public_id
    url = "/api/v1/cineplanner/membership"
    submitted = client.post(
        url + "/payments",
        headers=production["headers"],
        json={"file_id": file_id, "reference": "BANK-TEST-2026"},
    )
    assert submitted.status_code == 201, submitted.text
    pid = submitted.json["data"]["payment"]["public_id"]
    assert (
        client.post(
            url + "/payments",
            headers=production["headers"],
            json={"file_id": file_id, "reference": "duplicate"},
        ).status_code
        == 409
    )
    assert client.get(url + "/review", headers=production["headers"]).status_code == 403
    for _ in range(2):
        approved = client.post(
            url + "/review/" + pid, headers=finance, json={"decision": "approved"}
        )
        assert approved.status_code == 200, approved.text
    access = client.get(url, headers=production["headers"]).json["data"]["access"]
    assert access["full_access"] and access["alterations_remaining"] == 10
    assert (
        access["price_minor"] == 2000
        and access["currency"] == "USD"
        and not access["auto_renew"]
    )
    assert (
        client.post(
            url + "/review/" + pid, headers=finance, json={"decision": "rejected"}
        ).status_code
        == 409
    )
    assert (
        client.post(
            url + "/payments",
            headers=production["other"],
            json={"file_id": file_id, "reference": "stolen"},
        ).status_code
        == 422
    )


def test_reviewed_edit_preserves_other_fields_and_undo_does_not_charge(
    app, client, production
):
    _activate(app)
    message, scene_id = _proposal(app)
    before = request(client, production, "GET")["scenes"]
    endpoint = f"/assistant/messages/{message}"
    for _ in range(2):
        request(client, production, "POST", endpoint + "/apply")
    changed = request(client, production, "GET")
    scene = next(s for s in changed["scenes"] if s["public_id"] == scene_id)
    original = next(s for s in before if s["public_id"] == scene_id)
    assert scene["summary"] == "A carefully revised summary."
    for key in original:
        if key != "summary":
            assert scene[key] == original[key], key
    assert [s for s in changed["scenes"] if s["public_id"] != scene_id] == [
        s for s in before if s["public_id"] != scene_id
    ]
    assert changed["access"]["alterations_used"] == 1
    request(
        client,
        production,
        "PATCH",
        "/scenes/" + scene_id,
        {"production_notes": "Keep my later note."},
    )
    request(client, production, "POST", endpoint + "/undo")
    restored = request(client, production, "GET")
    scene = next(s for s in restored["scenes"] if s["public_id"] == scene_id)
    assert (
        scene["summary"] == original["summary"]
        and scene["production_notes"] == "Keep my later note."
    )
    assert restored["access"]["alterations_used"] == 1


def test_stale_proposal_rejected_without_charging(app, client, production):
    _activate(app)
    message, scene = _proposal(app)
    request(
        client,
        production,
        "PATCH",
        "/scenes/" + scene,
        {"summary": "Later manual edit."},
    )
    request(
        client, production, "POST", f"/assistant/messages/{message}/apply", expected=409
    )
    assert request(client, production, "GET")["access"]["alterations_used"] == 0


def test_last_credit_and_expiry_enforced(app, client, production):
    _activate(app, used=9)
    message, _ = _proposal(app)
    request(client, production, "POST", f"/assistant/messages/{message}/apply")
    message, _ = _proposal(app, add=True)
    request(
        client, production, "POST", f"/assistant/messages/{message}/apply", expected=402
    )
    with app.app_context():
        row = db.session.scalar(select(CineMembership))
        row.period_end = utc_now() - timedelta(seconds=1)
        db.session.commit()
    assert request(client, production, "GET")["access"]["full_access"] is False
    request(client, production, "GET", "/assistant/messages", expected=402)


def test_undo_added_scene_preserves_later_edits(app, client, production):
    _activate(app)
    message, _ = _proposal(app, add=True)
    applied = request(
        client, production, "POST", f"/assistant/messages/{message}/apply"
    )
    scene_id = applied["message"]["changes"][0]["target_id"]
    request(
        client,
        production,
        "PATCH",
        "/scenes/" + scene_id,
        {"production_notes": "Later information to preserve."},
    )
    request(
        client, production, "POST", f"/assistant/messages/{message}/undo", expected=409
    )


def test_source_parser_preserves_full_movie_and_long_scene():
    pages = [
        f"{i} INT. ROOM {i} - DAY\nHERO\nPage {i} unique dialogue END_{i}."
        for i in range(1, 241)
    ]
    source = source_scenes(pages)
    assert len(source) == 240 and source[-1].number == "240"
    chunks = sections(source)
    assert len(chunks) == 40
    for i in range(1, 241):
        assert any(f"END_{i}." in c.text for c in chunks)
    long = SourceScene("1", "X" * 52000 + "FINAL SENTENCE", 1, 20)
    split = sections([long])
    assert (
        len(split) == 3
        and "".join(s.text for c in split for s in c.scenes) == long.text
    )
    assert all(c.numbers == ["1"] for c in split)
    assert [s.number for s in source_scenes(["Unformatted prose", "Second page"])] == [
        "P1",
        "P2",
    ]


def test_merge_unions_late_scene_references_and_keeps_first_information():
    result = merge_results(
        [
            {
                "characters": {
                    "items": [
                        {
                            "name": "MARA",
                            "classification": "lead",
                            "scene_numbers": ["1"],
                            "description": "First detail",
                            "dialogue_count": 2,
                        }
                    ]
                }
            },
            {
                "characters": {
                    "items": [
                        {
                            "name": "Mara",
                            "classification": "minor",
                            "scene_numbers": ["240"],
                            "description": "Final detail",
                            "dialogue_count": 3,
                        }
                    ]
                }
            },
        ]
    )
    row = result["characters"]["items"][0]
    assert (
        row["scene_numbers"] == ["1", "240"]
        and row["dialogue_count"] == 5
        and row["classification"] == "lead"
    )
    assert "First detail" in row["description"] and "Final detail" in row["description"]


def test_incomplete_provider_response_is_not_silently_accepted():
    fake = SimpleNamespace(
        responses=SimpleNamespace(
            create=lambda **_: SimpleNamespace(status="incomplete", output_text="{}")
        )
    )
    with pytest.raises(ValueError, match="incomplete"):
        _request_stage(
            fake,
            stage="script_structure",
            prompt="fixture",
            schema={"properties": {}},
            source_text="test",
            model="fixture",
            safety_identifier="test",
        )


def test_failed_large_section_adapts_to_smaller_windows():
    calls = []

    def fake(_client, **kwargs):
        ids = kwargs["expected_scenes"]
        calls.append(ids)
        if len(ids) > 1:
            raise ValueError("Incomplete response")
        return {"scenes": {"items": [{"scene_number": ids[0], "summary": "Complete."}]}}

    with patch("app.services.cineplanner_ai._request_stage", side_effect=fake):
        result = _request_section_stage(
            None,
            chunk=SourceSection(
                [SourceScene("1", "First", 1, 1), SourceScene("2", "Last", 2, 2)]
            ),
            prompt="fixture",
        )
    assert calls == [["1", "2"], ["1"], ["2"]]
    assert len(result["scenes"]["items"]) == 2


def test_missing_original_text_and_cross_scope_targets_cannot_be_rewritten():
    context = {
        "editable_records": {
            "scenes": [{"public_id": "allowed", "summary": "Old", "source_text": ""}]
        }
    }
    raw = {
        "resource": "scenes",
        "action": "update",
        "target_id": "elsewhere",
        "fields_json": json.dumps({"summary": "Changed"}),
    }
    with pytest.raises(ValueError, match="outside"):
        prepare_changes(context, [raw])
    raw.update(
        target_id="allowed",
        fields_json=json.dumps({"source_text": "Invented original"}),
    )
    with pytest.raises(ValueError, match="Original scene text"):
        prepare_changes(context, [raw])
