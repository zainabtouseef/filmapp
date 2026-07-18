from __future__ import annotations

import hashlib
import json
from datetime import timedelta
from decimal import Decimal
from typing import Any

from flask import Blueprint, Response, jsonify, request
from flask.typing import ResponseReturnValue
from sqlalchemy import select

from app.api.auth import _current_user, _json_body
from app.api.bookings import _booking_for_user, _user_payload
from app.api.marketplace import _field_error, _file_payload
from app.errors import APIError
from app.extensions import db
from app.models.base import utc_now
from app.models.contracts import (
    Contract,
    ContractAddendum,
    ContractClause,
    ContractParty,
    ContractSignature,
    ContractTemplate,
    LegalBillingRecord,
    LegalClauseRisk,
    LegalReviewRequest,
)
from app.models.files import FileAsset
from app.models.identity import User
from app.responses import success

contracts_blueprint = Blueprint("contracts", __name__)


def _has_role(user: User, *codes: str) -> bool:
    return any(
        user_role.status == "active" and user_role.role.code in codes
        for user_role in user.roles
    )


def _template_payload(item: ContractTemplate) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "name": item.name,
        "category": item.category,
        "jurisdiction": item.jurisdiction,
        "version_number": item.version_number,
        "status": item.status,
        "published_at": item.published_at.isoformat() if item.published_at else None,
        "clauses": [
            {
                "clause_key": row.clause_key,
                "title": row.title,
                "body_text": row.body_text,
                "sort_order": row.sort_order,
                "required": row.required,
                "editable": row.editable,
            }
            for row in item.clauses
        ],
    }


def _party_payload(item: ContractParty) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "user": _user_payload(item.user),
        "organization_id": item.organization_id,
        "party_role": item.party_role,
        "signing_order": item.signing_order,
        "status": item.status,
    }


def _clause_payload(item: ContractClause) -> dict[str, Any]:
    return {
        "clause_key": item.clause_key,
        "title": item.title,
        "body_text": item.body_text,
        "sort_order": item.sort_order,
        "highlighted": item.highlighted,
    }


def _signature_payload(item: ContractSignature) -> dict[str, Any]:
    return {
        "party_id": item.party.public_id,
        "signer": _user_payload(item.signer),
        "signature_file": _file_payload(item.signature_file),
        "signature_hash": item.signature_hash,
        "signed_at": item.signed_at.isoformat(),
    }


def _addendum_payload(item: ContractAddendum) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "requested_by": _user_payload(item.requester),
        "reason": item.reason,
        "content": item.content,
        "status": item.status,
        "created_at": item.created_at.isoformat(),
    }


def _contract_payload(item: Contract) -> dict[str, Any]:
    signatures = [signature for party in item.parties for signature in party.signatures]
    return {
        "public_id": item.public_id,
        "booking_id": item.booking.public_id,
        "project_id": item.project.public_id,
        "template": _template_payload(item.template),
        "version_number": item.version_number,
        "title": item.title,
        "status": item.status,
        "effective_date": item.effective_date.isoformat()
        if item.effective_date
        else None,
        "value_minor": item.value_minor,
        "currency": item.currency,
        "rendered_file": _file_payload(item.rendered_file),
        "content_snapshot": json.loads(item.content_snapshot_json),
        "signature_progress": f"{Decimal(item.signature_progress):.3f}",
        "parties": [_party_payload(row) for row in item.parties],
        "clauses": [_clause_payload(row) for row in item.clauses],
        "signatures": [_signature_payload(row) for row in signatures],
        "addendums": [_addendum_payload(row) for row in item.addendums],
    }


def _risk_payload(item: LegalClauseRisk) -> dict[str, Any]:
    return {
        "risk_level": item.risk_level,
        "issue": item.issue,
        "recommendation": item.recommendation,
        "status": item.status,
        "contract_clause_key": item.contract_clause.clause_key
        if item.contract_clause
        else None,
    }


def _review_payload(item: LegalReviewRequest) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "contract_id": item.contract.public_id if item.contract else None,
        "template_id": item.template.public_id if item.template else None,
        "addendum_id": item.addendum.public_id if item.addendum else None,
        "requested_by": _user_payload(item.requester),
        "assigned_legal": _user_payload(item.assigned_legal)
        if item.assigned_legal
        else None,
        "contract_type": item.contract_type,
        "risk": item.risk,
        "status": item.status,
        "sla_due_at": item.sla_due_at.isoformat() if item.sla_due_at else None,
        "decision_notes": item.decision_notes,
        "risks": [_risk_payload(row) for row in item.risks],
        "created_at": item.created_at.isoformat(),
    }


def _contract_for_user(public_id: str, user: User) -> Contract:
    contract = db.session.execute(
        select(Contract)
        .join(ContractParty, ContractParty.contract_id == Contract.id)
        .where(Contract.public_id == public_id, ContractParty.user_id == user.id)
    ).scalar_one_or_none()
    if contract is None:
        raise APIError("contract.not_found", "Contract was not found.", status=404)
    return contract


def _published_template(category: str) -> ContractTemplate:
    template = db.session.execute(
        select(ContractTemplate).where(
            ContractTemplate.category == category,
            ContractTemplate.status == "published",
        )
    ).scalar_one_or_none()
    if template is None:
        raise APIError(
            "contract.template_missing",
            "No published contract template is available.",
            status=409,
        )
    return template


def _update_signature_progress(contract: Contract) -> None:
    signed = len([party for party in contract.parties if party.status == "signed"])
    total = len(contract.parties) or 1
    contract.signature_progress = Decimal(signed) / Decimal(total)
    if signed == total:
        contract.status = "signed"


@contracts_blueprint.get("/contract-templates")
def contract_templates() -> Response:
    rows = db.session.execute(
        select(ContractTemplate)
        .where(ContractTemplate.status == "published")
        .order_by(
            ContractTemplate.category.asc(), ContractTemplate.version_number.desc()
        )
    ).scalars()
    return jsonify(success({"templates": [_template_payload(row) for row in rows]}))


@contracts_blueprint.get("/contracts")
def contracts() -> Response:
    user = _current_user()
    rows = db.session.execute(
        select(Contract)
        .join(ContractParty, ContractParty.contract_id == Contract.id)
        .where(ContractParty.user_id == user.id)
        .order_by(Contract.updated_at.desc())
        .limit(100)
    ).scalars()
    return jsonify(success({"contracts": [_contract_payload(row) for row in rows]}))


@contracts_blueprint.post("/bookings/<public_id>/contracts")
def generate_contract(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    booking = _booking_for_user(public_id, user)
    if booking.status != "accepted":
        raise APIError(
            "contract.booking_not_ready",
            "Only accepted bookings can generate contracts.",
            status=409,
        )
    if booking.requester_user_id != user.id:
        raise APIError(
            "contract.permission_denied",
            "Only the booking requester can generate the contract.",
            status=403,
        )
    existing = db.session.execute(
        select(Contract).where(Contract.booking_id == booking.id)
    ).scalar_one_or_none()
    if existing is not None:
        return jsonify(success({"contract": _contract_payload(existing)}))
    template = _published_template(booking.category)
    snapshot = {
        "booking_id": booking.public_id,
        "project_title": booking.project.title,
        "provider": booking.provider.display_name,
        "requester": booking.requester.display_name,
        "start_at": booking.start_at.isoformat(),
        "end_at": booking.end_at.isoformat(),
        "amount_minor": booking.agreed_amount_minor,
        "currency": booking.currency,
        "template_version": template.version_number,
    }
    contract = Contract(
        booking_id=booking.id,
        project_id=booking.project_id,
        template_id=template.id,
        version_number=1,
        title=f"{booking.project.title} — {template.name}",
        status="pending_signature",
        effective_date=booking.start_at.date(),
        value_minor=booking.agreed_amount_minor,
        currency=booking.currency,
        content_snapshot_json=json.dumps(snapshot, sort_keys=True),
        signature_progress=Decimal("0"),
    )
    db.session.add(contract)
    db.session.flush()
    db.session.add_all(
        [
            ContractParty(
                contract_id=contract.id,
                user_id=booking.requester_user_id,
                party_role="producer",
                signing_order=1,
            ),
            ContractParty(
                contract_id=contract.id,
                user_id=booking.provider_user_id,
                party_role=booking.category,
                signing_order=2,
            ),
        ]
    )
    for clause in template.clauses:
        db.session.add(
            ContractClause(
                contract_id=contract.id,
                clause_key=clause.clause_key,
                title=clause.title,
                body_text=clause.body_text,
                sort_order=clause.sort_order,
                highlighted=clause.clause_key in {"usage_rights", "payment_schedule"},
                source_template_clause_id=clause.id,
            )
        )
    db.session.commit()
    return jsonify(success({"contract": _contract_payload(contract)})), 201


@contracts_blueprint.get("/contracts/<public_id>")
def contract_detail(public_id: str) -> Response:
    user = _current_user()
    return jsonify(
        success({"contract": _contract_payload(_contract_for_user(public_id, user))})
    )


@contracts_blueprint.post("/contracts/<public_id>/signatures")
def sign_contract(public_id: str) -> Response:
    user = _current_user()
    contract = _contract_for_user(public_id, user)
    party = next((row for row in contract.parties if row.user_id == user.id), None)
    if party is None:
        raise APIError(
            "contract.permission_denied", "Not a contract party.", status=403
        )
    if party.status == "signed":
        return jsonify(success({"contract": _contract_payload(contract)}))
    payload = _json_body()
    signature_file_id = None
    raw_file_id = str(payload.get("signature_file_id", "")).strip()
    if raw_file_id:
        file = db.session.execute(
            select(FileAsset).where(
                FileAsset.public_id == raw_file_id,
                FileAsset.owner_user_id == user.id,
                FileAsset.scan_status == "clean",
                FileAsset.processing_status == "ready",
            )
        ).scalar_one_or_none()
        if file is None:
            raise _field_error(
                "signature_file_id", "Signature file must be owned and ready."
            )
        signature_file_id = file.id
    signed_at = utc_now()
    signature_hash = hashlib.sha256(
        f"{contract.public_id}:{party.public_id}:{user.public_id}:{signed_at.isoformat()}".encode()
    ).hexdigest()
    db.session.add(
        ContractSignature(
            contract_id=contract.id,
            party_id=party.id,
            signer_user_id=user.id,
            signature_file_id=signature_file_id,
            signature_hash=signature_hash,
            signed_at=signed_at,
            ip_address=request.headers.get("X-Forwarded-For", request.remote_addr),
            user_agent=request.headers.get("User-Agent"),
        )
    )
    party.status = "signed"
    _update_signature_progress(contract)
    if contract.status == "signed":
        from app.services.payments import ensure_payment_schedule_for_contract

        ensure_payment_schedule_for_contract(contract)
    db.session.commit()
    return jsonify(success({"contract": _contract_payload(contract)}))


@contracts_blueprint.post("/contracts/<public_id>/addendums")
def create_addendum(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    contract = _contract_for_user(public_id, user)
    payload = _json_body()
    reason = str(payload.get("reason", "")).strip()
    content = str(payload.get("content", "")).strip()
    if len(reason) < 3:
        raise _field_error("reason", "Addendum reason is required.")
    if len(content) < 3:
        raise _field_error("content", "Addendum content is required.")
    item = ContractAddendum(
        contract_id=contract.id,
        requested_by=user.id,
        reason=reason[:2000],
        content=content[:8000],
        status="review_requested",
    )
    db.session.add(item)
    db.session.flush()
    db.session.add(
        LegalReviewRequest(
            contract_id=contract.id,
            addendum_id=item.id,
            requested_by=user.id,
            contract_type=f"{contract.template.category}_addendum",
            risk="medium",
            status="requested",
            sla_due_at=utc_now() + timedelta(days=2),
        )
    )
    db.session.commit()
    return jsonify(success({"addendum": _addendum_payload(item)})), 201


@contracts_blueprint.post("/legal-reviews")
def request_legal_review() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    contract_id = str(payload.get("contract_id", "")).strip()
    contract = _contract_for_user(contract_id, user)
    item = LegalReviewRequest(
        contract_id=contract.id,
        template_id=contract.template_id,
        requested_by=user.id,
        contract_type=str(
            payload.get("contract_type") or contract.template.category
        ).strip(),
        risk=str(payload.get("risk", "medium")).strip(),
        status="requested",
        sla_due_at=utc_now() + timedelta(days=2),
    )
    db.session.add(item)
    db.session.commit()
    return jsonify(success({"review": _review_payload(item)})), 201


@contracts_blueprint.get("/legal/reviews")
def legal_reviews() -> Response:
    user = _current_user()
    if not _has_role(user, "legal_partner", "super_admin", "reviewer"):
        raise APIError("legal.permission_denied", "Legal role is required.", status=403)
    rows = db.session.execute(
        select(LegalReviewRequest)
        .order_by(LegalReviewRequest.created_at.desc())
        .limit(100)
    ).scalars()
    return jsonify(success({"reviews": [_review_payload(row) for row in rows]}))


@contracts_blueprint.get("/legal-reviews/<public_id>")
def legal_review_detail(public_id: str) -> Response:
    user = _current_user()
    item = db.session.execute(
        select(LegalReviewRequest).where(LegalReviewRequest.public_id == public_id)
    ).scalar_one_or_none()
    if item is None:
        raise APIError(
            "legal_review.not_found", "Legal review was not found.", status=404
        )
    if item.requested_by != user.id and not _has_role(
        user, "legal_partner", "super_admin", "reviewer"
    ):
        raise APIError(
            "legal.permission_denied", "Legal review is not visible.", status=403
        )
    return jsonify(success({"review": _review_payload(item)}))


@contracts_blueprint.post("/legal-reviews/<public_id>/decision")
def legal_review_decision(public_id: str) -> Response:
    user = _current_user()
    if not _has_role(user, "legal_partner", "super_admin", "reviewer"):
        raise APIError("legal.permission_denied", "Legal role is required.", status=403)
    item = db.session.execute(
        select(LegalReviewRequest).where(LegalReviewRequest.public_id == public_id)
    ).scalar_one_or_none()
    if item is None:
        raise APIError(
            "legal_review.not_found", "Legal review was not found.", status=404
        )
    payload = _json_body()
    status = str(payload.get("status", "approved")).strip()
    if status not in {"approved", "changes_requested", "rejected"}:
        raise _field_error("status", "Unsupported legal review decision.")
    item.status = status
    item.assigned_legal_user_id = user.id
    item.decision_notes = str(payload.get("decision_notes", "")).strip()[:4000] or None
    if (
        item.contract
        and status == "approved"
        and item.contract.status == "pending_legal_review"
    ):
        item.contract.status = "pending_signature"
    db.session.add(
        LegalBillingRecord(
            legal_user_id=user.id,
            matter_type="contract_review",
            matter_id=item.public_id,
            client_user_id=item.requested_by,
            minutes=int(payload.get("minutes") or 0),
            amount_minor=int(payload.get("amount_minor") or 0),
            currency="PKR",
            status="draft",
            notes=item.decision_notes,
        )
    )
    db.session.commit()
    return jsonify(success({"review": _review_payload(item)}))
