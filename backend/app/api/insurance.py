from __future__ import annotations

from typing import Any

from flask import Blueprint, Response, jsonify
from flask.typing import ResponseReturnValue
from sqlalchemy import func, or_, select

from app.api.auth import _current_user, _json_body
from app.api.bookings import _user_payload
from app.api.marketplace import _field_error, _file_payload, _owned_ready_file
from app.api.operations import _parse_datetime
from app.api.projects import _optional_date
from app.errors import APIError
from app.extensions import db
from app.models.bookings import Booking
from app.models.identity import User
from app.models.insurance import (
    InsuranceClaim,
    InsuranceClaimEvidence,
    InsurancePartnerProfile,
    InsurancePolicy,
)
from app.models.projects import Project
from app.responses import success

insurance_blueprint = Blueprint("insurance", __name__)


def _partner_for_owner(user: User) -> InsurancePartnerProfile:
    profile = db.session.execute(
        select(InsurancePartnerProfile).where(
            InsurancePartnerProfile.user_id == user.id
        )
    ).scalar_one_or_none()
    if profile is None:
        raise APIError(
            "insurance.profile_required",
            "Create an insurance partner profile first.",
            status=409,
        )
    return profile


def _partner_payload(item: InsurancePartnerProfile) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "name": item.name,
        "coverage_regions": item.coverage_regions,
        "status": item.status,
    }


def _policy_payload(
    item: InsurancePolicy, *, include_claims: bool = False
) -> dict[str, Any]:
    payload: dict[str, Any] = {
        "public_id": item.public_id,
        "project_id": item.project.public_id if item.project else None,
        "booking_id": item.booking.public_id if item.booking else None,
        "provider_profile_id": item.provider_profile.public_id,
        "insured_user": _user_payload(item.insured_user),
        "coverage_summary": item.coverage_summary,
        "valid_from": item.valid_from.isoformat(),
        "valid_to": item.valid_to.isoformat(),
        "document_file": _file_payload(item.document_file),
        "risk_level": item.risk_level,
        "status": item.status,
    }
    if include_claims:
        payload["claims"] = [_claim_payload(row) for row in item.claims]
    return payload


def _claim_evidence_payload(item: InsuranceClaimEvidence) -> dict[str, Any]:
    return {
        "file": _file_payload(item.file),
        "evidence_type": item.evidence_type,
        "mandatory": item.mandatory,
        "caption": item.caption,
    }


def _claim_payload(item: InsuranceClaim) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "policy_id": item.policy.public_id,
        "booking_id": item.booking.public_id if item.booking else None,
        "claimant": _user_payload(item.claimant),
        "title": item.title,
        "item_or_room": item.item_or_room,
        "adjuster": _user_payload(item.adjuster) if item.adjuster else None,
        "estimate_minor": item.estimate_minor,
        "currency": item.currency,
        "status": item.status,
        "due_at": item.due_at.isoformat() if item.due_at else None,
        "evidence": [_claim_evidence_payload(row) for row in item.evidence],
    }


@insurance_blueprint.get("/insurance/profile")
def insurance_profile() -> Response:
    user = _current_user()
    profile = db.session.execute(
        select(InsurancePartnerProfile).where(
            InsurancePartnerProfile.user_id == user.id
        )
    ).scalar_one_or_none()
    return jsonify(success({"profile": _partner_payload(profile) if profile else None}))


@insurance_blueprint.patch("/insurance/profile")
def upsert_insurance_profile() -> Response:
    user = _current_user()
    payload = _json_body()
    profile = db.session.execute(
        select(InsurancePartnerProfile).where(
            InsurancePartnerProfile.user_id == user.id
        )
    ).scalar_one_or_none()
    if profile is None:
        profile = InsurancePartnerProfile(user_id=user.id, name=user.display_name)
        db.session.add(profile)
    profile.name = str(payload.get("name", profile.name)).strip()[:180]
    profile.coverage_regions = (
        str(payload.get("coverage_regions", profile.coverage_regions or "")).strip()[
            :255
        ]
        or None
    )
    if payload.get("license_number"):
        profile.license_number_token = "encrypted:pending"
    db.session.commit()
    return jsonify(success({"profile": _partner_payload(profile)}))


@insurance_blueprint.post("/insurance/policies")
def create_insurance_policy() -> ResponseReturnValue:
    user = _current_user()
    provider = _partner_for_owner(user)
    payload = _json_body()

    insured_user = db.session.execute(
        select(User).where(
            User.public_id == str(payload.get("insured_user_id", "")).strip()
        )
    ).scalar_one_or_none()
    if insured_user is None:
        raise _field_error("insured_user_id", "Insured user was not found.")

    project = None
    project_public_id = str(payload.get("project_id", "")).strip()
    if project_public_id:
        project = db.session.execute(
            select(Project).where(Project.public_id == project_public_id)
        ).scalar_one_or_none()

    booking = None
    booking_public_id = str(payload.get("booking_id", "")).strip()
    if booking_public_id:
        booking = db.session.execute(
            select(Booking).where(Booking.public_id == booking_public_id)
        ).scalar_one_or_none()

    valid_from = _optional_date(payload.get("valid_from"), "valid_from")
    valid_to = _optional_date(payload.get("valid_to"), "valid_to")
    if valid_from is None or valid_to is None:
        raise _field_error("valid_from", "Policy validity dates are required.")

    document_file = None
    if str(payload.get("document_file_id", "")).strip():
        document_file = _owned_ready_file(
            str(payload.get("document_file_id")).strip(), user.id, "document_file_id"
        )

    policy = InsurancePolicy(
        project_id=project.id if project else None,
        booking_id=booking.id if booking else None,
        provider_profile_id=provider.id,
        insured_user_id=insured_user.id,
        coverage_summary=str(payload.get("coverage_summary", "")).strip()[:4000],
        valid_from=valid_from,
        valid_to=valid_to,
        document_file_id=document_file.id if document_file else None,
        risk_level=str(payload.get("risk_level", "low")).strip()[:32],
        status=str(payload.get("status", "active")).strip()[:32],
    )
    db.session.add(policy)
    db.session.commit()
    return jsonify(success({"policy": _policy_payload(policy)})), 201


@insurance_blueprint.get("/insurance/policies")
def list_insurance_policies() -> Response:
    user = _current_user()
    provider = db.session.execute(
        select(InsurancePartnerProfile).where(
            InsurancePartnerProfile.user_id == user.id
        )
    ).scalar_one_or_none()
    if provider is not None:
        rows = db.session.execute(
            select(InsurancePolicy)
            .where(InsurancePolicy.provider_profile_id == provider.id)
            .order_by(InsurancePolicy.created_at.desc())
        ).scalars()
    else:
        rows = db.session.execute(
            select(InsurancePolicy)
            .where(InsurancePolicy.insured_user_id == user.id)
            .order_by(InsurancePolicy.created_at.desc())
        ).scalars()
    return jsonify(success({"policies": [_policy_payload(row) for row in rows]}))


def _policy_for_party(public_id: str, user: User) -> InsurancePolicy:
    policy = db.session.execute(
        select(InsurancePolicy).where(InsurancePolicy.public_id == public_id)
    ).scalar_one_or_none()
    if policy is None or user.id not in {
        policy.provider_profile.user_id,
        policy.insured_user_id,
    }:
        raise APIError(
            "insurance_policy.not_found", "Policy was not found.", status=404
        )
    return policy


@insurance_blueprint.get("/insurance/policies/<public_id>")
def insurance_policy_detail(public_id: str) -> Response:
    user = _current_user()
    policy = _policy_for_party(public_id, user)
    return jsonify(success({"policy": _policy_payload(policy, include_claims=True)}))


@insurance_blueprint.post("/insurance/claims")
def create_insurance_claim() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    policy = _policy_for_party(str(payload.get("policy_id", "")).strip(), user)

    booking = None
    booking_public_id = str(payload.get("booking_id", "")).strip()
    if booking_public_id:
        booking = db.session.execute(
            select(Booking).where(Booking.public_id == booking_public_id)
        ).scalar_one_or_none()

    title = str(payload.get("title", "")).strip()
    if len(title) < 2:
        raise _field_error("title", "Claim title is required.")

    claim = InsuranceClaim(
        policy_id=policy.id,
        booking_id=booking.id if booking else None,
        claimant_user_id=user.id,
        title=title[:180],
        item_or_room=str(payload.get("item_or_room", "")).strip()[:180] or None,
        estimate_minor=int(payload.get("estimate_minor") or 0) or None,
        currency=str(payload.get("currency", "PKR")).strip()[:3],
        due_at=_parse_datetime(payload["due_at"], "due_at")
        if payload.get("due_at")
        else None,
    )
    db.session.add(claim)
    db.session.commit()
    return jsonify(success({"claim": _claim_payload(claim)})), 201


def _claim_for_party(public_id: str, user: User) -> InsuranceClaim:
    claim = db.session.execute(
        select(InsuranceClaim).where(InsuranceClaim.public_id == public_id)
    ).scalar_one_or_none()
    if claim is None:
        raise APIError("insurance_claim.not_found", "Claim was not found.", status=404)
    if user.id not in {
        claim.claimant_user_id,
        claim.policy.provider_profile.user_id,
        claim.adjuster_user_id,
    }:
        raise APIError(
            "insurance_claim.permission_denied", "Claim is not visible.", status=403
        )
    return claim


@insurance_blueprint.get("/insurance/claims")
def list_insurance_claims() -> Response:
    user = _current_user()
    provider = db.session.execute(
        select(InsurancePartnerProfile).where(
            InsurancePartnerProfile.user_id == user.id
        )
    ).scalar_one_or_none()
    if provider is not None:
        rows = db.session.execute(
            select(InsuranceClaim)
            .join(InsurancePolicy, InsuranceClaim.policy_id == InsurancePolicy.id)
            .where(InsurancePolicy.provider_profile_id == provider.id)
            .order_by(InsuranceClaim.created_at.desc())
        ).scalars()
    else:
        rows = db.session.execute(
            select(InsuranceClaim)
            .where(
                or_(
                    InsuranceClaim.claimant_user_id == user.id,
                    InsuranceClaim.adjuster_user_id == user.id,
                )
            )
            .order_by(InsuranceClaim.created_at.desc())
        ).scalars()
    return jsonify(success({"claims": [_claim_payload(row) for row in rows]}))


@insurance_blueprint.get("/insurance/claims/<public_id>")
def insurance_claim_detail(public_id: str) -> Response:
    user = _current_user()
    claim = _claim_for_party(public_id, user)
    return jsonify(success({"claim": _claim_payload(claim)}))


@insurance_blueprint.post("/insurance/claims/<public_id>/evidence")
def add_insurance_claim_evidence(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    claim = _claim_for_party(public_id, user)
    payload = _json_body()
    file = None
    if str(payload.get("file_id", "")).strip():
        file = _owned_ready_file(
            str(payload.get("file_id")).strip(), user.id, "file_id"
        )
    evidence = InsuranceClaimEvidence(
        claim_id=claim.id,
        file_id=file.id if file else None,
        evidence_type=str(payload.get("evidence_type", "photo")).strip()[:64],
        mandatory=bool(payload.get("mandatory", False)),
        caption=str(payload.get("caption", "")).strip()[:255] or None,
    )
    db.session.add(evidence)
    db.session.commit()
    return jsonify(success({"claim": _claim_payload(claim)})), 201


@insurance_blueprint.post("/insurance/claims/<public_id>/decision")
def decide_insurance_claim(public_id: str) -> Response:
    user = _current_user()
    claim = _claim_for_party(public_id, user)
    if claim.policy.provider_profile.user_id != user.id:
        raise APIError(
            "insurance_claim.permission_denied",
            "Only the insurance provider can decide claims.",
            status=403,
        )
    payload = _json_body()
    status = str(payload.get("status", "")).strip()
    if status not in {"investigating", "approved", "rejected", "settled"}:
        raise _field_error("status", "Unsupported claim status.")
    claim.status = status
    if payload.get("estimate_minor") is not None:
        claim.estimate_minor = int(payload.get("estimate_minor") or 0) or None
    if payload.get("adjuster_user_id"):
        adjuster = db.session.execute(
            select(User).where(
                User.public_id == str(payload.get("adjuster_user_id")).strip()
            )
        ).scalar_one_or_none()
        if adjuster is not None:
            claim.adjuster_user_id = adjuster.id
    db.session.commit()
    return jsonify(success({"claim": _claim_payload(claim)}))


@insurance_blueprint.get("/insurance/dashboard")
def insurance_dashboard() -> Response:
    user = _current_user()
    provider = _partner_for_owner(user)
    policy_count = db.session.execute(
        select(func.count()).where(InsurancePolicy.provider_profile_id == provider.id)
    ).scalar_one()
    active_policy_count = db.session.execute(
        select(func.count()).where(
            InsurancePolicy.provider_profile_id == provider.id,
            InsurancePolicy.status == "active",
        )
    ).scalar_one()
    open_claims = db.session.execute(
        select(func.count())
        .select_from(InsuranceClaim)
        .join(InsurancePolicy, InsuranceClaim.policy_id == InsurancePolicy.id)
        .where(
            InsurancePolicy.provider_profile_id == provider.id,
            InsuranceClaim.status.in_(("submitted", "investigating")),
        )
    ).scalar_one()
    return jsonify(
        success(
            {
                "policy_count": policy_count,
                "active_policy_count": active_policy_count,
                "open_claims": open_claims,
            }
        )
    )
