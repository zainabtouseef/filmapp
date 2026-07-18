from __future__ import annotations

import uuid
from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.extensions import Base
from app.models.base import EntityMixin
from app.models.bookings import Booking
from app.models.files import FileAsset
from app.models.identity import User, make_public_id
from app.models.projects import Project


class ContractTemplate(EntityMixin, Base):
    __tablename__ = "contract_templates"

    public_id: Mapped[str] = mapped_column(String(40), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(180), nullable=False)
    category: Mapped[str] = mapped_column(String(64), nullable=False)
    jurisdiction: Mapped[str] = mapped_column(String(8), nullable=False, default="PK")
    version_number: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    body_schema_json: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="draft")
    created_by: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
    approved_by: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
    published_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    clauses: Mapped[list[TemplateClause]] = relationship(
        back_populates="template",
        cascade="all, delete-orphan",
        lazy="selectin",
        order_by="TemplateClause.sort_order",
    )


class TemplateClause(EntityMixin, Base):
    __tablename__ = "template_clauses"

    template_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("contract_templates.id", ondelete="CASCADE"),
        nullable=False,
    )
    clause_key: Mapped[str] = mapped_column(String(80), nullable=False)
    title: Mapped[str] = mapped_column(String(180), nullable=False)
    body_text: Mapped[str] = mapped_column(Text, nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=100)
    required: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    editable: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)

    template: Mapped[ContractTemplate] = relationship(back_populates="clauses")


class Contract(EntityMixin, Base):
    __tablename__ = "contracts"

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("CTR"),
    )
    booking_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("bookings.id", ondelete="CASCADE"),
        nullable=False,
    )
    project_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("projects.id", ondelete="CASCADE"),
        nullable=False,
    )
    template_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("contract_templates.id", ondelete="RESTRICT"),
        nullable=False,
    )
    version_number: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    title: Mapped[str] = mapped_column(String(180), nullable=False)
    status: Mapped[str] = mapped_column(
        String(32), nullable=False, default="pending_signature"
    )
    effective_date: Mapped[date | None] = mapped_column(Date)
    value_minor: Mapped[int | None] = mapped_column(Integer)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="PKR")
    rendered_file_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("files.id", ondelete="SET NULL")
    )
    content_snapshot_json: Mapped[str] = mapped_column(Text, nullable=False)
    signature_progress: Mapped[Decimal] = mapped_column(
        Numeric(4, 3), nullable=False, default=0
    )

    booking: Mapped[Booking] = relationship(lazy="joined")
    project: Mapped[Project] = relationship(lazy="joined")
    template: Mapped[ContractTemplate] = relationship(lazy="joined")
    rendered_file: Mapped[FileAsset | None] = relationship(lazy="joined")
    parties: Mapped[list[ContractParty]] = relationship(
        back_populates="contract",
        cascade="all, delete-orphan",
        lazy="selectin",
        order_by="ContractParty.signing_order",
    )
    clauses: Mapped[list[ContractClause]] = relationship(
        back_populates="contract",
        cascade="all, delete-orphan",
        lazy="selectin",
        order_by="ContractClause.sort_order",
    )
    addendums: Mapped[list[ContractAddendum]] = relationship(
        back_populates="contract",
        cascade="all, delete-orphan",
        lazy="selectin",
        order_by="ContractAddendum.created_at.desc()",
    )


class ContractParty(EntityMixin, Base):
    __tablename__ = "contract_parties"

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("PARTY"),
    )
    contract_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("contracts.id", ondelete="CASCADE"),
        nullable=False,
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    organization_id: Mapped[str | None] = mapped_column(String(40))
    party_role: Mapped[str] = mapped_column(String(64), nullable=False)
    signing_order: Mapped[int] = mapped_column(Integer, nullable=False)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="pending")

    contract: Mapped[Contract] = relationship(back_populates="parties")
    user: Mapped[User] = relationship(lazy="joined")
    signatures: Mapped[list[ContractSignature]] = relationship(
        back_populates="party",
        cascade="all, delete-orphan",
        lazy="selectin",
    )


class ContractClause(EntityMixin, Base):
    __tablename__ = "contract_clauses"

    contract_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("contracts.id", ondelete="CASCADE"),
        nullable=False,
    )
    clause_key: Mapped[str] = mapped_column(String(80), nullable=False)
    title: Mapped[str] = mapped_column(String(180), nullable=False)
    body_text: Mapped[str] = mapped_column(Text, nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False)
    highlighted: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    source_template_clause_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("template_clauses.id", ondelete="SET NULL")
    )

    contract: Mapped[Contract] = relationship(back_populates="clauses")
    source_template_clause: Mapped[TemplateClause | None] = relationship(lazy="joined")


class ContractSignature(EntityMixin, Base):
    __tablename__ = "contract_signatures"

    contract_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("contracts.id", ondelete="CASCADE"),
        nullable=False,
    )
    party_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("contract_parties.id", ondelete="CASCADE"),
        nullable=False,
    )
    signer_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    signature_file_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("files.id", ondelete="SET NULL")
    )
    signature_hash: Mapped[str] = mapped_column(String(128), nullable=False)
    signed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    ip_address: Mapped[str | None] = mapped_column(String(64))
    user_agent: Mapped[str | None] = mapped_column(String(512))

    party: Mapped[ContractParty] = relationship(back_populates="signatures")
    signer: Mapped[User] = relationship(foreign_keys=[signer_user_id], lazy="joined")
    signature_file: Mapped[FileAsset | None] = relationship(
        foreign_keys=[signature_file_id],
        lazy="joined",
    )


class ContractAddendum(EntityMixin, Base):
    __tablename__ = "contract_addendums"

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("ADD"),
    )
    contract_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("contracts.id", ondelete="CASCADE"),
        nullable=False,
    )
    requested_by: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    reason: Mapped[str] = mapped_column(Text, nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[str] = mapped_column(
        String(32), nullable=False, default="review_requested"
    )
    reviewer_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
    rendered_file_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("files.id", ondelete="SET NULL")
    )

    contract: Mapped[Contract] = relationship(back_populates="addendums")
    requester: Mapped[User] = relationship(foreign_keys=[requested_by], lazy="joined")


class LegalReviewRequest(EntityMixin, Base):
    __tablename__ = "legal_review_requests"

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("LGR"),
    )
    contract_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("contracts.id", ondelete="CASCADE")
    )
    template_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("contract_templates.id", ondelete="SET NULL")
    )
    addendum_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("contract_addendums.id", ondelete="SET NULL")
    )
    requested_by: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    assigned_legal_user_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
    contract_type: Mapped[str] = mapped_column(String(64), nullable=False)
    risk: Mapped[str] = mapped_column(String(32), nullable=False, default="medium")
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="requested")
    sla_due_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    decision_notes: Mapped[str | None] = mapped_column(Text)

    contract: Mapped[Contract | None] = relationship(lazy="joined")
    template: Mapped[ContractTemplate | None] = relationship(lazy="joined")
    addendum: Mapped[ContractAddendum | None] = relationship(lazy="joined")
    requester: Mapped[User] = relationship(foreign_keys=[requested_by], lazy="joined")
    assigned_legal: Mapped[User | None] = relationship(
        foreign_keys=[assigned_legal_user_id],
        lazy="joined",
    )
    risks: Mapped[list[LegalClauseRisk]] = relationship(
        back_populates="review_request",
        cascade="all, delete-orphan",
        lazy="selectin",
    )


class LegalClauseRisk(EntityMixin, Base):
    __tablename__ = "legal_clause_risks"

    review_request_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("legal_review_requests.id", ondelete="CASCADE"),
        nullable=False,
    )
    contract_clause_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("contract_clauses.id", ondelete="SET NULL")
    )
    risk_level: Mapped[str] = mapped_column(String(32), nullable=False)
    issue: Mapped[str] = mapped_column(Text, nullable=False)
    recommendation: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="open")

    review_request: Mapped[LegalReviewRequest] = relationship(back_populates="risks")
    contract_clause: Mapped[ContractClause | None] = relationship(lazy="joined")


class LegalBillingRecord(EntityMixin, Base):
    __tablename__ = "legal_billing_records"

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("LGB"),
    )
    legal_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    matter_type: Mapped[str] = mapped_column(String(64), nullable=False)
    matter_id: Mapped[str] = mapped_column(String(40), nullable=False)
    client_user_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
    minutes: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    amount_minor: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="PKR")
    invoice_number: Mapped[str | None] = mapped_column(String(64))
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="draft")
    notes: Mapped[str | None] = mapped_column(Text)
