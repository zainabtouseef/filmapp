from __future__ import annotations

import uuid
from datetime import date, datetime

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.extensions import Base
from app.models.base import EntityMixin
from app.models.files import FileAsset
from app.models.identity import User, make_public_id
from app.models.marketplace import City


class Project(EntityMixin, Base):
    __tablename__ = "projects"

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("PRJ"),
    )
    owner_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    organization_id: Mapped[str | None] = mapped_column(String(40))
    title: Mapped[str] = mapped_column(String(180), nullable=False)
    project_type: Mapped[str] = mapped_column(String(64), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    city_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("cities.id", ondelete="SET NULL")
    )
    start_date: Mapped[date | None] = mapped_column(Date)
    end_date: Mapped[date | None] = mapped_column(Date)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="draft")
    estimated_budget_minor: Mapped[int | None] = mapped_column(Integer)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="PKR")
    visibility: Mapped[str] = mapped_column(
        String(32), nullable=False, default="private"
    )
    progress_percent: Mapped[int] = mapped_column(Integer, nullable=False, default=0)

    owner: Mapped[User] = relationship(lazy="joined")
    city: Mapped[City | None] = relationship(lazy="joined")
    members: Mapped[list[ProjectMember]] = relationship(
        back_populates="project",
        cascade="all, delete-orphan",
        lazy="selectin",
    )
    requirements: Mapped[list[ProjectRequirement]] = relationship(
        back_populates="project",
        cascade="all, delete-orphan",
        lazy="selectin",
        order_by="ProjectRequirement.created_at.desc()",
    )
    files: Mapped[list[ProjectFile]] = relationship(
        back_populates="project",
        cascade="all, delete-orphan",
        lazy="selectin",
        order_by="ProjectFile.sort_order",
    )
    room_items: Mapped[list[ProjectRoomItem]] = relationship(
        back_populates="project",
        cascade="all, delete-orphan",
        lazy="selectin",
        order_by="ProjectRoomItem.created_at.desc()",
    )


class ProjectMember(EntityMixin, Base):
    __tablename__ = "project_members"
    __table_args__ = (
        UniqueConstraint("project_id", "user_id", name="uq_project_member_user"),
    )

    project_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("projects.id", ondelete="CASCADE"),
        nullable=False,
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    role_label: Mapped[str] = mapped_column(String(120), nullable=False)
    permissions_json: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="active")

    project: Mapped[Project] = relationship(back_populates="members")
    user: Mapped[User] = relationship(lazy="joined")


class Skill(EntityMixin, Base):
    __tablename__ = "skills"

    public_id: Mapped[str] = mapped_column(String(40), unique=True, nullable=False)
    category: Mapped[str] = mapped_column(String(64), nullable=False)
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)


class ProjectRequirement(EntityMixin, Base):
    __tablename__ = "project_requirements"

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("REQ"),
    )
    project_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("projects.id", ondelete="CASCADE"),
        nullable=False,
    )
    category: Mapped[str] = mapped_column(String(64), nullable=False)
    title: Mapped[str] = mapped_column(String(180), nullable=False)
    summary: Mapped[str | None] = mapped_column(Text)
    budget_min_minor: Mapped[int | None] = mapped_column(Integer)
    budget_max_minor: Mapped[int | None] = mapped_column(Integer)
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="PKR")
    start_date: Mapped[date | None] = mapped_column(Date)
    end_date: Mapped[date | None] = mapped_column(Date)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="open")
    candidate_count_cache: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0
    )

    project: Mapped[Project] = relationship(back_populates="requirements")
    skills: Mapped[list[RequirementSkill]] = relationship(
        back_populates="requirement",
        cascade="all, delete-orphan",
        lazy="selectin",
    )


class RequirementSkill(EntityMixin, Base):
    __tablename__ = "requirement_skills"
    __table_args__ = (
        UniqueConstraint("requirement_id", "skill_id", name="uq_requirement_skill"),
    )

    requirement_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("project_requirements.id", ondelete="CASCADE"),
        nullable=False,
    )
    skill_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("skills.id", ondelete="RESTRICT"),
        nullable=False,
    )
    required: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    minimum_level: Mapped[str | None] = mapped_column(String(32))

    requirement: Mapped[ProjectRequirement] = relationship(back_populates="skills")
    skill: Mapped[Skill] = relationship(lazy="joined")


class ProjectFile(EntityMixin, Base):
    __tablename__ = "project_files"
    __table_args__ = (
        UniqueConstraint("project_id", "file_id", name="uq_project_file_asset"),
    )

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("PFILE"),
    )
    project_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("projects.id", ondelete="CASCADE"),
        nullable=False,
    )
    file_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("files.id", ondelete="CASCADE"),
        nullable=False,
    )
    folder: Mapped[str] = mapped_column(String(64), nullable=False, default="briefs")
    label: Mapped[str] = mapped_column(String(180), nullable=False)
    uploaded_by: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    visibility: Mapped[str] = mapped_column(
        String(32), nullable=False, default="project_members"
    )
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=100)

    project: Mapped[Project] = relationship(back_populates="files")
    file: Mapped[FileAsset] = relationship(lazy="joined")
    uploader: Mapped[User | None] = relationship(lazy="joined")


class ProjectRoomItem(EntityMixin, Base):
    __tablename__ = "project_room_items"

    public_id: Mapped[str] = mapped_column(
        String(40),
        unique=True,
        nullable=False,
        default=lambda: make_public_id("ROOM"),
    )
    project_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("projects.id", ondelete="CASCADE"),
        nullable=False,
    )
    item_type: Mapped[str] = mapped_column(String(32), nullable=False)
    title: Mapped[str] = mapped_column(String(180), nullable=False)
    body: Mapped[str | None] = mapped_column(Text)
    linked_entity_type: Mapped[str | None] = mapped_column(String(64))
    linked_entity_id: Mapped[str | None] = mapped_column(String(40))
    created_by: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    pinned_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    project: Mapped[Project] = relationship(back_populates="room_items")
    creator: Mapped[User | None] = relationship(lazy="joined")
