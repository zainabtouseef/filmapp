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


def _register_role(
    client: FlaskClient, role: str, *, name: str
) -> tuple[dict[str, str], str]:
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": f"spec-{uuid.uuid4().hex[:12]}@example.com",
            "password": "StrongPass123!",
            "display_name": name,
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


def _file_for_user(client: FlaskClient, user_public_id: str) -> str:
    with client.application.app_context():
        user = db.session.execute(
            select(User).where(User.public_id == user_public_id)
        ).scalar_one()
        file = FileAsset(
            owner_user_id=user.id,
            storage_key=f"specialist/{uuid.uuid4().hex}.jpg",
            bucket="local-private",
            mime_type="image/jpeg",
            size_bytes=123456,
            checksum_sha256="1" * 64,
            visibility="private",
            scan_status="clean",
            processing_status="ready",
            original_name="asset.jpg",
        )
        db.session.add(file)
        db.session.commit()
        return file.public_id


def _lahore(client: FlaskClient) -> dict[str, str]:
    cities = client.get("/api/v1/cities")
    return next(
        city
        for city in cities.json["data"]["cities"]
        if city["public_id"] == "CITY-LHE"
    )


def test_agency_roster_audition_and_commission_flow(client: FlaskClient) -> None:
    producer_headers, _producer_id = _register_role(
        client, "director_producer", name="Agency Flow Producer"
    )
    agency_headers, _agency_user_id = _register_role(
        client, "casting_agency", name="Agency Flow Agency"
    )
    actor_headers, actor_user_id = _register_role(
        client, "actor_talent", name="Agency Flow Actor"
    )
    _approve_actor_kyc(client, actor_user_id)
    lahore = _lahore(client)

    agency_profile = client.patch(
        "/api/v1/agencies/profile",
        headers=agency_headers,
        json={
            "name": "FrameOne Casting Bureau",
            "city_id": lahore["public_id"],
            "commission_bps": 1500,
        },
    )
    assert agency_profile.status_code == 200, agency_profile.text
    agency_id = agency_profile.json["data"]["agency"]["public_id"]

    talent_profile = client.patch(
        "/api/v1/talent/profile",
        headers=actor_headers,
        json={
            "screen_name": "Agency Flow Actor",
            "day_rate_minor": 18000000,
            "currency": "PKR",
        },
    )
    assert talent_profile.status_code == 200, talent_profile.text
    talent_profile_id = talent_profile.json["data"]["talent_profile"]["public_id"]

    listing = client.post(
        "/api/v1/marketplace/listings",
        headers=actor_headers,
        json={
            "listing_type": "talent",
            "title": "Agency Flow Actor — Talent",
            "summary": "Talent available for agency flow tests.",
            "city_id": lahore["public_id"],
        },
    )
    assert listing.status_code == 201, listing.text
    listing_id = listing.json["data"]["listing"]["public_id"]

    invitation = client.post(
        "/api/v1/agency-invitations",
        headers=agency_headers,
        json={
            "talent_user_id": actor_user_id,
            "representation_type": "non_exclusive",
            "commission_bps": 1500,
        },
    )
    assert invitation.status_code == 201, invitation.text
    invitation_id = invitation.json["data"]["invitation"]["public_id"]

    accept = client.post(
        f"/api/v1/agency-invitations/{invitation_id}/accept",
        headers=actor_headers,
        json={},
    )
    assert accept.status_code == 200, accept.text
    assert accept.json["data"]["invitation"]["status"] == "accepted"

    roster = client.get(f"/api/v1/agencies/{agency_id}/talent", headers=agency_headers)
    assert roster.status_code == 200, roster.text
    assert len(roster.json["data"]["talent"]) == 1
    assert roster.json["data"]["talent"][0]["talent_profile_id"] == talent_profile_id

    project = client.post(
        "/api/v1/projects",
        headers=producer_headers,
        json={"title": "Agency Flow TVC", "project_type": "tvc"},
    )
    assert project.status_code == 201, project.text
    project_id = project.json["data"]["project"]["public_id"]
    requirement = client.post(
        f"/api/v1/projects/{project_id}/requirements",
        headers=producer_headers,
        json={"category": "talent", "title": "Lead father"},
    )
    assert requirement.status_code == 201, requirement.text
    requirement_id = requirement.json["data"]["requirement"]["public_id"]

    audition = client.post(
        "/api/v1/auditions",
        headers=producer_headers,
        json={
            "project_id": project_id,
            "requirement_id": requirement_id,
            "agency_id": agency_id,
            "role_title": "Lead father",
            "budget_minor": 18000000,
        },
    )
    assert audition.status_code == 201, audition.text
    audition_id = audition.json["data"]["audition"]["public_id"]

    accept_request = client.patch(
        f"/api/v1/auditions/{audition_id}",
        headers=agency_headers,
        json={"status": "accepted"},
    )
    assert accept_request.status_code == 200, accept_request.text

    candidate = client.post(
        f"/api/v1/auditions/{audition_id}/candidates",
        headers=agency_headers,
        json={"talent_profile_id": talent_profile_id, "agency_note": "Strong match"},
    )
    assert candidate.status_code == 201, candidate.text
    candidate_id = candidate.json["data"]["audition"]["candidates"][0]["public_id"]

    file_id = _file_for_user(client, actor_user_id)
    self_tape = client.post(
        "/api/v1/self-tapes",
        headers=actor_headers,
        json={
            "audition_candidate_id": candidate_id,
            "file_id": file_id,
            "duration_seconds": 74,
            "transcript": "My name is Ali...",
        },
    )
    assert self_tape.status_code == 201, self_tape.text

    agency_update = client.patch(
        f"/api/v1/audition-candidates/{candidate_id}",
        headers=agency_headers,
        json={"status": "shortlisted", "rank": 1},
    )
    assert agency_update.status_code == 200, agency_update.text
    assert agency_update.json["data"]["candidate"]["status"] == "shortlisted"

    director_update = client.patch(
        f"/api/v1/audition-candidates/{candidate_id}",
        headers=producer_headers,
        json={"director_note": "Warm read", "score": 92},
    )
    assert director_update.status_code == 200, director_update.text
    assert director_update.json["data"]["candidate"]["score"] == 92

    note = client.post(
        f"/api/v1/audition-candidates/{candidate_id}/notes",
        headers=agency_headers,
        json={"note": "Excellent timing", "score": 9},
    )
    assert note.status_code == 201, note.text
    assert len(note.json["data"]["candidate"]["selection_notes"]) == 1

    booking = client.post(
        "/api/v1/bookings",
        headers=producer_headers,
        json={
            "project_id": project_id,
            "requirement_id": requirement_id,
            "listing_id": listing_id,
            "category": "talent",
            "fee_minor": 18000000,
            "currency": "PKR",
            "start_at": "2026-08-01T02:30:00Z",
            "end_at": "2026-08-01T14:30:00Z",
        },
    )
    assert booking.status_code == 201, booking.text
    booking_id = booking.json["data"]["booking"]["public_id"]
    sent = client.post(
        f"/api/v1/bookings/{booking_id}/send",
        headers=producer_headers,
        json={"fee_minor": 18000000, "message": "Agency flow offer."},
    )
    assert sent.status_code == 200, sent.text
    offer_id = sent.json["data"]["booking"]["offers"][0]["public_id"]
    accepted = client.post(
        f"/api/v1/offers/{offer_id}/accept", headers=actor_headers, json={}
    )
    assert accepted.status_code == 200, accepted.text

    commission = client.post(
        "/api/v1/agency-commissions",
        headers=agency_headers,
        json={
            "booking_id": booking_id,
            "talent_profile_id": talent_profile_id,
            "gross_minor": 18000000,
            "currency": "PKR",
        },
    )
    assert commission.status_code == 201, commission.text
    assert commission.json["data"]["commission"]["commission_minor"] == 2700000

    commissions = client.get(
        f"/api/v1/agencies/{agency_id}/commissions", headers=agency_headers
    )
    assert commissions.status_code == 200, commissions.text
    assert len(commissions.json["data"]["commissions"]) == 1


def test_brand_opportunity_and_campaign_flow(client: FlaskClient) -> None:
    brand_headers, _brand_user_id = _register_role(
        client, "brand_sponsor", name="Brand Flow Sponsor"
    )
    applicant_headers, applicant_user_id = _register_role(
        client, "actor_talent", name="Brand Flow Applicant"
    )
    declined_headers, _declined_user_id = _register_role(
        client, "actor_talent", name="Brand Declined Applicant"
    )

    brand_profile = client.patch(
        "/api/v1/brands/profile",
        headers=brand_headers,
        json={
            "name": "Noor Couture",
            "category": "fashion",
            "representative": "Maham Noor",
            "description": "Pakistani luxury fashion.",
        },
    )
    assert brand_profile.status_code == 200, brand_profile.text

    opportunity = client.post(
        "/api/v1/brand-opportunities",
        headers=brand_headers,
        json={
            "title": "Eid Editorial Campaign",
            "category": "fashion",
            "budget_minor": 62000000,
            "usage_summary": "Digital and print 12 months",
            "eligibility": "Verified models",
            "deliverables": "6 stills and 2 reels",
            "status": "published",
        },
    )
    assert opportunity.status_code == 201, opportunity.text
    opportunity_id = opportunity.json["data"]["opportunity"]["public_id"]

    updated_opportunity = client.patch(
        f"/api/v1/brand-opportunities/{opportunity_id}",
        headers=brand_headers,
        json={
            "title": "Eid Editorial and Reels Campaign",
            "eligibility": "Verified creative applicants",
            "status": "published",
        },
    )
    assert updated_opportunity.status_code == 200, updated_opportunity.text
    assert (
        updated_opportunity.json["data"]["opportunity"]["title"]
        == "Eid Editorial and Reels Campaign"
    )

    public_list = client.get("/api/v1/brand-opportunities")
    assert public_list.status_code == 200, public_list.text
    assert any(
        row["public_id"] == opportunity_id
        for row in public_list.json["data"]["opportunities"]
    )

    application = client.post(
        f"/api/v1/brand-opportunities/{opportunity_id}/applications",
        headers=applicant_headers,
        json={
            "proposal": "Editorial concept proposal",
            "audience_metrics": {"instagram": 85000},
            "budget_ask_minor": 9500000,
        },
    )
    assert application.status_code == 201, application.text
    application_id = application.json["data"]["application"]["public_id"]

    declined_application = client.post(
        f"/api/v1/brand-opportunities/{opportunity_id}/applications",
        headers=declined_headers,
        json={
            "proposal": "A proposal outside the current campaign audience.",
            "audience_metrics": {"instagram": 1200},
        },
    )
    assert declined_application.status_code == 201, declined_application.text
    declined_application_id = declined_application.json["data"]["application"][
        "public_id"
    ]

    applications = client.get(
        f"/api/v1/brand-opportunities/{opportunity_id}/applications",
        headers=brand_headers,
    )
    assert applications.status_code == 200, applications.text
    assert len(applications.json["data"]["applications"]) == 2

    owner_applications = client.get(
        "/api/v1/brand-applications",
        headers=brand_headers,
    )
    assert owner_applications.status_code == 200, owner_applications.text
    assert len(owner_applications.json["data"]["applications"]) == 2

    rejected = client.patch(
        f"/api/v1/brand-applications/{declined_application_id}",
        headers=brand_headers,
        json={
            "status": "rejected",
            "rejection_reason": "Audience fit is below the current campaign brief.",
        },
    )
    assert rejected.status_code == 200, rejected.text
    assert (
        rejected.json["data"]["application"]["rejection_reason"]
        == "Audience fit is below the current campaign brief."
    )

    application_detail = client.get(
        f"/api/v1/brand-applications/{application_id}",
        headers=brand_headers,
    )
    assert application_detail.status_code == 200, application_detail.text
    assert (
        application_detail.json["data"]["application"]["opportunity"]["public_id"]
        == opportunity_id
    )

    conversation = client.post(
        f"/api/v1/brand-applications/{application_id}/conversation",
        headers=brand_headers,
    )
    assert conversation.status_code == 200, conversation.text
    conversation_id = conversation.json["data"]["conversation_id"]
    same_conversation = client.post(
        f"/api/v1/brand-applications/{application_id}/conversation",
        headers=applicant_headers,
    )
    assert same_conversation.status_code == 200, same_conversation.text
    assert same_conversation.json["data"]["conversation_id"] == conversation_id

    shortlisted = client.patch(
        f"/api/v1/brand-applications/{application_id}",
        headers=brand_headers,
        json={"status": "shortlisted"},
    )
    assert shortlisted.status_code == 200, shortlisted.text

    terms = client.post(
        f"/api/v1/brand-applications/{application_id}/terms",
        headers=brand_headers,
        json={
            "scope": "6 stills 2 reels",
            "exclusivity": "90-day fashion exclusivity",
            "approval_rights": "Brand pre-approval",
            "payment_schedule": [{"percent": 50}, {"percent": 50}],
            "status": "negotiating",
        },
    )
    assert terms.status_code == 201, terms.text
    assert terms.json["data"]["application"]["terms"][0]["version"] == 1

    accepted_terms = client.post(
        f"/api/v1/brand-applications/{application_id}/terms",
        headers=brand_headers,
        json={
            "scope": "6 stills 2 reels with approved usage rights",
            "exclusivity": "90-day fashion exclusivity",
            "approval_rights": "Brand pre-approval within two business days",
            "payment_schedule": [
                {"key": "advance", "percent": 50},
                {"key": "completion", "percent": 50},
            ],
            "status": "accepted",
        },
    )
    assert accepted_terms.status_code == 201, accepted_terms.text
    assert accepted_terms.json["data"]["application"]["status"] == "accepted"
    assert accepted_terms.json["data"]["application"]["terms"][1]["version"] == 2

    deliverable = client.post(
        "/api/v1/campaign-deliverables",
        headers=brand_headers,
        json={
            "opportunity_id": opportunity_id,
            "owner_user_id": applicant_user_id,
            "label": "First Instagram reel",
        },
    )
    assert deliverable.status_code == 201, deliverable.text
    deliverable_id = deliverable.json["data"]["deliverable"]["public_id"]

    deliverables = client.get(
        f"/api/v1/campaign-deliverables?opportunity_id={opportunity_id}",
        headers=brand_headers,
    )
    assert deliverables.status_code == 200, deliverables.text
    assert len(deliverables.json["data"]["deliverables"]) == 1

    unfiltered_deliverables = client.get(
        "/api/v1/campaign-deliverables",
        headers=brand_headers,
    )
    assert unfiltered_deliverables.status_code == 200, unfiltered_deliverables.text
    assert len(unfiltered_deliverables.json["data"]["deliverables"]) == 1

    premature_revision = client.patch(
        f"/api/v1/campaign-deliverables/{deliverable_id}",
        headers=brand_headers,
        json={
            "status": "revision_requested",
            "revision_note": "Use the approved product lockup.",
        },
    )
    assert premature_revision.status_code == 409, premature_revision.text

    file_id = _file_for_user(client, applicant_user_id)
    proof = client.post(
        f"/api/v1/campaign-deliverables/{deliverable_id}/proof",
        headers=applicant_headers,
        json={"file_id": file_id},
    )
    assert proof.status_code == 200, proof.text
    assert proof.json["data"]["deliverable"]["status"] == "submitted"

    revision = client.patch(
        f"/api/v1/campaign-deliverables/{deliverable_id}",
        headers=brand_headers,
        json={
            "status": "revision_requested",
            "revision_note": "Use the approved product lockup in the final frame.",
        },
    )
    assert revision.status_code == 200, revision.text
    assert (
        revision.json["data"]["deliverable"]["revision_note"]
        == "Use the approved product lockup in the final frame."
    )

    revised_proof = client.post(
        f"/api/v1/campaign-deliverables/{deliverable_id}/proof",
        headers=applicant_headers,
        json={"file_id": file_id},
    )
    assert revised_proof.status_code == 200, revised_proof.text
    assert revised_proof.json["data"]["deliverable"]["revision_note"] is None

    approved = client.post(
        f"/api/v1/campaign-deliverables/{deliverable_id}/approve",
        headers=brand_headers,
        json={},
    )
    assert approved.status_code == 200, approved.text
    assert approved.json["data"]["deliverable"]["status"] == "approved"

    metric = client.post(
        "/api/v1/campaign-metrics",
        headers=brand_headers,
        json={
            "deliverable_id": deliverable_id,
            "platform": "instagram",
            "impressions": 120000,
            "reach": 91000,
            "engagements": 8900,
            "clicks": 1400,
        },
    )
    assert metric.status_code == 201, metric.text
    assert len(metric.json["data"]["deliverable"]["metrics"]) == 1


def test_model_extension_profile_flow(client: FlaskClient) -> None:
    model_headers, model_user_id = _register_role(
        client, "model", name="Model Flow User"
    )

    profile = client.patch(
        "/api/v1/model/profile",
        headers=model_headers,
        json={"brand_safety_notes": "No tobacco campaigns.", "public_visibility": True},
    )
    assert profile.status_code == 200, profile.text
    assert profile.json["data"]["model_profile"]["brand_safety_notes"] == (
        "No tobacco campaigns."
    )

    categories = client.patch(
        "/api/v1/model/campaign-categories",
        headers=model_headers,
        json={
            "categories": [
                {"category": "fashion", "selected": True, "public_visible": True}
            ]
        },
    )
    assert categories.status_code == 200, categories.text
    assert len(categories.json["data"]["model_profile"]["campaign_categories"]) == 1

    usage_right = client.post(
        "/api/v1/model/usage-rights",
        headers=model_headers,
        json={
            "platform": "instagram",
            "territory": "Pakistan",
            "duration_months": 12,
            "exclusive": False,
        },
    )
    assert usage_right.status_code == 201, usage_right.text
    usage_right_id = usage_right.json["data"]["usage_right"]["public_id"]

    updated_right = client.patch(
        f"/api/v1/model/usage-rights/{usage_right_id}",
        headers=model_headers,
        json={"status": "expired"},
    )
    assert updated_right.status_code == 200, updated_right.text
    assert updated_right.json["data"]["usage_right"]["status"] == "expired"

    usage_rate = client.post(
        "/api/v1/model/usage-rates",
        headers=model_headers,
        json={
            "label": "Digital 12 months",
            "scope": "Pakistan social",
            "amount_minor": 9500000,
            "requires_review": False,
        },
    )
    assert usage_rate.status_code == 201, usage_rate.text
    usage_rate_id = usage_rate.json["data"]["usage_rate"]["public_id"]

    updated_rate = client.patch(
        f"/api/v1/model/usage-rates/{usage_rate_id}",
        headers=model_headers,
        json={"amount_minor": 10000000},
    )
    assert updated_rate.status_code == 200, updated_rate.text
    assert updated_rate.json["data"]["usage_rate"]["amount_minor"] == 10000000

    restricted = client.patch(
        "/api/v1/model/restricted-categories",
        headers=model_headers,
        json={"categories": [{"category": "tobacco", "blocked": True}]},
    )
    assert restricted.status_code == 200, restricted.text
    assert (
        restricted.json["data"]["model_profile"]["restricted_categories"][0]["category"]
        == "tobacco"
    )

    file_id = _file_for_user(client, model_user_id)
    portfolio_item = client.post(
        "/api/v1/portfolio",
        headers=model_headers,
        json={
            "profile_type": "model",
            "title": "Editorial reel",
            "category": "showreel",
            "file_id": file_id,
        },
    )
    assert portfolio_item.status_code == 201, portfolio_item.text

    portfolio_list = client.get(
        "/api/v1/portfolio?profile_type=model", headers=model_headers
    )
    assert portfolio_list.status_code == 200, portfolio_list.text
    assert len(portfolio_list.json["data"]["items"]) == 1


def test_distribution_release_flow(client: FlaskClient) -> None:
    producer_headers, _producer_id = _register_role(
        client, "director_producer", name="Distribution Flow Producer"
    )
    partner_headers, partner_user_id = _register_role(
        client, "distribution_partner", name="Distribution Flow Partner"
    )

    project = client.post(
        "/api/v1/projects",
        headers=producer_headers,
        json={"title": "Distribution Flow Feature", "project_type": "feature_film"},
    )
    assert project.status_code == 201, project.text
    project_id = project.json["data"]["project"]["public_id"]

    partner_profile = client.patch(
        "/api/v1/distribution/profile",
        headers=partner_headers,
        json={
            "name": "CineRelease Partner Desk",
            "channels": "Cinema OTT TV",
            "territories": "Pakistan GCC",
        },
    )
    assert partner_profile.status_code == 200, partner_profile.text

    distribution_project = client.post(
        "/api/v1/distribution-projects",
        headers=partner_headers,
        json={
            "project_id": project_id,
            "release_window_start": "2026-09-01",
            "release_window_end": "2026-09-30",
            "territories": "Pakistan GCC",
            "missing_items": "DCP subtitles",
            "status_note": "Awaiting masters",
        },
    )
    assert distribution_project.status_code == 201, distribution_project.text
    distribution_project_id = distribution_project.json["data"]["distribution_project"][
        "public_id"
    ]

    status_update = client.patch(
        f"/api/v1/distribution-projects/{distribution_project_id}",
        headers=partner_headers,
        json={"status": "in_progress"},
    )
    assert status_update.status_code == 200, status_update.text
    assert status_update.json["data"]["distribution_project"]["status"] == (
        "in_progress"
    )

    release_window = client.post(
        f"/api/v1/distribution-projects/{distribution_project_id}/release-windows",
        headers=partner_headers,
        json={
            "channel": "cinema",
            "territory": "Pakistan",
            "starts_on": "2026-09-01",
            "ends_on": "2026-09-21",
            "exclusivity": "exclusive",
        },
    )
    assert release_window.status_code == 201, release_window.text
    windows = release_window.json["data"]["distribution_project"]["release_windows"]
    assert len(windows) == 1

    handover = client.post(
        f"/api/v1/distribution-projects/{distribution_project_id}/handover-items",
        headers=partner_headers,
        json={"label": "DCP master", "detail": "4K encrypted DCP"},
    )
    assert handover.status_code == 201, handover.text
    handover_item_id = handover.json["data"]["distribution_project"]["handover_items"][
        0
    ]["id"]

    file_id = _file_for_user(client, partner_user_id)
    handover_update = client.patch(
        f"/api/v1/release-handover-items/{handover_item_id}",
        headers=partner_headers,
        json={"file_id": file_id, "status": "approved"},
    )
    assert handover_update.status_code == 200, handover_update.text
    updated_item = handover_update.json["data"]["distribution_project"][
        "handover_items"
    ][0]
    assert updated_item["status"] == "approved"
    assert updated_item["approved_at"] is not None

    contact = client.post(
        "/api/v1/distributor-contacts",
        headers=partner_headers,
        json={
            "name": "Aamir Shah",
            "channel": "cinema",
            "territory": "Pakistan",
            "contact_role": "Acquisition Manager",
            "email": "aamir@example.com",
            "prior_project": "Echo Street",
            "notes": "Prefers Thursday calls",
        },
    )
    assert contact.status_code == 201, contact.text
    contact_id = contact.json["data"]["contact"]["public_id"]

    contacts = client.get("/api/v1/distributor-contacts", headers=partner_headers)
    assert contacts.status_code == 200, contacts.text
    assert len(contacts.json["data"]["contacts"]) == 1

    contact_update = client.patch(
        f"/api/v1/distributor-contacts/{contact_id}",
        headers=partner_headers,
        json={"notes": "Prefers Friday calls"},
    )
    assert contact_update.status_code == 200, contact_update.text

    report = client.post(
        "/api/v1/distribution-reports",
        headers=partner_headers,
        json={
            "distribution_project_id": distribution_project_id,
            "territory": "Pakistan",
            "channel": "cinema",
            "period_start": "2026-09-01",
            "period_end": "2026-09-07",
            "audience_count": 84000,
            "revenue_minor": 125000000,
        },
    )
    assert report.status_code == 201, report.text

    reports = client.get(
        f"/api/v1/distribution-reports?distribution_project_id={distribution_project_id}",
        headers=partner_headers,
    )
    assert reports.status_code == 200, reports.text
    assert len(reports.json["data"]["reports"]) == 1
