from __future__ import annotations

import json
import sys
from datetime import UTC, datetime, timedelta
from decimal import Decimal
from pathlib import Path
from typing import Any

from sqlalchemy import select

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app import create_app
from app.extensions import db
from app.models import (
    AvailabilityEntry,
    Booking,
    BookingFeeSnapshot,
    BookingParticipant,
    BookingStatusEvent,
    Contract,
    ContractAddendum,
    ContractClause,
    ContractParty,
    ContractSignature,
    ContractTemplate,
    Conversation,
    ConversationMember,
    FeeRule,
    FileAsset,
    LedgerEntry,
    LegalBillingRecord,
    LegalClauseRisk,
    LegalReviewRequest,
    MarketplaceListing,
    Message,
    NegotiationRound,
    NegotiationThread,
    Offer,
    PaymentMilestone,
    PaymentProof,
    PaymentSchedule,
    PaymentTransaction,
    PayoutAccount,
    Project,
    ProjectRequirement,
    Receipt,
    TemplateClause,
    User,
)


SEED_BATCH = "cineconnect-demo-2026-07-18"
NOW = datetime.now(UTC)


PROJECT_TITLES = [
    "River Lights",
    "City of Dust",
    "Blue Van",
    "Eid Run",
    "Salt Road",
    "Campus Beat",
    "Night Bazaar",
    "Monsoon Menu",
    "Safe Set PSA",
    "Desert Echo",
]

BOOKING_STATUSES = [
    "accepted",
    "sent",
    "secured",
    "countered",
    "accepted",
    "sent",
    "accepted",
    "completed",
    "secured",
    "accepted",
]

PAYMENT_PROOF_STATUSES = [
    "pending",
    "approved",
    "rejected",
    "approved",
    "pending",
    "approved",
    "pending",
    "approved",
    "rejected",
    "approved",
]

CONTRACT_STATUSES = [
    "pending_signature",
    "pending_signature",
    "signed",
    "draft",
    "pending_signature",
    "signed",
    "legal_review",
    "signed",
    "legal_review",
    "signed",
]


def one(model: type[Any], **where: Any) -> Any | None:
    return db.session.execute(select(model).filter_by(**where)).scalar_one_or_none()


def many(model: type[Any], **where: Any) -> list[Any]:
    return list(db.session.execute(select(model).filter_by(**where)).scalars())


def remember(stats: dict[str, int], key: str, created: bool) -> None:
    suffix = "created" if created else "existing"
    stats[f"{key}_{suffix}"] = stats.get(f"{key}_{suffix}", 0) + 1


def ensure(
    model: type[Any],
    stats: dict[str, int],
    key: str,
    defaults: dict[str, Any] | None = None,
    **where: Any,
) -> Any:
    row = one(model, **where)
    if row is not None:
        remember(stats, key, False)
        return row
    row = model(**where, **(defaults or {}))
    db.session.add(row)
    db.session.flush()
    remember(stats, key, True)
    return row


def required(model: type[Any], **where: Any) -> Any:
    row = one(model, **where)
    if row is None:
        raise RuntimeError(f"Missing required {model.__name__}: {where}")
    return row


def user(public_id: str) -> User:
    return required(User, public_id=public_id)


def file_asset(public_id: str) -> FileAsset:
    return required(FileAsset, public_id=public_id)


def ensure_contract_template(stats: dict[str, int], admin: User) -> ContractTemplate:
    template = ensure(
        ContractTemplate,
        stats,
        "contract_template",
        public_id="DEMO-TPL-TALENT-001",
        defaults={
            "name": "Demo Talent Engagement Agreement",
            "category": "talent_booking",
            "jurisdiction": "PK",
            "version_number": 1,
            "body_schema_json": json.dumps(
                {"seed_batch": SEED_BATCH, "tokens": ["project", "fee", "dates"]}
            ),
            "status": "published",
            "created_by": admin.id,
            "approved_by": admin.id,
            "published_at": NOW - timedelta(days=10),
        },
    )
    clauses = [
        (
            "parties",
            "Parties",
            "Producer and talent are the named contracting parties.",
        ),
        ("project", "Project", "Engagement is limited to the seeded demo project."),
        (
            "payment",
            "Payment Schedule",
            "Payment follows the attached milestone schedule.",
        ),
        (
            "usage",
            "Usage Rights",
            "Usage is limited to the campaign scope unless amended.",
        ),
        (
            "cancellation",
            "Cancellation",
            "Cancellation fees follow the platform policy.",
        ),
    ]
    for order, (key_name, title, body) in enumerate(clauses, start=1):
        ensure(
            TemplateClause,
            stats,
            "template_clause",
            template_id=template.id,
            clause_key=key_name,
            defaults={
                "title": title,
                "body_text": body,
                "sort_order": order,
                "required": True,
                "editable": key_name in {"usage", "cancellation"},
            },
        )
    return template


def seed_bookings(stats: dict[str, int]) -> list[Booking]:
    bookings: list[Booking] = []
    for idx in range(1, 11):
        project = required(Project, public_id=f"DEMO-PROJ-{idx:03}")
        producer = user(f"DEMO-DP-{idx:03}")
        talent = user(f"DEMO-AT-{idx:03}")
        listing = required(MarketplaceListing, public_id=f"DEMO-LST-AT-{idx:03}")
        requirement = (
            db.session.execute(
                select(ProjectRequirement)
                .where(ProjectRequirement.project_id == project.id)
                .order_by(ProjectRequirement.created_at)
            )
            .scalars()
            .first()
        )
        amount_minor = (180_000 + idx * 25_000) * 100
        start = datetime(2026, 9, idx + 1, 9, tzinfo=UTC)
        booking = ensure(
            Booking,
            stats,
            "booking",
            public_id=f"DEMO-BKG-{idx:03}",
            defaults={
                "project_id": project.id,
                "requirement_id": requirement.id if requirement else None,
                "requester_user_id": producer.id,
                "provider_user_id": talent.id,
                "listing_id": listing.id,
                "category": "actor_talent",
                "status": BOOKING_STATUSES[idx - 1],
                "agreed_amount_minor": amount_minor if idx not in {2, 4, 6} else None,
                "currency": "PKR",
                "start_at": start,
                "end_at": start + timedelta(days=2, hours=8),
                "expires_at": start - timedelta(days=3),
                "secured_at": NOW - timedelta(days=2)
                if BOOKING_STATUSES[idx - 1] in {"secured", "completed"}
                else None,
            },
        )
        bookings.append(booking)
        for participant, role_name, can_finance in [
            (producer, "requester", True),
            (talent, "provider", True),
        ]:
            ensure(
                BookingParticipant,
                stats,
                "booking_participant",
                booking_id=booking.id,
                user_id=participant.id,
                defaults={
                    "participant_role": role_name,
                    "can_chat": True,
                    "can_view_finance": can_finance,
                },
            )
        for event_idx, status in enumerate(["draft", "sent", booking.status], start=1):
            ensure(
                BookingStatusEvent,
                stats,
                "booking_status_event",
                booking_id=booking.id,
                to_status=status,
                defaults={
                    "actor_user_id": producer.id if event_idx < 3 else talent.id,
                    "from_status": None if event_idx == 1 else "sent",
                    "reason": f"{SEED_BATCH} booking status trail",
                    "metadata_json": json.dumps({"is_demo": True, "step": event_idx}),
                },
            )
        offer_ids = []
        for rev in range(1, 4):
            sender, recipient = (
                (producer, talent) if rev % 2 == 1 else (talent, producer)
            )
            offer = ensure(
                Offer,
                stats,
                "offer",
                public_id=f"DEMO-OFF-{idx:03}-{rev}",
                defaults={
                    "booking_id": booking.id,
                    "sender_user_id": sender.id,
                    "recipient_user_id": recipient.id,
                    "revision": rev,
                    "fee_minor": amount_minor + (rev - 2) * 15_000 * 100,
                    "currency": "PKR",
                    "schedule_json": json.dumps(
                        {
                            "start": booking.start_at.isoformat(),
                            "end": booking.end_at.isoformat(),
                        }
                    ),
                    "conditions": f"Demo round {rev} terms for {PROJECT_TITLES[idx - 1]}",
                    "payment_schedule_json": json.dumps(
                        {"advance_percent": 50, "completion_percent": 50}
                    ),
                    "status": "active"
                    if rev == 3 and booking.status in {"sent", "countered"}
                    else "accepted"
                    if booking.status in {"accepted", "secured", "completed"}
                    and rev == 3
                    else "superseded",
                    "expires_at": booking.expires_at,
                },
            )
            offer_ids.append(offer)
        thread = ensure(
            NegotiationThread,
            stats,
            "negotiation_thread",
            public_id=f"DEMO-NEG-{idx:03}",
            defaults={
                "booking_id": booking.id,
                "status": "locked"
                if booking.status in {"accepted", "secured", "completed"}
                else "open",
                "current_offer_id": offer_ids[-1].id,
                "locked_at": NOW - timedelta(days=1)
                if booking.status in {"accepted", "secured", "completed"}
                else None,
            },
        )
        if thread.current_offer_id is None:
            thread.current_offer_id = offer_ids[-1].id
        for round_no, offer in enumerate(offer_ids, start=1):
            ensure(
                NegotiationRound,
                stats,
                "negotiation_round",
                thread_id=thread.id,
                round_number=round_no,
                defaults={
                    "offer_id": offer.id,
                    "sender_user_id": offer.sender_user_id,
                    "message": f"Demo negotiation round {round_no} for {PROJECT_TITLES[idx - 1]}.",
                },
            )
        conv = ensure(
            Conversation,
            stats,
            "conversation",
            public_id=f"DEMO-CONV-{idx:03}",
            defaults={
                "booking_id": booking.id,
                "project_id": project.id,
                "type": "booking",
                "title": f"{PROJECT_TITLES[idx - 1]} booking chat",
                "last_message_at": NOW - timedelta(hours=idx),
            },
        )
        for member in [producer, talent]:
            ensure(
                ConversationMember,
                stats,
                "conversation_member",
                conversation_id=conv.id,
                user_id=member.id,
                defaults={},
            )
        for msg_idx in range(1, 11):
            sender = producer if msg_idx % 2 else talent
            ensure(
                Message,
                stats,
                "message",
                public_id=f"DEMO-MSG-{idx:03}-{msg_idx:02}",
                defaults={
                    "conversation_id": conv.id,
                    "sender_user_id": sender.id,
                    "message_type": "decision" if msg_idx == 10 else "text",
                    "body": f"Demo chat message {msg_idx} for {PROJECT_TITLES[idx - 1]}.",
                    "decision_type": "schedule_locked" if msg_idx == 10 else None,
                },
            )
        if booking.status in {"accepted", "secured", "completed"}:
            calendar_entry = required(
                AvailabilityEntry, public_id=f"DEMO-AVL-AT-{idx:03}-2"
            )
            calendar_entry.status = "booked"
            calendar_entry.source_booking_id = booking.id
        booking.status = BOOKING_STATUSES[idx - 1]
    return bookings


def seed_contracts_and_legal(
    stats: dict[str, int],
    bookings: list[Booking],
    template: ContractTemplate,
) -> list[Contract]:
    contracts: list[Contract] = []
    legal_users = [user(f"DEMO-LG-{idx:03}") for idx in range(1, 11)]
    for idx, booking in enumerate(bookings, start=1):
        producer = user(f"DEMO-DP-{idx:03}")
        talent = user(f"DEMO-AT-{idx:03}")
        contract = ensure(
            Contract,
            stats,
            "contract",
            public_id=f"DEMO-CTR-{idx:03}",
            defaults={
                "booking_id": booking.id,
                "project_id": booking.project_id,
                "template_id": template.id,
                "version_number": 1,
                "title": f"{PROJECT_TITLES[idx - 1]} Talent Agreement",
                "status": CONTRACT_STATUSES[idx - 1],
                "effective_date": booking.start_at.date(),
                "value_minor": booking.agreed_amount_minor
                or (180_000 + idx * 25_000) * 100,
                "currency": "PKR",
                "rendered_file_id": file_asset(
                    f"DEMO-FILE-PROJECT-{((idx - 1) % 20) + 1:03}"
                ).id,
                "content_snapshot_json": json.dumps(
                    {"seed_batch": SEED_BATCH, "booking": booking.public_id}
                ),
                "signature_progress": Decimal("1.000")
                if CONTRACT_STATUSES[idx - 1] == "signed"
                else Decimal("0.500"),
            },
        )
        contracts.append(contract)
        for order, party_user, party_role in [
            (1, producer, "producer"),
            (2, talent, "talent"),
        ]:
            party = ensure(
                ContractParty,
                stats,
                "contract_party",
                public_id=f"DEMO-PARTY-{idx:03}-{order}",
                defaults={
                    "contract_id": contract.id,
                    "user_id": party_user.id,
                    "party_role": party_role,
                    "signing_order": order,
                    "status": "signed"
                    if contract.status == "signed" or order == 1
                    else "pending",
                },
            )
            if party.status == "signed":
                ensure(
                    ContractSignature,
                    stats,
                    "contract_signature",
                    contract_id=contract.id,
                    party_id=party.id,
                    signer_user_id=party_user.id,
                    defaults={
                        "signature_file_id": file_asset(
                            f"DEMO-FILE-PROJECT-{((idx + order - 1) % 20) + 1:03}"
                        ).id,
                        "signature_hash": f"demo-signature-{idx:03}-{order}",
                        "signed_at": NOW - timedelta(days=idx),
                        "ip_address": "127.0.0.1",
                        "user_agent": "CineConnect demo seed",
                    },
                )
        for order, tpl_clause in enumerate(template.clauses, start=1):
            clause = ensure(
                ContractClause,
                stats,
                "contract_clause",
                contract_id=contract.id,
                clause_key=tpl_clause.clause_key,
                defaults={
                    "title": tpl_clause.title,
                    "body_text": f"{tpl_clause.body_text} Demo project: {PROJECT_TITLES[idx - 1]}.",
                    "sort_order": order,
                    "highlighted": tpl_clause.clause_key in {"payment", "usage"},
                    "source_template_clause_id": tpl_clause.id,
                },
            )
        review = ensure(
            LegalReviewRequest,
            stats,
            "legal_review",
            public_id=f"DEMO-LGR-{idx:03}",
            defaults={
                "contract_id": contract.id,
                "requested_by": producer.id,
                "assigned_legal_user_id": legal_users[idx - 1].id,
                "contract_type": "talent_booking",
                "risk": "high" if idx in {7, 9} else "medium" if idx % 2 else "low",
                "status": "approved" if idx in {3, 6, 8, 10} else "requested",
                "sla_due_at": NOW + timedelta(days=2 + idx),
                "decision_notes": "Demo legal approval"
                if idx in {3, 6, 8, 10}
                else None,
            },
        )
        ensure(
            LegalClauseRisk,
            stats,
            "legal_risk",
            review_request_id=review.id,
            issue=f"Usage scope check for {PROJECT_TITLES[idx - 1]}",
            defaults={
                "contract_clause_id": clause.id,
                "risk_level": review.risk,
                "recommendation": "Confirm campaign duration and territory before final signature.",
                "status": "resolved" if review.status == "approved" else "open",
            },
        )
        if idx in {4, 7, 9}:
            addendum = ensure(
                ContractAddendum,
                stats,
                "contract_addendum",
                public_id=f"DEMO-ADD-{idx:03}",
                defaults={
                    "contract_id": contract.id,
                    "requested_by": producer.id,
                    "reason": "Demo schedule/usage change",
                    "content": "Add one contingency shoot day and clarify promotional usage.",
                    "status": "review_requested",
                    "reviewer_id": legal_users[idx - 1].id,
                },
            )
            review.addendum_id = addendum.id
        ensure(
            LegalBillingRecord,
            stats,
            "legal_billing",
            public_id=f"DEMO-LGB-{idx:03}",
            defaults={
                "legal_user_id": legal_users[idx - 1].id,
                "matter_type": "contract_review",
                "matter_id": review.public_id,
                "client_user_id": producer.id,
                "minutes": 45 + idx * 5,
                "amount_minor": (20_000 + idx * 2_500) * 100,
                "currency": "PKR",
                "invoice_number": f"DEMO-LAW-{idx:03}",
                "status": "issued" if review.status == "approved" else "draft",
                "notes": "Demo legal billing record",
            },
        )
    return contracts


def seed_payments(
    stats: dict[str, int], bookings: list[Booking], contracts: list[Contract]
) -> None:
    admin = user("DEMO-ADMIN-001")
    fee_rule = (
        db.session.execute(select(FeeRule).where(FeeRule.active.is_(True)))
        .scalars()
        .first()
    )
    for idx, (booking, contract) in enumerate(
        zip(bookings, contracts, strict=True), start=1
    ):
        payer = user(f"DEMO-DP-{idx:03}")
        payee = user(f"DEMO-AT-{idx:03}")
        total = contract.value_minor or (200_000 + idx * 20_000) * 100
        schedule = ensure(
            PaymentSchedule,
            stats,
            "payment_schedule",
            public_id=f"DEMO-PS-{idx:03}",
            defaults={
                "booking_id": booking.id,
                "contract_id": contract.id,
                "total_minor": total,
                "currency": "PKR",
                "status": "active" if idx != 8 else "completed",
            },
        )
        for seq, (name, percent) in enumerate(
            [("Advance", 50), ("Completion", 50)], start=1
        ):
            milestone = ensure(
                PaymentMilestone,
                stats,
                "payment_milestone",
                public_id=f"DEMO-PM-{idx:03}-{seq}",
                defaults={
                    "schedule_id": schedule.id,
                    "name": name,
                    "sequence": seq,
                    "amount_minor": total * percent // 100,
                    "due_at": booking.start_at - timedelta(days=3)
                    if seq == 1
                    else booking.end_at + timedelta(days=1),
                    "release_condition": "contract_signed"
                    if seq == 1
                    else "job_completed",
                    "status": "verified"
                    if PAYMENT_PROOF_STATUSES[idx - 1] == "approved" and seq == 1
                    else "pending",
                },
            )
            if seq == 1:
                txn = ensure(
                    PaymentTransaction,
                    stats,
                    "payment_transaction",
                    public_id=f"DEMO-TXN-{idx:03}",
                    defaults={
                        "milestone_id": milestone.id,
                        "payer_user_id": payer.id,
                        "payee_user_id": payee.id,
                        "provider": "manual_bank" if idx % 2 else "sandbox_card",
                        "provider_reference": f"DEMO-PAY-{idx:03}",
                        "amount_minor": milestone.amount_minor,
                        "currency": "PKR",
                        "direction": "outgoing",
                        "status": "succeeded"
                        if PAYMENT_PROOF_STATUSES[idx - 1] == "approved"
                        else "under_verification"
                        if PAYMENT_PROOF_STATUSES[idx - 1] == "pending"
                        else "failed",
                        "paid_at": NOW - timedelta(days=idx)
                        if PAYMENT_PROOF_STATUSES[idx - 1] == "approved"
                        else None,
                        "idempotency_key": f"demo-payment-{idx:03}",
                    },
                )
                proof = ensure(
                    PaymentProof,
                    stats,
                    "payment_proof",
                    public_id=f"DEMO-PP-{idx:03}",
                    defaults={
                        "transaction_id": txn.id,
                        "file_id": file_asset(f"DEMO-FILE-PAYMENT-{idx:03}").id,
                        "claimed_amount_minor": milestone.amount_minor,
                        "method": txn.provider,
                        "transaction_reference_encrypted": f"demo-payment-proof-token-{idx:03}",
                        "submitted_by": payer.id,
                        "status": PAYMENT_PROOF_STATUSES[idx - 1],
                        "risk_score": 12 + idx,
                        "reviewed_by": admin.id
                        if PAYMENT_PROOF_STATUSES[idx - 1] != "pending"
                        else None,
                        "reviewed_at": NOW - timedelta(days=idx - 1)
                        if PAYMENT_PROOF_STATUSES[idx - 1] != "pending"
                        else None,
                        "rejection_reason": "Demo rejected proof example"
                        if PAYMENT_PROOF_STATUSES[idx - 1] == "rejected"
                        else None,
                    },
                )
                if proof.status == "approved":
                    ensure(
                        Receipt,
                        stats,
                        "receipt",
                        public_id=f"DEMO-RCT-{idx:03}",
                        defaults={
                            "transaction_id": txn.id,
                            "receipt_number": f"DEMO-RCT-NO-{idx:03}",
                            "issued_to_user_id": payer.id,
                            "amount_minor": txn.amount_minor,
                            "currency": "PKR",
                            "status": "issued",
                        },
                    )
                    for entry_no, (entry_user, direction, desc) in enumerate(
                        [
                            (payer, "debit", "Demo payer ledger debit"),
                            (payee, "credit", "Demo payee pending release"),
                        ],
                        start=1,
                    ):
                        ensure(
                            LedgerEntry,
                            stats,
                            "ledger_entry",
                            public_id=f"DEMO-LED-{idx:03}-{entry_no}",
                            defaults={
                                "user_id": entry_user.id,
                                "booking_id": booking.id,
                                "transaction_id": txn.id,
                                "entry_type": "booking_payment",
                                "direction": direction,
                                "amount_minor": txn.amount_minor,
                                "currency": "PKR",
                                "status": "posted",
                                "occurred_at": txn.paid_at or NOW,
                                "description": desc,
                            },
                        )
        ensure(
            BookingFeeSnapshot,
            stats,
            "fee_snapshot",
            booking_id=booking.id,
            defaults={
                "fee_rule_id": fee_rule.id if fee_rule else None,
                "base_minor": total,
                "fee_minor": total * 10 // 100,
                "tax_minor": 0,
                "currency": "PKR",
                "calculation_json": json.dumps(
                    {"seed_batch": SEED_BATCH, "fee_bps": 1000}
                ),
            },
        )
        ensure(
            PayoutAccount,
            stats,
            "payout_account",
            public_id=f"DEMO-PAC-{idx:03}",
            defaults={
                "user_id": payee.id,
                "provider": "manual_bank",
                "account_token_encrypted": f"demo-payout-token-{idx:03}",
                "account_masked": f"PK**{idx:04}",
                "account_name": payee.display_name,
                "status": "verified" if idx % 3 else "pending",
                "is_default": True,
            },
        )


def main() -> None:
    app = create_app()
    stats: dict[str, int] = {}
    with app.app_context():
        admin = user("DEMO-ADMIN-001")
        template = ensure_contract_template(stats, admin)
        bookings = seed_bookings(stats)
        contracts = seed_contracts_and_legal(stats, bookings, template)
        seed_payments(stats, bookings, contracts)
        db.session.commit()
    print(
        json.dumps(
            {"seed_batch": SEED_BATCH, "stats": dict(sorted(stats.items()))}, indent=2
        )
    )


if __name__ == "__main__":
    main()
