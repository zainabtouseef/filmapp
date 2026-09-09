from __future__ import annotations

import json
import sys
from datetime import UTC, date, datetime, timedelta
from pathlib import Path
from typing import Any

from sqlalchemy import select

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app import create_app
from app.extensions import db
from app.models import (
    AgencyCommission,
    Announcement,
    AuditionCandidate,
    AuditionRequest,
    BlockedUser,
    Booking,
    BrandApplication,
    BrandOpportunity,
    BrandProfile,
    BrandTerm,
    CampaignDeliverable,
    CampaignMetric,
    CastingAgency,
    DamageClaim,
    DamageClaimEvidence,
    Dispute,
    DisputeEvent,
    DisputeEvidence,
    DistributionPartnerProfile,
    DistributionProject,
    DistributionReport,
    EquipmentInspection,
    EquipmentInspectionItem,
    EquipmentItem,
    EquipmentProviderProfile,
    ExportJob,
    FileAsset,
    Incident,
    InsuranceClaim,
    InsuranceClaimEvidence,
    InsurancePartnerProfile,
    InsurancePolicy,
    LocationInspection,
    LocationInspectionItem,
    LocationProperty,
    LocationSpace,
    ModerationCase,
    ModerationEvent,
    Notification,
    NotificationDelivery,
    PushDevice,
    ReleaseHandoverItem,
    ReleaseWindow,
    Report,
    Review,
    ReviewDimension,
    ReviewRequest,
    SelectionNote,
    SelfTape,
    SupportMessage,
    SupportTicket,
    TalentProfile,
    User,
)


SEED_BATCH = "cineconnect-demo-2026-07-18"
NOW = datetime.now(UTC)
BASE = date(2026, 10, 1)


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

BRAND_NAMES = [
    "Nova Cola",
    "Zest Telecom",
    "Orion Bank",
    "Naya Wear",
    "TravelPK",
    "ByteCafe",
    "Indie Fund",
    "Masala House",
    "InsurePro",
    "StreamSphere",
]


def one(model: type[Any], **where: Any) -> Any | None:
    return db.session.execute(select(model).filter_by(**where)).scalar_one_or_none()


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


def seed_operations_and_insurance(stats: dict[str, int]) -> None:
    for idx in range(1, 11):
        booking = required(Booking, public_id=f"DEMO-BKG-{idx:03}")
        project = booking.project
        producer = user(f"DEMO-DP-{idx:03}")
        talent = user(f"DEMO-AT-{idx:03}")
        location_owner = user(f"DEMO-LO-{idx:03}")
        insurance_user = user(f"DEMO-IN-{idx:03}")
        loc = required(LocationProperty, public_id=f"DEMO-LOC-{idx:03}")
        space = (
            db.session.execute(
                select(LocationSpace).where(LocationSpace.property_id == loc.id)
            )
            .scalars()
            .first()
        )
        inspection = ensure(
            LocationInspection,
            stats,
            "location_inspection",
            public_id=f"DEMO-LIN-{idx:03}",
            defaults={
                "booking_id": booking.id,
                "property_id": loc.id,
                "inspection_type": "check_in",
                "status": "confirmed" if idx % 2 else "in_progress",
                "confirmed_by_owner_at": NOW - timedelta(days=idx) if idx % 2 else None,
                "confirmed_by_renter_at": NOW - timedelta(days=idx)
                if idx % 2
                else None,
                "meter_reading": f"MTR-{idx:03}",
                "notes": f"Demo check-in inspection for {PROJECT_TITLES[idx - 1]}.",
            },
        )
        ensure(
            LocationInspectionItem,
            stats,
            "location_inspection_item",
            inspection_id=inspection.id,
            area_label="Main shoot area",
            defaults={
                "space_id": space.id if space else None,
                "before_file_id": file_asset(f"DEMO-FILE-LOCATION-{idx:03}").id,
                "after_file_id": file_asset(f"DEMO-FILE-LOCATION-{idx + 10:03}").id,
                "note": "Seeded inspection checklist item",
                "stage": "captured",
                "issue_severity": "minor" if idx in {3, 9} else "none",
            },
        )
        if idx <= 5:
            claim = ensure(
                DamageClaim,
                stats,
                "damage_claim",
                public_id=f"DEMO-DCL-{idx:03}",
                defaults={
                    "booking_id": booking.id,
                    "claimant_user_id": location_owner.id,
                    "respondent_user_id": producer.id,
                    "inspection_id": inspection.id,
                    "description": "Demo location damage/deposit claim.",
                    "claimed_minor": (25_000 + idx * 5_000) * 100,
                    "currency": "PKR",
                    "status": "submitted" if idx % 2 else "under_review",
                    "submitted_at": NOW - timedelta(days=idx),
                },
            )
            ensure(
                DamageClaimEvidence,
                stats,
                "damage_claim_evidence",
                claim_id=claim.id,
                evidence_type="photo",
                defaults={
                    "file_id": file_asset(f"DEMO-FILE-LOCATION-{idx + 15:03}").id,
                    "caption": "Seeded damage evidence photo",
                    "captured_at": NOW - timedelta(days=idx),
                },
            )

        epp = required(EquipmentProviderProfile, public_id=f"DEMO-EPP-{idx:03}")
        eq_inspection = ensure(
            EquipmentInspection,
            stats,
            "equipment_inspection",
            public_id=f"DEMO-EIN-{idx:03}",
            defaults={
                "booking_id": booking.id,
                "provider_profile_id": epp.id,
                "inspection_type": "handover",
                "status": "confirmed" if idx % 2 else "in_progress",
                "handover_at": NOW - timedelta(days=idx),
                "return_at": NOW + timedelta(days=idx),
                "signed_by_provider": idx % 2 == 1,
                "signed_by_renter": idx % 2 == 1,
            },
        )
        item = (
            db.session.execute(
                select(EquipmentItem).where(EquipmentItem.provider_profile_id == epp.id)
            )
            .scalars()
            .first()
        )
        if item:
            ensure(
                EquipmentInspectionItem,
                stats,
                "equipment_inspection_item",
                inspection_id=eq_inspection.id,
                equipment_item_id=item.id,
                defaults={
                    "before_file_id": file_asset(f"DEMO-FILE-EQUIPMENT-{idx:03}").id,
                    "after_file_id": file_asset(
                        f"DEMO-FILE-EQUIPMENT-{idx + 10:03}"
                    ).id,
                    "accessories_json": json.dumps(["battery", "charger", "case"]),
                    "stage": "captured",
                    "note": "Seeded equipment handover item",
                },
            )

        safety = ensure(
            __import__("app.models", fromlist=["SafetyCheck"]).SafetyCheck,
            stats,
            "safety_check",
            public_id=f"DEMO-SFC-{idx:03}",
            defaults={
                "project_id": project.id,
                "booking_id": booking.id,
                "location_property_id": loc.id,
                "responsible_user_id": producer.id,
                "due_at": NOW + timedelta(days=idx),
                "risk_level": "high" if idx in {4, 9} else "medium",
                "status": "in_review" if idx % 3 else "approved",
            },
        )
        SafetyCheckItem = __import__(
            "app.models", fromlist=["SafetyCheckItem"]
        ).SafetyCheckItem
        for item_idx, label in enumerate(
            ["Fire exits verified", "First-aid kit on set"], start=1
        ):
            ensure(
                SafetyCheckItem,
                stats,
                "safety_check_item",
                safety_check_id=safety.id,
                label=label,
                defaults={
                    "detail": "Seeded safety checklist row",
                    "mandatory": True,
                    "completed_at": NOW if item_idx == 1 and idx % 2 else None,
                    "completed_by": producer.id if item_idx == 1 and idx % 2 else None,
                },
            )
        ensure(
            Incident,
            stats,
            "incident",
            public_id=f"DEMO-INC-{idx:03}",
            defaults={
                "project_id": project.id,
                "booking_id": booking.id,
                "reported_by": producer.id if idx % 2 else talent.id,
                "title": f"{PROJECT_TITLES[idx - 1]} demo incident",
                "severity": "high" if idx in {4, 9} else "medium",
                "occurred_at": NOW - timedelta(days=idx),
                "parties": "Producer, talent, safety marshal",
                "description": "Seeded incident report for admin/insurance demos.",
                "corrective_action": "Safety briefing repeated and area isolated.",
                "status": "open" if idx in {4, 9} else "resolved",
            },
        )
        ensure(
            __import__("app.models", fromlist=["SafetyCheckIn"]).SafetyCheckIn,
            stats,
            "safety_check_in",
            public_id=f"DEMO-SCI-{idx:03}",
            defaults={
                "user_id": talent.id,
                "booking_id": booking.id,
                "scheduled_at": booking.start_at,
                "checked_in_at": booking.start_at + timedelta(minutes=15)
                if idx % 3
                else None,
                "latitude_token": f"demo-lat-{idx:03}",
                "longitude_token": f"demo-lng-{idx:03}",
                "status": "checked_in" if idx % 3 else "missed",
                "escalated_at": NOW - timedelta(days=1) if idx % 3 == 0 else None,
            },
        )

        insp = ensure(
            InsurancePartnerProfile,
            stats,
            "insurance_profile",
            public_id=f"DEMO-INSP-{idx:03}",
            defaults={
                "user_id": insurance_user.id,
                "name": f"Demo Insurance {idx:02}",
                "license_number_token": f"demo-license-{idx:03}",
                "coverage_regions": "Pakistan,GCC",
                "status": "approved",
            },
        )
        policy = ensure(
            InsurancePolicy,
            stats,
            "insurance_policy",
            public_id=f"DEMO-POL-{idx:03}",
            defaults={
                "project_id": project.id,
                "booking_id": booking.id,
                "provider_profile_id": insp.id,
                "insured_user_id": producer.id,
                "coverage_summary": f"General liability and equipment coverage for {PROJECT_TITLES[idx - 1]}.",
                "valid_from": BASE,
                "valid_to": BASE + timedelta(days=90),
                "document_file_id": file_asset(f"DEMO-FILE-INSURANCE-{idx:03}").id,
                "risk_level": "high" if idx in {4, 9} else "low",
                "status": "active",
            },
        )
        iclaim = ensure(
            InsuranceClaim,
            stats,
            "insurance_claim",
            public_id=f"DEMO-ICL-{idx:03}",
            defaults={
                "policy_id": policy.id,
                "booking_id": booking.id,
                "claimant_user_id": producer.id,
                "title": f"{PROJECT_TITLES[idx - 1]} insurance claim",
                "item_or_room": "Main shoot area",
                "adjuster_user_id": insurance_user.id,
                "estimate_minor": (40_000 + idx * 7_500) * 100,
                "currency": "PKR",
                "status": "submitted" if idx % 2 else "approved",
                "due_at": NOW + timedelta(days=idx + 5),
            },
        )
        ensure(
            InsuranceClaimEvidence,
            stats,
            "insurance_claim_evidence",
            claim_id=iclaim.id,
            evidence_type="incident_photo",
            defaults={
                "file_id": file_asset(f"DEMO-FILE-INSURANCE-{idx + 10:03}").id,
                "mandatory": True,
                "caption": "Seeded claim evidence",
            },
        )


def seed_specialist(stats: dict[str, int]) -> None:
    for idx in range(1, 11):
        booking = required(Booking, public_id=f"DEMO-BKG-{idx:03}")
        project = booking.project
        producer = user(f"DEMO-DP-{idx:03}")
        talent = required(TalentProfile, public_id=f"DEMO-TAL-{idx:03}")
        agency = required(CastingAgency, public_id=f"DEMO-AGY-{idx:03}")
        audition = ensure(
            AuditionRequest,
            stats,
            "audition_request",
            public_id=f"DEMO-AUD-{idx:03}",
            defaults={
                "agency_id": agency.id,
                "project_id": project.id,
                "requirement_id": booking.requirement_id,
                "requested_by": producer.id,
                "role_title": f"{PROJECT_TITLES[idx - 1]} supporting role",
                "due_at": NOW + timedelta(days=idx),
                "budget_minor": (80_000 + idx * 10_000) * 100,
                "currency": "PKR",
                "status": "shortlisting" if idx % 2 else "requested",
            },
        )
        for rank in range(1, 4):
            candidate_talent = required(
                TalentProfile, public_id=f"DEMO-TAL-{((idx + rank - 2) % 10) + 1:03}"
            )
            cand = ensure(
                AuditionCandidate,
                stats,
                "audition_candidate",
                public_id=f"DEMO-AUDC-{idx:03}-{rank}",
                defaults={
                    "audition_request_id": audition.id,
                    "talent_profile_id": candidate_talent.id,
                    "status": "shortlisted" if rank == 1 else "submitted",
                    "rank": rank,
                    "agency_note": "Seeded agency shortlist note",
                    "director_note": "Seeded director note",
                    "score": 90 - rank * 5,
                },
            )
            if rank <= 2:
                ensure(
                    SelfTape,
                    stats,
                    "self_tape",
                    public_id=f"DEMO-TAPE-{idx:03}-{rank}",
                    defaults={
                        "audition_candidate_id": cand.id,
                        "file_id": file_asset(f"DEMO-FILE-SHOWREEL-{rank:03}").id,
                        "thumbnail_file_id": file_asset(
                            f"DEMO-FILE-PORTFOLIO-{idx:03}"
                        ).id,
                        "duration_seconds": 90 + idx,
                        "transcript": "Seeded self-tape transcript.",
                        "status": "submitted",
                        "submitted_at": NOW - timedelta(days=rank),
                    },
                )
                ensure(
                    SelectionNote,
                    stats,
                    "selection_note",
                    audition_candidate_id=cand.id,
                    author_user_id=producer.id,
                    defaults={
                        "note": "Strong fit for demo shortlist.",
                        "score": 88 - rank,
                        "visibility": "agency_and_director",
                    },
                )
        ensure(
            AgencyCommission,
            stats,
            "agency_commission",
            public_id=f"DEMO-COM-{idx:03}",
            defaults={
                "agency_id": agency.id,
                "booking_id": booking.id,
                "talent_profile_id": talent.id,
                "gross_minor": booking.agreed_amount_minor or 200_000 * 100,
                "commission_bps": agency.commission_bps,
                "commission_minor": (
                    (booking.agreed_amount_minor or 200_000 * 100)
                    * agency.commission_bps
                )
                // 10000,
                "currency": "PKR",
                "due_at": NOW + timedelta(days=idx),
                "status": "paid" if idx % 3 == 0 else "pending",
            },
        )

        brand = required(BrandProfile, public_id=f"DEMO-BRD-{idx:03}")
        opp = ensure(
            BrandOpportunity,
            stats,
            "brand_opportunity",
            public_id=f"DEMO-BOP-{idx:03}",
            defaults={
                "brand_profile_id": brand.id,
                "project_id": project.id,
                "title": f"{BRAND_NAMES[idx - 1]} campaign for {PROJECT_TITLES[idx - 1]}",
                "category": "brand_integration",
                "budget_minor": (300_000 + idx * 25_000) * 100,
                "currency": "PKR",
                "usage_summary": "Seeded social/video/demo campaign usage.",
                "eligibility": "Approved talent profiles only.",
                "deliverables": "Two reels, one BTS post, usage report.",
                "application_due_at": NOW + timedelta(days=idx + 3),
                "status": "published",
                "cover_file_id": file_asset(f"DEMO-FILE-BRAND-{idx:03}").id,
            },
        )
        first_app: BrandApplication | None = None
        for app_idx in range(1, 4):
            applicant = user(f"DEMO-AT-{((idx + app_idx - 2) % 10) + 1:03}")
            applicant_talent = required(
                TalentProfile, public_id=f"DEMO-TAL-{((idx + app_idx - 2) % 10) + 1:03}"
            )
            app = ensure(
                BrandApplication,
                stats,
                "brand_application",
                public_id=f"DEMO-BAP-{idx:03}-{app_idx}",
                defaults={
                    "opportunity_id": opp.id,
                    "applicant_user_id": applicant.id,
                    "talent_profile_id": applicant_talent.id,
                    "proposal": "Seeded campaign application proposal.",
                    "audience_metrics_json": json.dumps(
                        {"followers": 10000 + idx * 1000, "engagement": 4.2}
                    ),
                    "budget_ask_minor": (120_000 + app_idx * 15_000) * 100,
                    "currency": "PKR",
                    "status": "approved" if app_idx == 1 else "submitted",
                },
            )
            first_app = first_app or app
        if first_app:
            ensure(
                BrandTerm,
                stats,
                "brand_term",
                public_id=f"DEMO-BTM-{idx:03}",
                defaults={
                    "application_id": first_app.id,
                    "scope": "Seeded social + BTS usage terms.",
                    "exclusivity": "non-exclusive",
                    "approval_rights": "Brand gets one revision round.",
                    "payment_schedule_json": json.dumps(
                        {"advance": 50, "delivery": 50}
                    ),
                    "status": "accepted" if idx % 2 else "draft",
                    "version": 1,
                },
            )
        for del_idx in range(1, 3):
            deliverable = ensure(
                CampaignDeliverable,
                stats,
                "campaign_deliverable",
                public_id=f"DEMO-DEL-{idx:03}-{del_idx}",
                defaults={
                    "opportunity_id": opp.id,
                    "booking_id": booking.id,
                    "owner_user_id": user(f"DEMO-AT-{idx:03}").id,
                    "label": f"Campaign proof {del_idx}",
                    "due_at": NOW + timedelta(days=del_idx + idx),
                    "proof_file_id": file_asset(
                        f"DEMO-FILE-BRAND-{idx + del_idx:03}"
                    ).id,
                    "status": "approved" if del_idx == 1 and idx % 2 else "pending",
                    "approved_at": NOW if del_idx == 1 and idx % 2 else None,
                },
            )
            ensure(
                CampaignMetric,
                stats,
                "campaign_metric",
                deliverable_id=deliverable.id,
                platform="instagram",
                defaults={
                    "captured_at": NOW - timedelta(days=del_idx),
                    "impressions": 50000 + idx * 2500,
                    "reach": 30000 + idx * 1200,
                    "engagements": 2500 + idx * 100,
                    "clicks": 600 + idx * 30,
                    "source": "manual_verified",
                    "raw_json": json.dumps({"seed_batch": SEED_BATCH}),
                },
            )

        partner = required(DistributionPartnerProfile, public_id=f"DEMO-DSTP-{idx:03}")
        dproj = required(DistributionProject, public_id=f"DEMO-DPR-{idx:03}")
        for item_idx, label in enumerate(
            ["Final master file", "Poster key art"], start=1
        ):
            ensure(
                ReleaseHandoverItem,
                stats,
                "release_handover",
                distribution_project_id=dproj.id,
                label=label,
                defaults={
                    "detail": "Seeded release handover row",
                    "mandatory": True,
                    "file_id": file_asset(f"DEMO-FILE-DISTRIBUTION-{idx:03}").id,
                    "status": "approved" if item_idx == 1 else "missing",
                    "approved_at": NOW if item_idx == 1 else None,
                },
            )
            ensure(
                ReleaseWindow,
                stats,
                "release_window",
                public_id=f"DEMO-RW-{idx:03}-{item_idx}",
                defaults={
                    "distribution_project_id": dproj.id,
                    "channel": "OTT" if item_idx == 1 else "Theatrical",
                    "territory": "Pakistan" if item_idx == 1 else "GCC",
                    "starts_on": BASE + timedelta(days=idx * 3),
                    "ends_on": BASE + timedelta(days=idx * 3 + 30),
                    "exclusivity": "exclusive" if item_idx == 1 else "non_exclusive",
                    "status": "planned",
                },
            )
        ensure(
            DistributionReport,
            stats,
            "distribution_report",
            public_id=f"DEMO-DRP-{idx:03}",
            defaults={
                "distribution_project_id": dproj.id,
                "partner_profile_id": partner.id,
                "territory": "Pakistan",
                "channel": "OTT",
                "period_start": BASE,
                "period_end": BASE + timedelta(days=30),
                "audience_count": 100000 + idx * 10000,
                "revenue_minor": (250_000 + idx * 25_000) * 100,
                "currency": "PKR",
                "source_file_id": file_asset(f"DEMO-FILE-DISTRIBUTION-{idx:03}").id,
                "status": "submitted",
            },
        )


def seed_trust_support_notifications(stats: dict[str, int]) -> None:
    admin = user("DEMO-ADMIN-001")
    for idx in range(1, 11):
        booking = required(Booking, public_id=f"DEMO-BKG-{idx:03}")
        producer = user(f"DEMO-DP-{idx:03}")
        talent = user(f"DEMO-AT-{idx:03}")
        review = ensure(
            Review,
            stats,
            "review",
            public_id=f"DEMO-REV-{idx:03}",
            defaults={
                "booking_id": booking.id,
                "reviewer_user_id": producer.id,
                "reviewee_user_id": talent.id,
                "rating": 4 + (idx % 2),
                "text": "Seeded published review for reputation demos.",
                "status": "published",
                "published_at": NOW - timedelta(days=idx),
            },
        )
        for dimension in ["professionalism", "communication"]:
            ensure(
                ReviewDimension,
                stats,
                "review_dimension",
                review_id=review.id,
                dimension=dimension,
                defaults={"score": review.rating},
            )
        ensure(
            ReviewRequest,
            stats,
            "review_request",
            public_id=f"DEMO-RVR-{idx:03}",
            defaults={
                "booking_id": booking.id,
                "requested_by": talent.id,
                "requested_from": producer.id,
                "status": "completed" if idx % 2 else "sent",
                "sent_at": NOW - timedelta(days=idx),
                "completed_review_id": review.id if idx % 2 else None,
            },
        )
        ensure(
            BlockedUser,
            stats,
            "blocked_user",
            blocker_user_id=talent.id,
            blocked_user_id=producer.id,
            defaults={"reason": "Seeded safety/block demo row"},
        )
        report = ensure(
            Report,
            stats,
            "report",
            public_id=f"DEMO-RPT-{idx:03}",
            defaults={
                "reporter_user_id": talent.id,
                "reported_user_id": producer.id,
                "entity_type": "booking",
                "entity_id": booking.public_id,
                "reason": "safety_concern",
                "description": "Seeded report for moderation demo.",
                "status": "open" if idx % 3 else "resolved",
                "assigned_admin_id": admin.id,
                "resolution": "Demo resolution" if idx % 3 == 0 else None,
            },
        )
        mod = ensure(
            ModerationCase,
            stats,
            "moderation_case",
            public_id=f"DEMO-MODC-{idx:03}",
            defaults={
                "entity_type": report.entity_type,
                "entity_id": report.entity_id,
                "source": "report",
                "risk_level": "high" if idx in {4, 9} else "medium",
                "status": "queued"
                if idx <= 5
                else "resolved"
                if idx <= 8
                else "escalated",
                "assigned_admin_id": admin.id,
                "decision": "approved" if idx in {6, 7, 8} else None,
                "decision_reason": "Seeded moderation decision"
                if idx in {6, 7, 8}
                else None,
            },
        )
        ensure(
            ModerationEvent,
            stats,
            "moderation_event",
            case_id=mod.id,
            action="created",
            defaults={
                "actor_user_id": admin.id,
                "from_status": None,
                "to_status": mod.status,
                "notes": "Seeded moderation event",
            },
        )
        dispute = ensure(
            Dispute,
            stats,
            "dispute",
            public_id=f"DEMO-DSP-{idx:03}",
            defaults={
                "booking_id": booking.id,
                "opened_by": producer.id,
                "respondent_user_id": talent.id,
                "type": "payment" if idx % 2 else "schedule",
                "description": "Seeded dispute for admin/support demos.",
                "value_minor": (50_000 + idx * 5_000) * 100,
                "currency": "PKR",
                "severity": "high" if idx in {4, 9} else "medium",
                "status": "open"
                if idx <= 4
                else "decided"
                if idx <= 8
                else "awaiting_evidence",
                "assigned_admin_id": admin.id,
                "resolved_at": NOW if idx in {5, 6, 7, 8} else None,
            },
        )
        ensure(
            DisputeEvidence,
            stats,
            "dispute_evidence",
            dispute_id=dispute.id,
            submitted_by=producer.id,
            evidence_type="payment_proof",
            defaults={
                "file_id": file_asset(f"DEMO-FILE-PAYMENT-{idx:03}").id,
                "description": "Seeded dispute evidence",
            },
        )
        ensure(
            DisputeEvent,
            stats,
            "dispute_event",
            dispute_id=dispute.id,
            event_type="opened",
            defaults={
                "actor_user_id": producer.id,
                "note": "Seeded dispute opened event",
                "metadata_json": json.dumps({"seed_batch": SEED_BATCH}),
            },
        )
        ticket = ensure(
            SupportTicket,
            stats,
            "support_ticket",
            public_id=f"DEMO-TKT-{idx:03}",
            defaults={
                "user_id": producer.id,
                "booking_id": booking.id,
                "category": "booking",
                "priority": "high" if idx in {4, 9} else "normal",
                "subject": f"Support for {PROJECT_TITLES[idx - 1]}",
                "status": "open"
                if idx <= 5
                else "waiting_user"
                if idx <= 8
                else "closed",
                "assigned_admin_id": admin.id,
                "last_message_at": NOW - timedelta(hours=idx),
            },
        )
        for msg_idx, sender in enumerate([producer, admin], start=1):
            ensure(
                SupportMessage,
                stats,
                "support_message",
                ticket_id=ticket.id,
                sender_user_id=sender.id,
                body=f"Seeded support message {msg_idx} for {PROJECT_TITLES[idx - 1]}.",
                defaults={
                    "file_id": file_asset(f"DEMO-FILE-PROJECT-{idx:03}").id
                    if msg_idx == 1
                    else None,
                    "internal_note": False,
                },
            )
        for ntf_idx, target in enumerate([producer, talent, admin], start=1):
            ntf = ensure(
                Notification,
                stats,
                "notification",
                public_id=f"DEMO-NTF-{idx:03}-{ntf_idx}",
                defaults={
                    "user_id": target.id,
                    "category": ["booking", "payment", "support"][ntf_idx - 1],
                    "title": f"Demo notification {ntf_idx}",
                    "body": f"{PROJECT_TITLES[idx - 1]} has a seeded update.",
                    "route_name": "/notifications",
                    "route_params_json": json.dumps({"booking_id": booking.public_id}),
                    "read_at": NOW - timedelta(days=1) if ntf_idx == 1 else None,
                },
            )
            ensure(
                NotificationDelivery,
                stats,
                "notification_delivery",
                notification_id=ntf.id,
                channel="in_app",
                defaults={
                    "provider": "sandbox",
                    "provider_reference": ntf.public_id,
                    "status": "sent",
                    "sent_at": NOW,
                },
            )
        if idx <= 5:
            ensure(
                PushDevice,
                stats,
                "push_device",
                user_id=talent.id,
                device_id=f"demo-device-{idx:03}",
                defaults={
                    "platform": "android",
                    "token_reference": f"firebase-demo-token-{idx:03}",
                    "enabled": True,
                    "last_seen_at": NOW,
                },
            )
    for idx, status in enumerate(["draft", "published", "scheduled"], start=1):
        ensure(
            Announcement,
            stats,
            "announcement",
            public_id=f"DEMO-ANN-{idx:03}",
            defaults={
                "title": f"Demo platform announcement {idx}",
                "body": "Seeded broadcast announcement for Super Admin demo.",
                "audience_json": json.dumps(
                    {"roles": ["director_producer", "actor_talent"]}
                ),
                "channel_json": json.dumps({"in_app": True, "push": True}),
                "status": status,
                "scheduled_at": NOW + timedelta(days=2)
                if status == "scheduled"
                else None,
                "published_at": NOW - timedelta(days=1)
                if status == "published"
                else None,
                "created_by": admin.id,
            },
        )
    for idx, export_type in enumerate(
        ["bookings", "ledger", "admin_disputes"], start=1
    ):
        ensure(
            ExportJob,
            stats,
            "export_job",
            public_id=f"DEMO-EXP-{idx:03}",
            defaults={
                "requested_by": admin.id,
                "export_type": export_type,
                "filters_json": json.dumps({"seed_batch": SEED_BATCH}),
                "status": "completed",
                "row_count": 10,
                "csv_content": "id,name,status\nDEMO,Seeded,completed\n",
                "requested_at": NOW - timedelta(hours=idx),
                "completed_at": NOW - timedelta(hours=idx, minutes=-1),
            },
        )


def main() -> None:
    app = create_app()
    stats: dict[str, int] = {}
    with app.app_context():
        seed_operations_and_insurance(stats)
        seed_specialist(stats)
        seed_trust_support_notifications(stats)
        db.session.commit()
    print(
        json.dumps(
            {"seed_batch": SEED_BATCH, "stats": dict(sorted(stats.items()))}, indent=2
        )
    )


if __name__ == "__main__":
    main()
