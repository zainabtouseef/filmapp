from __future__ import annotations

import json
import uuid
from datetime import datetime
from typing import Any

from flask import Blueprint, Response, jsonify, request
from flask.typing import ResponseReturnValue
from sqlalchemy import or_, select

from app.api.auth import _current_user, _json_body
from app.api.bookings import _user_payload
from app.api.marketplace import (
    _city_by_public_id,
    _field_error,
    _file_payload,
    _model_profile_for_user,
    _owned_ready_file,
    _talent_profile_for_user,
)
from app.api.operations import _parse_datetime, _project_for_member
from app.api.projects import _optional_date
from app.errors import APIError
from app.extensions import db
from app.models.base import utc_now
from app.models.bookings import Booking, Conversation, ConversationMember
from app.models.identity import User
from app.models.marketplace import (
    ModelCampaignCategory,
    ModelProfile,
    ModelRestrictedCategory,
    ModelUsageRate,
    ModelUsageRight,
    TalentProfile,
)
from app.models.projects import Project, ProjectRequirement
from app.models.specialist import (
    AgencyCommission,
    AgencyInvitation,
    AgencyTalent,
    AuditionCandidate,
    AuditionRequest,
    BrandApplication,
    BrandOpportunity,
    BrandProfile,
    BrandTerm,
    CampaignDeliverable,
    CampaignMetric,
    CastingAgency,
    DistributionPartnerProfile,
    DistributionProject,
    DistributionReport,
    DistributorContact,
    ReleaseHandoverItem,
    ReleaseWindow,
    SelectionNote,
    SelfTape,
)
from app.responses import success

specialist_blueprint = Blueprint("specialist", __name__)

BRAND_OPPORTUNITY_STATUSES = {"draft", "published", "paused", "closed"}
BRAND_APPLICATION_STATUSES = {
    "submitted",
    "reviewing",
    "shortlisted",
    "negotiating",
    "accepted",
    "rejected",
    "withdrawn",
}
BRAND_TERM_STATUSES = {"draft", "negotiating", "accepted", "rejected", "superseded"}
CAMPAIGN_DELIVERABLE_STATUSES = {
    "pending",
    "submitted",
    "revision_requested",
    "approved",
    "cancelled",
}


# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------


def _agency_for_owner(user: User) -> CastingAgency:
    agency = db.session.execute(
        select(CastingAgency).where(CastingAgency.owner_user_id == user.id)
    ).scalar_one_or_none()
    if agency is None:
        raise APIError(
            "agency.profile_required", "Create an agency profile first.", status=409
        )
    return agency


def _agency_by_public_id_for_owner(public_id: str, user: User) -> CastingAgency:
    agency = db.session.execute(
        select(CastingAgency).where(
            CastingAgency.public_id == public_id,
            CastingAgency.owner_user_id == user.id,
        )
    ).scalar_one_or_none()
    if agency is None:
        raise APIError("agency.not_found", "Agency was not found.", status=404)
    return agency


def _talent_profile_by_public_id(public_id: str) -> TalentProfile:
    profile = db.session.execute(
        select(TalentProfile).where(TalentProfile.public_id == public_id)
    ).scalar_one_or_none()
    if profile is None:
        raise _field_error("talent_profile_id", "Talent profile was not found.")
    return profile


def _brand_for_owner(user: User) -> BrandProfile:
    _require_brand_role(user)
    brand = db.session.execute(
        select(BrandProfile).where(BrandProfile.owner_user_id == user.id)
    ).scalar_one_or_none()
    if brand is None:
        raise APIError(
            "brand.profile_required", "Create a brand profile first.", status=409
        )
    return brand


def _require_brand_role(user: User) -> None:
    if any(
        user_role.status == "active" and user_role.role.code == "brand_sponsor"
        for user_role in user.roles
    ):
        return
    raise APIError(
        "brand.role_required",
        "An active brand role is required.",
        status=403,
    )


def _distribution_partner_for_owner(user: User) -> DistributionPartnerProfile:
    partner = db.session.execute(
        select(DistributionPartnerProfile).where(
            DistributionPartnerProfile.user_id == user.id
        )
    ).scalar_one_or_none()
    if partner is None:
        raise APIError(
            "distribution.profile_required",
            "Create a distribution partner profile first.",
            status=409,
        )
    return partner


# ---------------------------------------------------------------------------
# Payload builders
# ---------------------------------------------------------------------------


def _agency_payload(item: CastingAgency) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "name": item.name,
        "city": {"public_id": item.city.public_id, "name": item.city.name}
        if item.city
        else None,
        "commission_bps": item.commission_bps,
        "verification_status": item.verification_status,
    }


def _invitation_payload(item: AgencyInvitation) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "agency_id": item.agency.public_id,
        "talent_user": _user_payload(item.talent_user) if item.talent_user else None,
        "representation_type": item.representation_type,
        "commission_bps": item.commission_bps,
        "status": item.status,
        "expires_at": item.expires_at.isoformat() if item.expires_at else None,
    }


def _agency_talent_payload(item: AgencyTalent) -> dict[str, Any]:
    return {
        "talent_profile_id": item.talent_profile.public_id,
        "screen_name": item.talent_profile.screen_name,
        "representation_type": item.representation_type,
        "start_date": item.start_date.isoformat() if item.start_date else None,
        "end_date": item.end_date.isoformat() if item.end_date else None,
        "commission_bps": item.commission_bps,
        "status": item.status,
    }


def _self_tape_payload(item: SelfTape) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "file": _file_payload(item.file),
        "thumbnail_file": _file_payload(item.thumbnail_file),
        "duration_seconds": item.duration_seconds,
        "transcript": item.transcript,
        "status": item.status,
        "submitted_at": item.submitted_at.isoformat(),
    }


def _selection_note_payload(item: SelectionNote) -> dict[str, Any]:
    return {
        "author": _user_payload(item.author),
        "note": item.note,
        "score": item.score,
        "visibility": item.visibility,
        "created_at": item.created_at.isoformat(),
    }


def _candidate_payload(item: AuditionCandidate) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "talent_profile": {
            "public_id": item.talent_profile.public_id,
            "screen_name": item.talent_profile.screen_name,
        },
        "status": item.status,
        "rank": item.rank,
        "agency_note": item.agency_note,
        "director_note": item.director_note,
        "score": item.score,
        "self_tapes": [_self_tape_payload(row) for row in item.self_tapes],
        "selection_notes": [
            _selection_note_payload(row) for row in item.selection_notes
        ],
    }


def _audition_payload(item: AuditionRequest) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "agency_id": item.agency.public_id,
        "project_id": item.project.public_id,
        "requirement_id": item.requirement.public_id if item.requirement else None,
        "requested_by": _user_payload(item.requester),
        "role_title": item.role_title,
        "due_at": item.due_at.isoformat() if item.due_at else None,
        "budget_minor": item.budget_minor,
        "currency": item.currency,
        "status": item.status,
        "candidates": [_candidate_payload(row) for row in item.candidates],
    }


def _commission_payload(item: AgencyCommission) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "booking_id": item.booking.public_id,
        "talent_profile_id": item.talent_profile.public_id,
        "gross_minor": item.gross_minor,
        "commission_bps": item.commission_bps,
        "commission_minor": item.commission_minor,
        "currency": item.currency,
        "due_at": item.due_at.isoformat() if item.due_at else None,
        "status": item.status,
    }


def _brand_profile_payload(item: BrandProfile) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "name": item.name,
        "category": item.category,
        "representative": item.representative,
        "trust_status": item.trust_status,
        "description": item.description,
        "logo_file": _file_payload(item.logo_file),
    }


def _brand_payment_schedule_payload(raw_value: str | None) -> list[dict[str, Any]]:
    if not raw_value:
        return []
    try:
        decoded = json.loads(raw_value)
    except (TypeError, json.JSONDecodeError):
        return []
    if isinstance(decoded, list):
        return [row for row in decoded if isinstance(row, dict)]
    if isinstance(decoded, dict):
        # Early demo/import rows stored `{ "advance": 50, ... }`; the public
        # API contract uses the newer list-of-milestones representation.
        return [
            {"key": str(key), "percent": value}
            for key, value in decoded.items()
            if isinstance(value, (int, float))
        ]
    return []


def _brand_term_payload(item: BrandTerm) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "scope": item.scope,
        "exclusivity": item.exclusivity,
        "approval_rights": item.approval_rights,
        "payment_schedule": _brand_payment_schedule_payload(item.payment_schedule_json),
        "status": item.status,
        "version": item.version,
    }


def _brand_application_payload(item: BrandApplication) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "opportunity": {
            "public_id": item.opportunity.public_id,
            "title": item.opportunity.title,
            "status": item.opportunity.status,
        },
        "applicant": _user_payload(item.applicant),
        "talent_profile_id": item.talent_profile.public_id
        if item.talent_profile
        else None,
        "conversation_id": item.conversation.public_id if item.conversation else None,
        "proposal": item.proposal,
        "audience_metrics": json.loads(item.audience_metrics_json)
        if item.audience_metrics_json
        else {},
        "budget_ask_minor": item.budget_ask_minor,
        "currency": item.currency,
        "status": item.status,
        "rejection_reason": item.rejection_reason,
        "terms": [_brand_term_payload(row) for row in item.terms],
        "created_at": item.created_at.isoformat(),
    }


def _brand_opportunity_payload(
    item: BrandOpportunity, *, include_applications: bool = False
) -> dict[str, Any]:
    payload: dict[str, Any] = {
        "public_id": item.public_id,
        "brand_profile_id": item.brand_profile.public_id,
        "project_id": item.project.public_id if item.project else None,
        "title": item.title,
        "category": item.category,
        "budget_minor": item.budget_minor,
        "currency": item.currency,
        "usage_summary": item.usage_summary,
        "eligibility": item.eligibility,
        "deliverables": item.deliverables,
        "application_due_at": item.application_due_at.isoformat()
        if item.application_due_at
        else None,
        "status": item.status,
        "cover_file": _file_payload(item.cover_file),
        "application_count": len(item.applications),
        "created_at": item.created_at.isoformat(),
    }
    if include_applications:
        payload["applications"] = [
            _brand_application_payload(row) for row in item.applications
        ]
    return payload


def _campaign_metric_payload(item: CampaignMetric) -> dict[str, Any]:
    return {
        "captured_at": item.captured_at.isoformat(),
        "platform": item.platform,
        "impressions": item.impressions,
        "reach": item.reach,
        "engagements": item.engagements,
        "clicks": item.clicks,
        "source": item.source,
    }


def _deliverable_payload(item: CampaignDeliverable) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "opportunity_id": item.opportunity.public_id,
        "booking_id": item.booking.public_id if item.booking else None,
        "owner": _user_payload(item.owner),
        "label": item.label,
        "due_at": item.due_at.isoformat() if item.due_at else None,
        "proof_file": _file_payload(item.proof_file),
        "status": item.status,
        "revision_note": item.revision_note,
        "approved_at": item.approved_at.isoformat() if item.approved_at else None,
        "metrics": [_campaign_metric_payload(row) for row in item.metrics],
    }


def _model_profile_payload(item: ModelProfile) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "talent_profile_id": item.talent_profile.public_id,
        "brand_safety_notes": item.brand_safety_notes,
        "public_visibility": item.public_visibility,
        "campaign_categories": [
            {
                "category": row.category,
                "selected": row.selected,
                "public_visible": row.public_visible,
            }
            for row in item.campaign_categories
        ],
        "restricted_categories": [
            {
                "category": row.category,
                "blocked": row.blocked,
                "reason": row.reason,
            }
            for row in item.restricted_categories
        ],
        "usage_rights": [_usage_right_payload(row) for row in item.usage_rights],
        "usage_rates": [_usage_rate_payload(row) for row in item.usage_rates],
    }


def _usage_right_payload(item: ModelUsageRight) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "platform": item.platform,
        "territory": item.territory,
        "duration_months": item.duration_months,
        "exclusive": item.exclusive,
        "status": item.status,
    }


def _usage_rate_payload(item: ModelUsageRate) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "label": item.label,
        "scope": item.scope,
        "amount_minor": item.amount_minor,
        "currency": item.currency,
        "requires_review": item.requires_review,
        "negotiable": item.negotiable,
    }


def _distribution_partner_payload(item: DistributionPartnerProfile) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "name": item.name,
        "channels": item.channels,
        "territories": item.territories,
        "status": item.status,
    }


def _handover_item_payload(item: ReleaseHandoverItem) -> dict[str, Any]:
    return {
        "id": str(item.id),
        "label": item.label,
        "detail": item.detail,
        "mandatory": item.mandatory,
        "file": _file_payload(item.file),
        "status": item.status,
        "approved_at": item.approved_at.isoformat() if item.approved_at else None,
    }


def _release_window_payload(item: ReleaseWindow) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "channel": item.channel,
        "territory": item.territory,
        "starts_on": item.starts_on.isoformat() if item.starts_on else None,
        "ends_on": item.ends_on.isoformat() if item.ends_on else None,
        "exclusivity": item.exclusivity,
        "status": item.status,
    }


def _distribution_project_payload(item: DistributionProject) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "project_id": item.project.public_id,
        "partner_profile_id": item.partner_profile.public_id,
        "release_window_start": item.release_window_start.isoformat()
        if item.release_window_start
        else None,
        "release_window_end": item.release_window_end.isoformat()
        if item.release_window_end
        else None,
        "territories": item.territories,
        "missing_items": item.missing_items,
        "status_note": item.status_note,
        "status": item.status,
        "handover_items": [_handover_item_payload(row) for row in item.handover_items],
        "release_windows": [
            _release_window_payload(row) for row in item.release_windows
        ],
    }


def _distributor_contact_payload(item: DistributorContact) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "name": item.name,
        "channel": item.channel,
        "territory": item.territory,
        "contact_role": item.contact_role,
        "prior_project": item.prior_project,
        "notes": item.notes,
        "status": item.status,
    }


def _distribution_report_payload(item: DistributionReport) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "distribution_project_id": item.distribution_project.public_id,
        "territory": item.territory,
        "channel": item.channel,
        "period_start": item.period_start.isoformat(),
        "period_end": item.period_end.isoformat(),
        "audience_count": item.audience_count,
        "revenue_minor": item.revenue_minor,
        "currency": item.currency,
        "source_file": _file_payload(item.source_file),
        "status": item.status,
    }


# ---------------------------------------------------------------------------
# Casting agency endpoints
# ---------------------------------------------------------------------------


@specialist_blueprint.get("/agencies/profile")
def agency_profile() -> Response:
    user = _current_user()
    agency = db.session.execute(
        select(CastingAgency).where(CastingAgency.owner_user_id == user.id)
    ).scalar_one_or_none()
    return jsonify(success({"agency": _agency_payload(agency) if agency else None}))


@specialist_blueprint.patch("/agencies/profile")
def upsert_agency_profile() -> Response:
    user = _current_user()
    payload = _json_body()
    agency = db.session.execute(
        select(CastingAgency).where(CastingAgency.owner_user_id == user.id)
    ).scalar_one_or_none()
    if agency is None:
        agency = CastingAgency(owner_user_id=user.id, name=user.display_name)
        db.session.add(agency)
    agency.name = str(payload.get("name", agency.name)).strip()[:180]
    if payload.get("city_id"):
        city = _city_by_public_id(str(payload.get("city_id")).strip())
        agency.city_id = city.id if city else None
    if payload.get("commission_bps") is not None:
        agency.commission_bps = int(payload.get("commission_bps") or 0)
    db.session.commit()
    return jsonify(success({"agency": _agency_payload(agency)}))


@specialist_blueprint.post("/agency-invitations")
def create_agency_invitation() -> ResponseReturnValue:
    user = _current_user()
    agency = _agency_for_owner(user)
    payload = _json_body()
    talent_user = None
    talent_user_public_id = str(payload.get("talent_user_id", "")).strip()
    if talent_user_public_id:
        talent_user = db.session.execute(
            select(User).where(User.public_id == talent_user_public_id)
        ).scalar_one_or_none()
        if talent_user is None:
            raise _field_error("talent_user_id", "User was not found.")
    invitation = AgencyInvitation(
        agency_id=agency.id,
        invited_by=user.id,
        talent_user_id=talent_user.id if talent_user else None,
        contact_token="encrypted:pending" if payload.get("contact") else None,
        representation_type=str(
            payload.get("representation_type", "non_exclusive")
        ).strip()[:32],
        commission_bps=int(payload.get("commission_bps") or agency.commission_bps),
        expires_at=_parse_datetime(payload["expires_at"], "expires_at")
        if payload.get("expires_at")
        else None,
    )
    db.session.add(invitation)
    db.session.commit()
    return jsonify(success({"invitation": _invitation_payload(invitation)})), 201


@specialist_blueprint.get("/agency-invitations")
def list_agency_invitations() -> Response:
    user = _current_user()
    agency = _agency_for_owner(user)
    rows = db.session.execute(
        select(AgencyInvitation)
        .where(AgencyInvitation.agency_id == agency.id)
        .order_by(AgencyInvitation.created_at.desc())
    ).scalars()
    return jsonify(success({"invitations": [_invitation_payload(row) for row in rows]}))


@specialist_blueprint.post("/agency-invitations/<public_id>/accept")
def accept_agency_invitation(public_id: str) -> Response:
    user = _current_user()
    invitation = db.session.execute(
        select(AgencyInvitation).where(AgencyInvitation.public_id == public_id)
    ).scalar_one_or_none()
    if invitation is None or invitation.talent_user_id != user.id:
        raise APIError("invitation.not_found", "Invitation was not found.", status=404)
    talent = _talent_profile_for_user(user.id)
    existing = db.session.execute(
        select(AgencyTalent).where(
            AgencyTalent.agency_id == invitation.agency_id,
            AgencyTalent.talent_profile_id == talent.id,
        )
    ).scalar_one_or_none()
    if existing is None:
        db.session.add(
            AgencyTalent(
                agency_id=invitation.agency_id,
                talent_profile_id=talent.id,
                representation_type=invitation.representation_type,
                commission_bps=invitation.commission_bps,
                start_date=utc_now().date(),
            )
        )
    invitation.status = "accepted"
    db.session.commit()
    return jsonify(success({"invitation": _invitation_payload(invitation)}))


@specialist_blueprint.get("/agencies/<public_id>/talent")
def agency_roster(public_id: str) -> Response:
    user = _current_user()
    agency = _agency_by_public_id_for_owner(public_id, user)
    rows = db.session.execute(
        select(AgencyTalent)
        .where(AgencyTalent.agency_id == agency.id)
        .order_by(AgencyTalent.created_at.desc())
    ).scalars()
    return jsonify(success({"talent": [_agency_talent_payload(row) for row in rows]}))


@specialist_blueprint.post("/auditions")
def create_audition_request() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    project = _project_for_member(str(payload.get("project_id", "")).strip(), user)
    agency = db.session.execute(
        select(CastingAgency).where(
            CastingAgency.public_id == str(payload.get("agency_id", "")).strip()
        )
    ).scalar_one_or_none()
    if agency is None:
        raise _field_error("agency_id", "Agency was not found.")
    requirement = None
    requirement_public_id = str(payload.get("requirement_id", "")).strip()
    if requirement_public_id:
        requirement = db.session.execute(
            select(ProjectRequirement).where(
                ProjectRequirement.public_id == requirement_public_id,
                ProjectRequirement.project_id == project.id,
            )
        ).scalar_one_or_none()
        if requirement is None:
            raise _field_error("requirement_id", "Requirement was not found.")
    item = AuditionRequest(
        agency_id=agency.id,
        project_id=project.id,
        requirement_id=requirement.id if requirement else None,
        requested_by=user.id,
        role_title=str(payload.get("role_title", "")).strip()[:180],
        due_at=_parse_datetime(payload["due_at"], "due_at")
        if payload.get("due_at")
        else None,
        budget_minor=int(payload.get("budget_minor") or 0) or None,
        currency=str(payload.get("currency", "PKR")).strip()[:3],
    )
    db.session.add(item)
    db.session.commit()
    return jsonify(success({"audition": _audition_payload(item)})), 201


@specialist_blueprint.get("/auditions")
def list_auditions() -> Response:
    user = _current_user()
    agency = db.session.execute(
        select(CastingAgency).where(CastingAgency.owner_user_id == user.id)
    ).scalar_one_or_none()
    query = select(AuditionRequest)
    if agency is not None:
        rows = db.session.execute(
            query.where(AuditionRequest.agency_id == agency.id).order_by(
                AuditionRequest.created_at.desc()
            )
        ).scalars()
    else:
        rows = db.session.execute(
            query.where(AuditionRequest.requested_by == user.id).order_by(
                AuditionRequest.created_at.desc()
            )
        ).scalars()
    return jsonify(success({"auditions": [_audition_payload(row) for row in rows]}))


def _audition_for_participant(public_id: str, user: User) -> AuditionRequest:
    audition = db.session.execute(
        select(AuditionRequest).where(AuditionRequest.public_id == public_id)
    ).scalar_one_or_none()
    if audition is None:
        raise APIError("audition.not_found", "Audition was not found.", status=404)
    if user.id not in {audition.agency.owner_user_id, audition.requested_by}:
        raise APIError(
            "audition.permission_denied", "Audition is not visible.", status=403
        )
    return audition


@specialist_blueprint.patch("/auditions/<public_id>")
def update_audition_request(public_id: str) -> Response:
    user = _current_user()
    audition = _audition_for_participant(public_id, user)
    payload = _json_body()
    if "status" in payload:
        audition.status = str(payload.get("status", "")).strip()[:32]
    db.session.commit()
    return jsonify(success({"audition": _audition_payload(audition)}))


@specialist_blueprint.post("/auditions/<public_id>/candidates")
def add_audition_candidate(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    audition = db.session.execute(
        select(AuditionRequest).where(AuditionRequest.public_id == public_id)
    ).scalar_one_or_none()
    if audition is None or audition.agency.owner_user_id != user.id:
        raise APIError("audition.not_found", "Audition was not found.", status=404)
    payload = _json_body()
    talent = _talent_profile_by_public_id(
        str(payload.get("talent_profile_id", "")).strip()
    )
    existing = db.session.execute(
        select(AuditionCandidate).where(
            AuditionCandidate.audition_request_id == audition.id,
            AuditionCandidate.talent_profile_id == talent.id,
        )
    ).scalar_one_or_none()
    if existing is not None:
        raise _field_error("talent_profile_id", "Candidate has already been added.")
    candidate = AuditionCandidate(
        audition_request_id=audition.id,
        talent_profile_id=talent.id,
        rank=int(payload.get("rank") or 100),
        agency_note=str(payload.get("agency_note", "")).strip()[:2000] or None,
    )
    db.session.add(candidate)
    db.session.commit()
    return jsonify(success({"audition": _audition_payload(audition)})), 201


def _candidate_for_user(public_id: str, user: User) -> AuditionCandidate:
    candidate = db.session.execute(
        select(AuditionCandidate).where(AuditionCandidate.public_id == public_id)
    ).scalar_one_or_none()
    if candidate is None:
        raise APIError(
            "audition_candidate.not_found", "Candidate was not found.", status=404
        )
    return candidate


@specialist_blueprint.patch("/audition-candidates/<public_id>")
def update_audition_candidate(public_id: str) -> Response:
    user = _current_user()
    candidate = _candidate_for_user(public_id, user)
    audition = candidate.audition_request
    is_agency = audition.agency.owner_user_id == user.id
    is_director = audition.requested_by == user.id
    if not is_agency and not is_director:
        raise APIError(
            "audition_candidate.permission_denied",
            "Candidate is not visible.",
            status=403,
        )
    payload = _json_body()
    if "status" in payload:
        candidate.status = str(payload.get("status", "")).strip()[:32]
    if is_agency:
        if "rank" in payload:
            candidate.rank = int(payload.get("rank") or candidate.rank)
        if "agency_note" in payload:
            candidate.agency_note = (
                str(payload.get("agency_note", "")).strip()[:2000] or None
            )
    if is_director:
        if "director_note" in payload:
            candidate.director_note = (
                str(payload.get("director_note", "")).strip()[:2000] or None
            )
        if "score" in payload:
            candidate.score = int(payload.get("score") or 0) or None
    db.session.commit()
    return jsonify(success({"candidate": _candidate_payload(candidate)}))


@specialist_blueprint.post("/self-tapes")
def create_self_tape() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    candidate = db.session.execute(
        select(AuditionCandidate).where(
            AuditionCandidate.public_id
            == str(payload.get("audition_candidate_id", "")).strip()
        )
    ).scalar_one_or_none()
    if candidate is None or candidate.talent_profile.user_id != user.id:
        raise APIError(
            "audition_candidate.not_found", "Candidate was not found.", status=404
        )
    file = _owned_ready_file(
        str(payload.get("file_id", "")).strip(), user.id, "file_id"
    )
    thumbnail_file = None
    if str(payload.get("thumbnail_file_id", "")).strip():
        thumbnail_file = _owned_ready_file(
            str(payload.get("thumbnail_file_id", "")).strip(),
            user.id,
            "thumbnail_file_id",
        )
    tape = SelfTape(
        audition_candidate_id=candidate.id,
        file_id=file.id,
        thumbnail_file_id=thumbnail_file.id if thumbnail_file else None,
        duration_seconds=int(payload.get("duration_seconds") or 0) or None,
        transcript=str(payload.get("transcript", "")).strip()[:8000] or None,
        submitted_at=utc_now(),
    )
    db.session.add(tape)
    db.session.commit()
    return jsonify(success({"self_tape": _self_tape_payload(tape)})), 201


@specialist_blueprint.post("/audition-candidates/<public_id>/notes")
def add_selection_note(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    candidate = _candidate_for_user(public_id, user)
    audition = candidate.audition_request
    if user.id not in {audition.agency.owner_user_id, audition.requested_by}:
        raise APIError(
            "audition_candidate.permission_denied",
            "Candidate is not visible.",
            status=403,
        )
    payload = _json_body()
    note = SelectionNote(
        audition_candidate_id=candidate.id,
        author_user_id=user.id,
        note=str(payload.get("note", "")).strip()[:2000],
        score=int(payload.get("score") or 0) or None,
        visibility=str(payload.get("visibility", "agency_and_director")).strip()[:32],
    )
    db.session.add(note)
    db.session.commit()
    return jsonify(success({"candidate": _candidate_payload(candidate)})), 201


@specialist_blueprint.post("/agency-commissions")
def create_agency_commission() -> ResponseReturnValue:
    user = _current_user()
    agency = _agency_for_owner(user)
    payload = _json_body()
    booking = db.session.execute(
        select(Booking).where(
            Booking.public_id == str(payload.get("booking_id", "")).strip()
        )
    ).scalar_one_or_none()
    if booking is None:
        raise _field_error("booking_id", "Booking was not found.")
    talent = _talent_profile_by_public_id(
        str(payload.get("talent_profile_id", "")).strip()
    )
    gross_minor = int(payload.get("gross_minor") or 0)
    commission_bps = int(payload.get("commission_bps") or agency.commission_bps)
    commission = AgencyCommission(
        agency_id=agency.id,
        booking_id=booking.id,
        talent_profile_id=talent.id,
        gross_minor=gross_minor,
        commission_bps=commission_bps,
        commission_minor=(gross_minor * commission_bps) // 10000,
        currency=str(payload.get("currency", "PKR")).strip()[:3],
        due_at=_parse_datetime(payload["due_at"], "due_at")
        if payload.get("due_at")
        else None,
    )
    db.session.add(commission)
    db.session.commit()
    return jsonify(success({"commission": _commission_payload(commission)})), 201


@specialist_blueprint.get("/agencies/<public_id>/commissions")
def agency_commissions(public_id: str) -> Response:
    user = _current_user()
    agency = _agency_by_public_id_for_owner(public_id, user)
    rows = db.session.execute(
        select(AgencyCommission)
        .where(AgencyCommission.agency_id == agency.id)
        .order_by(AgencyCommission.created_at.desc())
    ).scalars()
    return jsonify(success({"commissions": [_commission_payload(row) for row in rows]}))


# ---------------------------------------------------------------------------
# Brand / sponsor endpoints
# ---------------------------------------------------------------------------


@specialist_blueprint.get("/brands/profile")
def brand_profile() -> Response:
    user = _current_user()
    _require_brand_role(user)
    brand = db.session.execute(
        select(BrandProfile).where(BrandProfile.owner_user_id == user.id)
    ).scalar_one_or_none()
    return jsonify(success({"brand": _brand_profile_payload(brand) if brand else None}))


@specialist_blueprint.patch("/brands/profile")
def upsert_brand_profile() -> Response:
    user = _current_user()
    _require_brand_role(user)
    payload = _json_body()
    brand = db.session.execute(
        select(BrandProfile).where(BrandProfile.owner_user_id == user.id)
    ).scalar_one_or_none()
    if brand is None:
        brand = BrandProfile(owner_user_id=user.id, name=user.display_name)
        db.session.add(brand)
    brand.name = str(payload.get("name", brand.name)).strip()[:180]
    brand.category = (
        str(payload.get("category", brand.category or "")).strip()[:64] or None
    )
    brand.representative = (
        str(payload.get("representative", brand.representative or "")).strip()[:120]
        or None
    )
    brand.description = (
        str(payload.get("description", brand.description or "")).strip()[:4000] or None
    )
    if payload.get("billing_details"):
        brand.billing_token = "encrypted:pending"
    if str(payload.get("logo_file_id", "")).strip():
        brand.logo_file_id = _owned_ready_file(
            str(payload.get("logo_file_id")).strip(), user.id, "logo_file_id"
        ).id
    db.session.commit()
    return jsonify(success({"brand": _brand_profile_payload(brand)}))


@specialist_blueprint.post("/brand-opportunities")
def create_brand_opportunity() -> ResponseReturnValue:
    user = _current_user()
    brand = _brand_for_owner(user)
    payload = _json_body()
    title = str(payload.get("title", "")).strip()
    if len(title) < 2:
        raise _field_error("title", "Opportunity title is required.")
    project = None
    project_public_id = str(payload.get("project_id", "")).strip()
    if project_public_id:
        project = db.session.execute(
            select(Project).where(Project.public_id == project_public_id)
        ).scalar_one_or_none()
    status = str(payload.get("status", "draft")).strip()
    if status not in BRAND_OPPORTUNITY_STATUSES:
        raise _field_error("status", "Opportunity status is invalid.")
    cover_file = None
    if str(payload.get("cover_file_id", "")).strip():
        cover_file = _owned_ready_file(
            str(payload.get("cover_file_id")).strip(),
            user.id,
            "cover_file_id",
        )
    item = BrandOpportunity(
        brand_profile_id=brand.id,
        project_id=project.id if project else None,
        title=title[:180],
        category=str(payload.get("category", "fashion")).strip()[:64],
        budget_minor=int(payload.get("budget_minor") or 0) or None,
        currency=str(payload.get("currency", "PKR")).strip()[:3],
        usage_summary=str(payload.get("usage_summary", "")).strip()[:2000] or None,
        eligibility=str(payload.get("eligibility", "")).strip()[:2000] or None,
        deliverables=str(payload.get("deliverables", "")).strip()[:2000] or None,
        application_due_at=_parse_datetime(
            payload["application_due_at"], "application_due_at"
        )
        if payload.get("application_due_at")
        else None,
        status=status,
        cover_file_id=cover_file.id if cover_file else None,
    )
    db.session.add(item)
    db.session.commit()
    return jsonify(success({"opportunity": _brand_opportunity_payload(item)})), 201


@specialist_blueprint.get("/brand-opportunities")
def list_brand_opportunities() -> Response:
    query = select(BrandOpportunity)
    brand = None
    try:
        user = _current_user()
    except APIError:
        user = None
    if user is not None:
        brand = db.session.execute(
            select(BrandProfile).where(BrandProfile.owner_user_id == user.id)
        ).scalar_one_or_none()
    if brand is not None:
        rows = db.session.execute(
            query.where(BrandOpportunity.brand_profile_id == brand.id).order_by(
                BrandOpportunity.created_at.desc()
            )
        ).scalars()
    else:
        rows = db.session.execute(
            query.where(BrandOpportunity.status == "published").order_by(
                BrandOpportunity.created_at.desc()
            )
        ).scalars()
    return jsonify(
        success({"opportunities": [_brand_opportunity_payload(row) for row in rows]})
    )


def _opportunity_or_404(public_id: str) -> BrandOpportunity:
    opportunity = db.session.execute(
        select(BrandOpportunity).where(BrandOpportunity.public_id == public_id)
    ).scalar_one_or_none()
    if opportunity is None:
        raise APIError(
            "brand_opportunity.not_found", "Opportunity was not found.", status=404
        )
    return opportunity


@specialist_blueprint.get("/brand-opportunities/<public_id>")
def get_brand_opportunity(public_id: str) -> Response:
    opportunity = _opportunity_or_404(public_id)
    return jsonify(success({"opportunity": _brand_opportunity_payload(opportunity)}))


@specialist_blueprint.patch("/brand-opportunities/<public_id>")
def update_brand_opportunity(public_id: str) -> Response:
    user = _current_user()
    item = _opportunity_or_404(public_id)
    if item.brand_profile.owner_user_id != user.id:
        raise APIError(
            "brand_opportunity.permission_denied",
            "Only the brand can update this opportunity.",
            status=403,
        )
    payload = _json_body()
    if "title" in payload:
        title = str(payload.get("title", "")).strip()
        if len(title) < 2:
            raise _field_error("title", "Opportunity title is required.")
        item.title = title[:180]
    if "category" in payload:
        item.category = str(payload.get("category", "")).strip()[:64]
    if "budget_minor" in payload:
        item.budget_minor = int(payload.get("budget_minor") or 0) or None
    if "currency" in payload:
        item.currency = str(payload.get("currency", "PKR")).strip()[:3]
    if "usage_summary" in payload:
        item.usage_summary = (
            str(payload.get("usage_summary", "")).strip()[:2000] or None
        )
    if "eligibility" in payload:
        item.eligibility = str(payload.get("eligibility", "")).strip()[:2000] or None
    if "deliverables" in payload:
        item.deliverables = str(payload.get("deliverables", "")).strip()[:2000] or None
    if "application_due_at" in payload:
        item.application_due_at = (
            _parse_datetime(payload["application_due_at"], "application_due_at")
            if payload.get("application_due_at")
            else None
        )
    if "status" in payload:
        status = str(payload.get("status", "")).strip()
        if status not in BRAND_OPPORTUNITY_STATUSES:
            raise _field_error("status", "Opportunity status is invalid.")
        item.status = status
    if str(payload.get("cover_file_id", "")).strip():
        item.cover_file_id = _owned_ready_file(
            str(payload.get("cover_file_id")).strip(),
            user.id,
            "cover_file_id",
        ).id
    db.session.commit()
    return jsonify(success({"opportunity": _brand_opportunity_payload(item)}))


@specialist_blueprint.post("/brand-opportunities/<public_id>/applications")
def create_brand_application(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    opportunity = _opportunity_or_404(public_id)
    payload = _json_body()
    talent = db.session.execute(
        select(TalentProfile).where(TalentProfile.user_id == user.id)
    ).scalar_one_or_none()
    application = BrandApplication(
        opportunity_id=opportunity.id,
        applicant_user_id=user.id,
        talent_profile_id=talent.id if talent else None,
        proposal=str(payload.get("proposal", "")).strip()[:4000] or None,
        audience_metrics_json=json.dumps(payload.get("audience_metrics", {})),
        budget_ask_minor=int(payload.get("budget_ask_minor") or 0) or None,
        currency=str(payload.get("currency", "PKR")).strip()[:3],
    )
    db.session.add(application)
    db.session.commit()
    return jsonify(
        success({"application": _brand_application_payload(application)})
    ), 201


@specialist_blueprint.get("/brand-opportunities/<public_id>/applications")
def list_brand_applications(public_id: str) -> Response:
    user = _current_user()
    opportunity = _opportunity_or_404(public_id)
    if opportunity.brand_profile.owner_user_id != user.id:
        raise APIError(
            "brand_opportunity.permission_denied",
            "Applications are not visible.",
            status=403,
        )
    return jsonify(
        success(
            {
                "applications": [
                    _brand_application_payload(row) for row in opportunity.applications
                ]
            }
        )
    )


@specialist_blueprint.get("/brand-applications")
def list_owner_brand_applications() -> Response:
    user = _current_user()
    brand = _brand_for_owner(user)
    opportunity_id = request.args.get("opportunity_id")
    query = (
        select(BrandApplication)
        .join(BrandOpportunity)
        .where(BrandOpportunity.brand_profile_id == brand.id)
    )
    if opportunity_id:
        opportunity = _opportunity_or_404(opportunity_id)
        if opportunity.brand_profile_id != brand.id:
            raise APIError(
                "brand_opportunity.permission_denied",
                "Applications are not visible.",
                status=403,
            )
        query = query.where(BrandApplication.opportunity_id == opportunity.id)
    rows = db.session.execute(
        query.order_by(BrandApplication.created_at.desc())
    ).scalars()
    return jsonify(
        success({"applications": [_brand_application_payload(row) for row in rows]})
    )


def _application_for_participant(public_id: str, user: User) -> BrandApplication:
    application = db.session.execute(
        select(BrandApplication).where(BrandApplication.public_id == public_id)
    ).scalar_one_or_none()
    if application is None:
        raise APIError(
            "brand_application.not_found", "Application was not found.", status=404
        )
    if user.id not in {
        application.applicant_user_id,
        application.opportunity.brand_profile.owner_user_id,
    }:
        raise APIError(
            "brand_application.permission_denied",
            "Application is not visible.",
            status=403,
        )
    return application


@specialist_blueprint.get("/brand-applications/<public_id>")
def get_brand_application(public_id: str) -> Response:
    user = _current_user()
    application = _application_for_participant(public_id, user)
    return jsonify(success({"application": _brand_application_payload(application)}))


@specialist_blueprint.patch("/brand-applications/<public_id>")
def update_brand_application(public_id: str) -> Response:
    user = _current_user()
    application = _application_for_participant(public_id, user)
    if application.opportunity.brand_profile.owner_user_id != user.id:
        raise APIError(
            "brand_application.permission_denied",
            "Only the brand can update application status.",
            status=403,
        )
    payload = _json_body()
    if "status" in payload:
        status = str(payload.get("status", "")).strip()
        if status not in BRAND_APPLICATION_STATUSES:
            raise _field_error("status", "Application status is invalid.")
        application.status = status
        if status != "rejected":
            application.rejection_reason = None
    if "rejection_reason" in payload:
        if application.status != "rejected":
            raise _field_error(
                "rejection_reason",
                "A rejection reason can only be saved for a rejected application.",
            )
        application.rejection_reason = (
            str(payload.get("rejection_reason", "")).strip()[:2000] or None
        )
    db.session.commit()
    return jsonify(success({"application": _brand_application_payload(application)}))


@specialist_blueprint.post("/brand-applications/<public_id>/conversation")
def ensure_brand_application_conversation(public_id: str) -> Response:
    user = _current_user()
    application = _application_for_participant(public_id, user)
    if application.conversation is None:
        conversation = Conversation(
            project_id=application.opportunity.project_id,
            type="brand_application",
            title=(
                f"{application.opportunity.title} - "
                f"{application.applicant.display_name}"
            )[:180],
        )
        db.session.add(conversation)
        db.session.flush()
        db.session.add_all(
            [
                ConversationMember(
                    conversation_id=conversation.id,
                    user_id=application.opportunity.brand_profile.owner_user_id,
                ),
                ConversationMember(
                    conversation_id=conversation.id,
                    user_id=application.applicant_user_id,
                ),
            ]
        )
        application.conversation = conversation
        db.session.commit()
    return jsonify(
        success(
            {
                "conversation_id": application.conversation.public_id,
                "application": _brand_application_payload(application),
            }
        )
    )


@specialist_blueprint.post("/brand-applications/<public_id>/terms")
def create_brand_term(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    application = _application_for_participant(public_id, user)
    payload = _json_body()
    next_version = max((row.version for row in application.terms), default=0) + 1
    status = str(payload.get("status", "negotiating")).strip()
    if status not in BRAND_TERM_STATUSES:
        raise _field_error("status", "Term status is invalid.")
    term = BrandTerm(
        application_id=application.id,
        scope=str(payload.get("scope", "")).strip()[:2000] or None,
        exclusivity=str(payload.get("exclusivity", "")).strip()[:255] or None,
        approval_rights=str(payload.get("approval_rights", "")).strip()[:255] or None,
        payment_schedule_json=json.dumps(payload.get("payment_schedule", [])),
        status=status,
        version=next_version,
    )
    db.session.add(term)
    if status == "accepted":
        application.status = "accepted"
    elif application.status in {"submitted", "reviewing", "shortlisted"}:
        application.status = "negotiating"
    db.session.commit()
    return jsonify(
        success({"application": _brand_application_payload(application)})
    ), 201


@specialist_blueprint.post("/campaign-deliverables")
def create_campaign_deliverable() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    opportunity = _opportunity_or_404(str(payload.get("opportunity_id", "")).strip())
    if opportunity.brand_profile.owner_user_id != user.id:
        raise APIError(
            "brand_opportunity.permission_denied",
            "Only the brand can create deliverables.",
            status=403,
        )
    owner_user = None
    owner_public_id = str(payload.get("owner_user_id", "")).strip()
    if owner_public_id:
        owner_user = db.session.execute(
            select(User).where(User.public_id == owner_public_id)
        ).scalar_one_or_none()
    if owner_user is None:
        raise _field_error("owner_user_id", "Deliverable owner was not found.")
    accepted_application = db.session.execute(
        select(BrandApplication).where(
            BrandApplication.opportunity_id == opportunity.id,
            BrandApplication.applicant_user_id == owner_user.id,
            BrandApplication.status == "accepted",
        )
    ).scalar_one_or_none()
    if accepted_application is None:
        raise _field_error(
            "owner_user_id",
            "Deliverables can only be assigned to an accepted applicant.",
        )
    booking = None
    booking_public_id = str(payload.get("booking_id", "")).strip()
    if booking_public_id:
        booking = db.session.execute(
            select(Booking).where(Booking.public_id == booking_public_id)
        ).scalar_one_or_none()
    label = str(payload.get("label", "")).strip()
    if len(label) < 2:
        raise _field_error("label", "Deliverable label is required.")
    item = CampaignDeliverable(
        opportunity_id=opportunity.id,
        booking_id=booking.id if booking else None,
        owner_user_id=owner_user.id,
        label=label[:180],
        due_at=_parse_datetime(payload["due_at"], "due_at")
        if payload.get("due_at")
        else None,
    )
    db.session.add(item)
    db.session.commit()
    return jsonify(success({"deliverable": _deliverable_payload(item)})), 201


@specialist_blueprint.get("/campaign-deliverables")
def list_campaign_deliverables() -> Response:
    user = _current_user()
    opportunity_id = request.args.get("opportunity_id")
    query = select(CampaignDeliverable)
    if opportunity_id:
        opportunity = _opportunity_or_404(opportunity_id)
        if opportunity.brand_profile.owner_user_id != user.id:
            raise APIError(
                "brand_opportunity.permission_denied",
                "Deliverables are not visible.",
                status=403,
            )
        query = query.where(CampaignDeliverable.opportunity_id == opportunity.id)
    else:
        query = (
            query.join(
                BrandOpportunity,
                CampaignDeliverable.opportunity_id == BrandOpportunity.id,
            )
            .join(
                BrandProfile,
                BrandOpportunity.brand_profile_id == BrandProfile.id,
            )
            .where(
                or_(
                    CampaignDeliverable.owner_user_id == user.id,
                    BrandProfile.owner_user_id == user.id,
                )
            )
        )
    rows = db.session.execute(
        query.order_by(CampaignDeliverable.created_at.desc())
    ).scalars()
    return jsonify(
        success({"deliverables": [_deliverable_payload(row) for row in rows]})
    )


def _deliverable_or_404(public_id: str) -> CampaignDeliverable:
    item = db.session.execute(
        select(CampaignDeliverable).where(CampaignDeliverable.public_id == public_id)
    ).scalar_one_or_none()
    if item is None:
        raise APIError(
            "campaign_deliverable.not_found", "Deliverable was not found.", status=404
        )
    return item


@specialist_blueprint.patch("/campaign-deliverables/<public_id>")
def update_campaign_deliverable(public_id: str) -> Response:
    user = _current_user()
    item = _deliverable_or_404(public_id)
    is_brand = item.opportunity.brand_profile.owner_user_id == user.id
    if not is_brand:
        raise APIError(
            "campaign_deliverable.permission_denied",
            "Only the brand can update this deliverable.",
            status=403,
        )
    payload = _json_body()
    if "label" in payload:
        label = str(payload.get("label", "")).strip()
        if len(label) < 2:
            raise _field_error("label", "Deliverable label is required.")
        item.label = label[:180]
    if "due_at" in payload:
        item.due_at = (
            _parse_datetime(payload["due_at"], "due_at")
            if payload.get("due_at")
            else None
        )
    if "status" in payload:
        status = str(payload.get("status", "")).strip()
        if status not in CAMPAIGN_DELIVERABLE_STATUSES:
            raise _field_error("status", "Deliverable status is invalid.")
        if status == "submitted":
            raise _field_error(
                "status",
                "Only the deliverable owner can submit proof.",
            )
        if status == "revision_requested":
            if item.status != "submitted" or item.proof_file_id is None:
                raise APIError(
                    "campaign_deliverable.not_submitted",
                    "A submitted proof is required before requesting revision.",
                    status=409,
                )
            revision_note = str(payload.get("revision_note", "")).strip()
            if len(revision_note) < 4:
                raise _field_error(
                    "revision_note",
                    "Add a clear revision request for the deliverable owner.",
                )
            item.revision_note = revision_note[:2000]
        elif "revision_note" in payload:
            item.revision_note = (
                str(payload.get("revision_note", "")).strip()[:2000] or None
            )
        item.status = status
        if status != "approved":
            item.approved_at = None
    db.session.commit()
    return jsonify(success({"deliverable": _deliverable_payload(item)}))


@specialist_blueprint.post("/campaign-deliverables/<public_id>/proof")
def submit_campaign_deliverable_proof(public_id: str) -> Response:
    user = _current_user()
    item = _deliverable_or_404(public_id)
    if item.owner_user_id != user.id:
        raise APIError(
            "campaign_deliverable.permission_denied",
            "Only the deliverable owner can submit proof.",
            status=403,
        )
    payload = _json_body()
    file = _owned_ready_file(
        str(payload.get("file_id", "")).strip(), user.id, "file_id"
    )
    item.proof_file_id = file.id
    item.status = "submitted"
    item.revision_note = None
    db.session.commit()
    return jsonify(success({"deliverable": _deliverable_payload(item)}))


@specialist_blueprint.post("/campaign-deliverables/<public_id>/approve")
def approve_campaign_deliverable(public_id: str) -> Response:
    user = _current_user()
    item = _deliverable_or_404(public_id)
    if item.opportunity.brand_profile.owner_user_id != user.id:
        raise APIError(
            "campaign_deliverable.permission_denied",
            "Only the brand can approve deliverables.",
            status=403,
        )
    if item.status != "submitted":
        raise APIError(
            "campaign_deliverable.not_submitted",
            "Proof must be submitted before approval.",
            status=409,
        )
    item.status = "approved"
    item.revision_note = None
    item.approved_at = utc_now()
    db.session.commit()
    return jsonify(success({"deliverable": _deliverable_payload(item)}))


@specialist_blueprint.post("/campaign-metrics")
def create_campaign_metric() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    deliverable = _deliverable_or_404(str(payload.get("deliverable_id", "")).strip())
    if user.id not in {
        deliverable.owner_user_id,
        deliverable.opportunity.brand_profile.owner_user_id,
    }:
        raise APIError(
            "campaign_deliverable.permission_denied",
            "Deliverable is not visible.",
            status=403,
        )
    captured_at: datetime = (
        _parse_datetime(payload["captured_at"], "captured_at")
        if payload.get("captured_at")
        else utc_now()
    )
    metric = CampaignMetric(
        deliverable_id=deliverable.id,
        captured_at=captured_at,
        platform=str(payload.get("platform", "instagram")).strip()[:64],
        impressions=int(payload.get("impressions") or 0),
        reach=int(payload.get("reach") or 0),
        engagements=int(payload.get("engagements") or 0),
        clicks=int(payload.get("clicks") or 0),
        source=str(payload.get("source", "manual_verified")).strip()[:32],
        raw_json=json.dumps(payload.get("raw")) if payload.get("raw") else None,
    )
    db.session.add(metric)
    db.session.commit()
    return jsonify(success({"deliverable": _deliverable_payload(deliverable)})), 201


# ---------------------------------------------------------------------------
# Model extension endpoints
# ---------------------------------------------------------------------------


def _model_profile_or_create(user: User) -> ModelProfile:
    profile = db.session.execute(
        select(ModelProfile).where(ModelProfile.user_id == user.id)
    ).scalar_one_or_none()
    if profile is not None:
        return profile
    talent = db.session.execute(
        select(TalentProfile).where(TalentProfile.user_id == user.id)
    ).scalar_one_or_none()
    if talent is None:
        talent = TalentProfile(user_id=user.id, screen_name=user.display_name)
        db.session.add(talent)
        db.session.flush()
    profile = ModelProfile(user_id=user.id, talent_profile_id=talent.id)
    db.session.add(profile)
    db.session.flush()
    return profile


@specialist_blueprint.get("/model/profile")
def model_profile() -> Response:
    user = _current_user()
    profile = db.session.execute(
        select(ModelProfile).where(ModelProfile.user_id == user.id)
    ).scalar_one_or_none()
    return jsonify(
        success({"model_profile": _model_profile_payload(profile) if profile else None})
    )


@specialist_blueprint.patch("/model/profile")
def update_model_profile() -> Response:
    user = _current_user()
    payload = _json_body()
    profile = _model_profile_or_create(user)
    if "brand_safety_notes" in payload:
        profile.brand_safety_notes = (
            str(payload.get("brand_safety_notes", "")).strip()[:2000] or None
        )
    if "public_visibility" in payload:
        profile.public_visibility = bool(payload.get("public_visibility"))
    db.session.commit()
    return jsonify(success({"model_profile": _model_profile_payload(profile)}))


@specialist_blueprint.get("/model/campaign-categories")
def model_campaign_categories() -> Response:
    profile = _model_profile_for_user(_current_user().id)
    return jsonify(success(_model_profile_payload(profile)))


@specialist_blueprint.patch("/model/campaign-categories")
def update_model_campaign_categories() -> Response:
    user = _current_user()
    profile = _model_profile_or_create(user)
    payload = _json_body()
    categories = payload.get("categories")
    if not isinstance(categories, list):
        raise _field_error("categories", "Categories must be a list.")
    profile.campaign_categories.clear()
    db.session.flush()
    for entry in categories:
        if not isinstance(entry, dict):
            continue
        category = str(entry.get("category", "")).strip()[:64]
        if not category:
            continue
        db.session.add(
            ModelCampaignCategory(
                model_profile_id=profile.id,
                category=category,
                selected=bool(entry.get("selected", True)),
                public_visible=bool(entry.get("public_visible", True)),
            )
        )
    db.session.commit()
    return jsonify(success({"model_profile": _model_profile_payload(profile)}))


@specialist_blueprint.get("/model/usage-rights")
def list_model_usage_rights() -> Response:
    profile = _model_profile_for_user(_current_user().id)
    rights = [_usage_right_payload(row) for row in profile.usage_rights]
    return jsonify(success({"usage_rights": rights}))


@specialist_blueprint.post("/model/usage-rights")
def create_model_usage_right() -> ResponseReturnValue:
    user = _current_user()
    profile = _model_profile_or_create(user)
    payload = _json_body()
    item = ModelUsageRight(
        model_profile_id=profile.id,
        platform=str(payload.get("platform", "")).strip()[:64],
        territory=str(payload.get("territory", "Pakistan")).strip()[:120],
        duration_months=int(payload.get("duration_months") or 0) or None,
        exclusive=bool(payload.get("exclusive", False)),
        status=str(payload.get("status", "active")).strip()[:32],
    )
    db.session.add(item)
    db.session.commit()
    return jsonify(success({"usage_right": _usage_right_payload(item)})), 201


@specialist_blueprint.patch("/model/usage-rights/<public_id>")
def update_model_usage_right(public_id: str) -> Response:
    user = _current_user()
    profile = _model_profile_for_user(user.id)
    item = db.session.execute(
        select(ModelUsageRight).where(
            ModelUsageRight.public_id == public_id,
            ModelUsageRight.model_profile_id == profile.id,
        )
    ).scalar_one_or_none()
    if item is None:
        raise APIError(
            "model_usage_right.not_found", "Usage right was not found.", status=404
        )
    payload = _json_body()
    if "status" in payload:
        item.status = str(payload.get("status", "")).strip()[:32]
    if "exclusive" in payload:
        item.exclusive = bool(payload.get("exclusive"))
    if "duration_months" in payload:
        item.duration_months = int(payload.get("duration_months") or 0) or None
    db.session.commit()
    return jsonify(success({"usage_right": _usage_right_payload(item)}))


@specialist_blueprint.get("/model/usage-rates")
def list_model_usage_rates() -> Response:
    profile = _model_profile_for_user(_current_user().id)
    return jsonify(
        success({"usage_rates": [_usage_rate_payload(r) for r in profile.usage_rates]})
    )


@specialist_blueprint.post("/model/usage-rates")
def create_model_usage_rate() -> ResponseReturnValue:
    user = _current_user()
    profile = _model_profile_or_create(user)
    payload = _json_body()
    item = ModelUsageRate(
        model_profile_id=profile.id,
        label=str(payload.get("label", "")).strip()[:120],
        scope=str(payload.get("scope", "")).strip()[:180] or None,
        amount_minor=int(payload.get("amount_minor") or 0),
        currency=str(payload.get("currency", "PKR")).strip()[:3],
        requires_review=bool(payload.get("requires_review", False)),
        negotiable=bool(payload.get("negotiable", True)),
    )
    db.session.add(item)
    db.session.commit()
    return jsonify(success({"usage_rate": _usage_rate_payload(item)})), 201


@specialist_blueprint.patch("/model/usage-rates/<public_id>")
def update_model_usage_rate(public_id: str) -> Response:
    user = _current_user()
    profile = _model_profile_for_user(user.id)
    item = db.session.execute(
        select(ModelUsageRate).where(
            ModelUsageRate.public_id == public_id,
            ModelUsageRate.model_profile_id == profile.id,
        )
    ).scalar_one_or_none()
    if item is None:
        raise APIError(
            "model_usage_rate.not_found", "Usage rate was not found.", status=404
        )
    payload = _json_body()
    if "amount_minor" in payload:
        item.amount_minor = int(payload.get("amount_minor") or item.amount_minor)
    if "negotiable" in payload:
        item.negotiable = bool(payload.get("negotiable"))
    if "requires_review" in payload:
        item.requires_review = bool(payload.get("requires_review"))
    db.session.commit()
    return jsonify(success({"usage_rate": _usage_rate_payload(item)}))


@specialist_blueprint.get("/model/restricted-categories")
def model_restricted_categories() -> Response:
    profile = _model_profile_for_user(_current_user().id)
    return jsonify(
        success(
            {
                "restricted_categories": [
                    {
                        "category": row.category,
                        "blocked": row.blocked,
                        "reason": row.reason,
                    }
                    for row in profile.restricted_categories
                ]
            }
        )
    )


@specialist_blueprint.patch("/model/restricted-categories")
def update_model_restricted_categories() -> Response:
    user = _current_user()
    profile = _model_profile_or_create(user)
    payload = _json_body()
    categories = payload.get("categories")
    if not isinstance(categories, list):
        raise _field_error("categories", "Categories must be a list.")
    profile.restricted_categories.clear()
    db.session.flush()
    for entry in categories:
        if not isinstance(entry, dict):
            continue
        category = str(entry.get("category", "")).strip()[:64]
        if not category:
            continue
        db.session.add(
            ModelRestrictedCategory(
                model_profile_id=profile.id,
                category=category,
                blocked=bool(entry.get("blocked", True)),
                reason=str(entry.get("reason", "")).strip()[:2000] or None,
            )
        )
    db.session.commit()
    return jsonify(success({"model_profile": _model_profile_payload(profile)}))


# ---------------------------------------------------------------------------
# Distribution / release endpoints
# ---------------------------------------------------------------------------


@specialist_blueprint.get("/distribution/profile")
def distribution_profile() -> Response:
    user = _current_user()
    partner = db.session.execute(
        select(DistributionPartnerProfile).where(
            DistributionPartnerProfile.user_id == user.id
        )
    ).scalar_one_or_none()
    return jsonify(
        success(
            {"partner": _distribution_partner_payload(partner) if partner else None}
        )
    )


@specialist_blueprint.patch("/distribution/profile")
def upsert_distribution_profile() -> Response:
    user = _current_user()
    payload = _json_body()
    partner = db.session.execute(
        select(DistributionPartnerProfile).where(
            DistributionPartnerProfile.user_id == user.id
        )
    ).scalar_one_or_none()
    if partner is None:
        partner = DistributionPartnerProfile(user_id=user.id, name=user.display_name)
        db.session.add(partner)
    partner.name = str(payload.get("name", partner.name)).strip()[:180]
    partner.channels = (
        str(payload.get("channels", partner.channels or "")).strip()[:255] or None
    )
    partner.territories = (
        str(payload.get("territories", partner.territories or "")).strip()[:255] or None
    )
    db.session.commit()
    return jsonify(success({"partner": _distribution_partner_payload(partner)}))


@specialist_blueprint.post("/distribution-projects")
def create_distribution_project() -> ResponseReturnValue:
    user = _current_user()
    partner = _distribution_partner_for_owner(user)
    payload = _json_body()
    project = db.session.execute(
        select(Project).where(
            Project.public_id == str(payload.get("project_id", "")).strip()
        )
    ).scalar_one_or_none()
    if project is None:
        raise _field_error("project_id", "Project was not found.")
    item = DistributionProject(
        project_id=project.id,
        partner_profile_id=partner.id,
        release_window_start=_optional_date(
            payload.get("release_window_start"), "release_window_start"
        ),
        release_window_end=_optional_date(
            payload.get("release_window_end"), "release_window_end"
        ),
        territories=str(payload.get("territories", "")).strip()[:255] or None,
        missing_items=str(payload.get("missing_items", "")).strip()[:255] or None,
        status_note=str(payload.get("status_note", "")).strip()[:2000] or None,
        status=str(payload.get("status", "onboarding")).strip()[:32],
    )
    db.session.add(item)
    db.session.commit()
    return jsonify(
        success({"distribution_project": _distribution_project_payload(item)})
    ), 201


@specialist_blueprint.get("/distribution-projects")
def list_distribution_projects() -> Response:
    user = _current_user()
    partner = db.session.execute(
        select(DistributionPartnerProfile).where(
            DistributionPartnerProfile.user_id == user.id
        )
    ).scalar_one_or_none()
    if partner is not None:
        rows = db.session.execute(
            select(DistributionProject)
            .where(DistributionProject.partner_profile_id == partner.id)
            .order_by(DistributionProject.created_at.desc())
        ).scalars()
    else:
        rows = db.session.execute(
            select(DistributionProject)
            .join(Project, DistributionProject.project_id == Project.id)
            .where(Project.owner_user_id == user.id)
            .order_by(DistributionProject.created_at.desc())
        ).scalars()
    return jsonify(
        success(
            {
                "distribution_projects": [
                    _distribution_project_payload(row) for row in rows
                ]
            }
        )
    )


def _distribution_project_for_partner(
    public_id: str, user: User
) -> DistributionProject:
    item = db.session.execute(
        select(DistributionProject).where(DistributionProject.public_id == public_id)
    ).scalar_one_or_none()
    if item is None or item.partner_profile.user_id != user.id:
        raise APIError(
            "distribution_project.not_found",
            "Distribution project was not found.",
            status=404,
        )
    return item


@specialist_blueprint.patch("/distribution-projects/<public_id>")
def update_distribution_project(public_id: str) -> Response:
    user = _current_user()
    item = _distribution_project_for_partner(public_id, user)
    payload = _json_body()
    if "status" in payload:
        item.status = str(payload.get("status", "")).strip()[:32]
    if "status_note" in payload:
        item.status_note = str(payload.get("status_note", "")).strip()[:2000] or None
    if "missing_items" in payload:
        item.missing_items = str(payload.get("missing_items", "")).strip()[:255] or None
    if "release_window_start" in payload:
        item.release_window_start = _optional_date(
            payload.get("release_window_start"), "release_window_start"
        )
    if "release_window_end" in payload:
        item.release_window_end = _optional_date(
            payload.get("release_window_end"), "release_window_end"
        )
    db.session.commit()
    return jsonify(
        success({"distribution_project": _distribution_project_payload(item)})
    )


@specialist_blueprint.post("/distribution-projects/<public_id>/release-windows")
def create_release_window(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    item = _distribution_project_for_partner(public_id, user)
    payload = _json_body()
    window = ReleaseWindow(
        distribution_project_id=item.id,
        channel=str(payload.get("channel", "cinema")).strip()[:64],
        territory=str(payload.get("territory", "Pakistan")).strip()[:120],
        starts_on=_optional_date(payload.get("starts_on"), "starts_on"),
        ends_on=_optional_date(payload.get("ends_on"), "ends_on"),
        exclusivity=str(payload.get("exclusivity", "non_exclusive")).strip()[:32],
        status=str(payload.get("status", "planned")).strip()[:32],
    )
    db.session.add(window)
    db.session.commit()
    return jsonify(
        success({"distribution_project": _distribution_project_payload(item)})
    ), 201


@specialist_blueprint.post("/distribution-projects/<public_id>/handover-items")
def create_handover_item(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    item = _distribution_project_for_partner(public_id, user)
    payload = _json_body()
    handover = ReleaseHandoverItem(
        distribution_project_id=item.id,
        label=str(payload.get("label", "")).strip()[:180],
        detail=str(payload.get("detail", "")).strip()[:2000] or None,
        mandatory=bool(payload.get("mandatory", True)),
    )
    db.session.add(handover)
    db.session.commit()
    return jsonify(
        success({"distribution_project": _distribution_project_payload(item)})
    ), 201


@specialist_blueprint.patch("/release-handover-items/<item_id>")
def update_handover_item(item_id: str) -> Response:
    user = _current_user()
    try:
        item_uuid = uuid.UUID(item_id)
    except ValueError:
        raise APIError(
            "release_handover_item.not_found",
            "Handover item was not found.",
            status=404,
        ) from None
    handover = db.session.execute(
        select(ReleaseHandoverItem).where(ReleaseHandoverItem.id == item_uuid)
    ).scalar_one_or_none()
    if handover is None or handover.distribution_project.partner_profile.user_id != (
        user.id
    ):
        raise APIError(
            "release_handover_item.not_found",
            "Handover item was not found.",
            status=404,
        )
    payload = _json_body()
    if str(payload.get("file_id", "")).strip():
        handover.file_id = _owned_ready_file(
            str(payload.get("file_id")).strip(), user.id, "file_id"
        ).id
    if "status" in payload:
        handover.status = str(payload.get("status", "")).strip()[:32]
        if handover.status == "approved":
            handover.approved_at = utc_now()
    db.session.commit()
    return jsonify(
        success(
            {
                "distribution_project": _distribution_project_payload(
                    handover.distribution_project
                )
            }
        )
    )


@specialist_blueprint.post("/distributor-contacts")
def create_distributor_contact() -> ResponseReturnValue:
    user = _current_user()
    partner = _distribution_partner_for_owner(user)
    payload = _json_body()
    item = DistributorContact(
        partner_profile_id=partner.id,
        name=str(payload.get("name", "")).strip()[:180],
        channel=str(payload.get("channel", "cinema")).strip()[:64],
        territory=str(payload.get("territory", "")).strip()[:120] or None,
        contact_role=str(payload.get("contact_role", "")).strip()[:120] or None,
        email_token="encrypted:pending" if payload.get("email") else None,
        phone_token="encrypted:pending" if payload.get("phone") else None,
        prior_project=str(payload.get("prior_project", "")).strip()[:180] or None,
        notes=str(payload.get("notes", "")).strip()[:2000] or None,
    )
    db.session.add(item)
    db.session.commit()
    return jsonify(success({"contact": _distributor_contact_payload(item)})), 201


@specialist_blueprint.get("/distributor-contacts")
def list_distributor_contacts() -> Response:
    user = _current_user()
    partner = _distribution_partner_for_owner(user)
    rows = db.session.execute(
        select(DistributorContact)
        .where(DistributorContact.partner_profile_id == partner.id)
        .order_by(DistributorContact.created_at.desc())
    ).scalars()
    return jsonify(
        success({"contacts": [_distributor_contact_payload(row) for row in rows]})
    )


@specialist_blueprint.patch("/distributor-contacts/<public_id>")
def update_distributor_contact(public_id: str) -> Response:
    user = _current_user()
    partner = _distribution_partner_for_owner(user)
    item = db.session.execute(
        select(DistributorContact).where(
            DistributorContact.public_id == public_id,
            DistributorContact.partner_profile_id == partner.id,
        )
    ).scalar_one_or_none()
    if item is None:
        raise APIError(
            "distributor_contact.not_found", "Contact was not found.", status=404
        )
    payload = _json_body()
    if "notes" in payload:
        item.notes = str(payload.get("notes", "")).strip()[:2000] or None
    if "status" in payload:
        item.status = str(payload.get("status", "")).strip()[:32]
    db.session.commit()
    return jsonify(success({"contact": _distributor_contact_payload(item)}))


@specialist_blueprint.post("/distribution-reports")
def create_distribution_report() -> ResponseReturnValue:
    user = _current_user()
    partner = _distribution_partner_for_owner(user)
    payload = _json_body()
    project = _distribution_project_for_partner(
        str(payload.get("distribution_project_id", "")).strip(), user
    )
    period_start = _optional_date(payload.get("period_start"), "period_start")
    period_end = _optional_date(payload.get("period_end"), "period_end")
    if period_start is None or period_end is None:
        raise _field_error("period_start", "Report period is required.")
    source_file = None
    if str(payload.get("source_file_id", "")).strip():
        source_file = _owned_ready_file(
            str(payload.get("source_file_id")).strip(), user.id, "source_file_id"
        )
    item = DistributionReport(
        distribution_project_id=project.id,
        partner_profile_id=partner.id,
        territory=str(payload.get("territory", "Pakistan")).strip()[:120],
        channel=str(payload.get("channel", "cinema")).strip()[:64],
        period_start=period_start,
        period_end=period_end,
        audience_count=int(payload.get("audience_count") or 0),
        revenue_minor=int(payload.get("revenue_minor") or 0),
        currency=str(payload.get("currency", "PKR")).strip()[:3],
        source_file_id=source_file.id if source_file else None,
    )
    db.session.add(item)
    db.session.commit()
    return jsonify(success({"report": _distribution_report_payload(item)})), 201


@specialist_blueprint.get("/distribution-reports")
def list_distribution_reports() -> Response:
    user = _current_user()
    partner = _distribution_partner_for_owner(user)
    query = select(DistributionReport).where(
        DistributionReport.partner_profile_id == partner.id
    )
    project_public_id = request.args.get("distribution_project_id")
    if project_public_id:
        project = _distribution_project_for_partner(project_public_id, user)
        query = query.where(DistributionReport.distribution_project_id == project.id)
    rows = db.session.execute(
        query.order_by(DistributionReport.period_start.desc())
    ).scalars()
    return jsonify(
        success({"reports": [_distribution_report_payload(row) for row in rows]})
    )
