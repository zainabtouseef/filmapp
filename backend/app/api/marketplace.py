from __future__ import annotations

import json
from decimal import Decimal
from typing import Any

from flask import Blueprint, Response, jsonify, request
from flask.typing import ResponseReturnValue
from sqlalchemy import func, or_, select

from app.api.auth import _current_user, _json_body
from app.errors import APIError
from app.extensions import db
from app.models.base import utc_now
from app.models.files import FileAsset
from app.models.identity import Role
from app.models.kyc import KycSubmission
from app.models.marketplace import (
    City,
    ListingMedia,
    MarketplaceListing,
    ModelProfile,
    PortfolioItem,
    SavedSearch,
    Shortlist,
    ShortlistItem,
    TalentLanguage,
    TalentProfile,
    UserProfile,
)
from app.models.operations import LocationProperty
from app.responses import success
from app.services.local_storage import public_url_for

marketplace_blueprint = Blueprint("marketplace", __name__)


def _field_error(field: str, message: str) -> APIError:
    return APIError(
        "validation.invalid",
        "Request validation failed.",
        status=422,
        fields={field: [message]},
    )


def _optional_int(value: Any, field: str) -> int | None:
    if value in {None, ""}:
        return None
    try:
        return int(str(value))
    except ValueError as exc:
        raise _field_error(field, "Value must be an integer.") from exc


def _city_payload(city: City | None) -> dict[str, Any] | None:
    if city is None:
        return None
    return {
        "public_id": city.public_id,
        "name": city.name,
        "province": city.province,
        "timezone": city.timezone,
        "country": {
            "iso2": city.country.iso2,
            "name": city.country.name,
            "currency_code": city.country.currency_code,
        },
    }


def _profile_payload(profile: UserProfile | None) -> dict[str, Any]:
    if profile is None:
        return {
            "bio": None,
            "city": None,
            "website_url": None,
            "profile_visibility": "private",
            "rating_average": "0.00",
            "review_count": 0,
            "avatar_file": None,
            "cover_file": None,
        }
    return {
        "bio": profile.bio,
        "city": _city_payload(profile.city),
        "website_url": profile.website_url,
        "profile_visibility": profile.profile_visibility,
        "rating_average": f"{Decimal(profile.rating_average):.2f}",
        "review_count": profile.review_count,
        "avatar_file": _file_payload(profile.avatar_file),
        "cover_file": _file_payload(profile.cover_file),
    }


def _talent_payload(profile: TalentProfile | None) -> dict[str, Any] | None:
    if profile is None:
        return None
    return {
        "public_id": profile.public_id,
        "screen_name": profile.screen_name,
        "age_range": profile.age_range,
        "gender_identity": profile.gender_identity,
        "height_cm": profile.height_cm,
        "union_note": profile.union_note,
        "experience_years": profile.experience_years,
        "availability_status": profile.availability_status,
        "day_rate_minor": profile.day_rate_minor,
        "currency": profile.currency,
        "resume_file": _file_payload(profile.resume_file),
        "languages": [
            {"language": item.language, "proficiency": item.proficiency}
            for item in profile.languages
        ],
    }


def _file_payload(file: FileAsset | None) -> dict[str, Any] | None:
    if file is None:
        return None
    public_url = public_url_for(file)
    return {
        "public_id": file.public_id,
        "mime_type": file.mime_type,
        "size_bytes": file.size_bytes,
        "visibility": file.visibility,
        "scan_status": file.scan_status,
        "processing_status": file.processing_status,
        "original_name": file.original_name,
        "download_url": f"/api/v1/files/{file.public_id}/download",
        "public_url": public_url,
    }


def _listing_media_payload(media: ListingMedia) -> dict[str, Any]:
    return {
        "file": _file_payload(media.file),
        "sort_order": media.sort_order,
        "is_cover": media.is_cover,
        "caption": media.caption,
    }


def _portfolio_payload(item: PortfolioItem) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "profile_type": item.profile_type,
        "profile_id": item.profile_id,
        "title": item.title,
        "category": item.category,
        "file": _file_payload(item.file),
        "thumbnail_file": _file_payload(item.thumbnail_file),
        "duration_seconds": item.duration_seconds,
        "status": item.status,
        "is_cover": item.is_cover,
        "sort_order": item.sort_order,
        "moderation_status": item.moderation_status,
    }


def _saved_search_payload(item: SavedSearch) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "name": item.name,
        "listing_type": item.listing_type,
        "city": _city_payload(item.city),
        "query_text": item.query_text,
        "filters": json.loads(item.filters_json) if item.filters_json else {},
        "notify_enabled": item.notify_enabled,
        "created_at": item.created_at.isoformat(),
    }


def _owner_avatar_url(owner_user_id: object) -> str | None:
    # Listings don't always have their own media attached — falling back to
    # the owner's profile avatar means a candidate card still shows a real
    # photo instead of just initials as soon as they've set one, without
    # requiring them to separately pick listing cover media too.
    profile = db.session.execute(
        select(UserProfile).where(UserProfile.user_id == owner_user_id)
    ).scalar_one_or_none()
    if profile is None or profile.avatar_file is None:
        return None
    return public_url_for(profile.avatar_file)


def _listing_payload(listing: MarketplaceListing) -> dict[str, Any]:
    return {
        "public_id": listing.public_id,
        "listing_type": listing.listing_type,
        "profile_entity_id": listing.profile_entity_id,
        "title": listing.title,
        "summary": listing.summary,
        "city": _city_payload(listing.city),
        "price_from_minor": listing.price_from_minor,
        "currency": listing.currency,
        "verification_status": listing.verification_status,
        "moderation_status": listing.moderation_status,
        "visibility": listing.visibility,
        "published_at": listing.published_at.isoformat()
        if listing.published_at
        else None,
        "owner": {
            "public_id": listing.owner.public_id,
            "display_name": listing.owner.display_name,
            "avatar_url": _owner_avatar_url(listing.owner_user_id),
        },
        "media": [_listing_media_payload(item) for item in listing.media],
    }


def _shortlist_item_payload(item: ShortlistItem) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "listing": _listing_payload(item.listing),
        "candidate_user": {
            "public_id": item.candidate.public_id,
            "display_name": item.candidate.display_name,
        }
        if item.candidate
        else None,
        "rank": item.rank,
        "notes": item.notes,
        "status": item.status,
    }


def _shortlist_payload(item: Shortlist) -> dict[str, Any]:
    return {
        "public_id": item.public_id,
        "project_id": item.project_id,
        "requirement_id": item.requirement_id,
        "name": item.name,
        "items": [_shortlist_item_payload(row) for row in item.items],
        "created_at": item.created_at.isoformat(),
    }


def _city_by_public_id(public_id: str | None) -> City | None:
    if not public_id:
        return None
    city = db.session.execute(
        select(City).where(City.public_id == public_id, City.active.is_(True))
    ).scalar_one_or_none()
    if city is None:
        raise _field_error("city_id", "Select a supported active city.")
    return city


def _marketplace_query_from_payload(payload: dict[str, Any]) -> Any:
    query = select(MarketplaceListing).where(
        MarketplaceListing.visibility == "public",
        MarketplaceListing.moderation_status == "approved",
    )
    listing_type = str(payload.get("listing_type") or payload.get("type") or "").strip()
    if listing_type:
        query = query.where(MarketplaceListing.listing_type == listing_type)
    city_id = str(payload.get("city_id") or payload.get("city") or "").strip()
    if city_id:
        query = query.join(City).where(City.public_id == city_id)
    search = str(payload.get("q") or payload.get("query_text") or "").strip()
    if search:
        pattern = f"%{search}%"
        query = query.where(
            or_(
                MarketplaceListing.title.ilike(pattern),
                MarketplaceListing.summary.ilike(pattern),
            )
        )
    return query


def _public_listing(public_id: str) -> MarketplaceListing:
    listing = db.session.execute(
        select(MarketplaceListing).where(
            MarketplaceListing.public_id == public_id,
            MarketplaceListing.visibility == "public",
            MarketplaceListing.moderation_status == "approved",
        )
    ).scalar_one_or_none()
    if listing is None:
        raise APIError(
            "marketplace.not_found", "Marketplace listing was not found.", status=404
        )
    return listing


def _has_approved_kyc_for_role(user_id: object, role_code: str) -> bool:
    return (
        db.session.execute(
            select(KycSubmission)
            .join(Role, KycSubmission.role_id == Role.id)
            .where(
                KycSubmission.user_id == user_id,
                Role.code == role_code,
                KycSubmission.status == "approved",
            )
            .limit(1)
        ).scalar_one_or_none()
        is not None
    )


def _talent_profile_for_user(user_id: object) -> TalentProfile:
    profile = db.session.execute(
        select(TalentProfile).where(TalentProfile.user_id == user_id)
    ).scalar_one_or_none()
    if profile is None:
        raise APIError(
            "marketplace.profile_required",
            "Create a talent profile before using portfolio features.",
            status=409,
        )
    return profile


def _model_profile_for_user(user_id: object) -> ModelProfile:
    profile = db.session.execute(
        select(ModelProfile).where(ModelProfile.user_id == user_id)
    ).scalar_one_or_none()
    if profile is None:
        raise APIError(
            "marketplace.profile_required",
            "Create a model profile before using portfolio features.",
            status=409,
        )
    return profile


def _profile_public_id_for_type(profile_type: str, user_id: object) -> str:
    if profile_type == "model":
        return _model_profile_for_user(user_id).public_id
    return _talent_profile_for_user(user_id).public_id


def _owned_ready_file(public_id: str | None, user_id: object, field: str) -> FileAsset:
    if not public_id:
        raise _field_error(field, "File id is required.")
    file = db.session.execute(
        select(FileAsset).where(
            FileAsset.public_id == public_id,
            FileAsset.owner_user_id == user_id,
        )
    ).scalar_one_or_none()
    if file is None:
        raise _field_error(field, "Select a file owned by the current user.")
    if file.scan_status != "clean" or file.processing_status != "ready":
        raise _field_error(field, "File must be clean and ready before publishing.")
    return file


def _portfolio_item_for_user(public_id: str, user_id: object) -> PortfolioItem:
    item = db.session.execute(
        select(PortfolioItem).where(
            PortfolioItem.public_id == public_id,
            PortfolioItem.owner_user_id == user_id,
        )
    ).scalar_one_or_none()
    if item is None:
        raise APIError(
            "portfolio.not_found", "Portfolio item was not found.", status=404
        )
    return item


def _shortlist_for_user(public_id: str, user_id: object) -> Shortlist:
    shortlist = db.session.execute(
        select(Shortlist).where(
            Shortlist.public_id == public_id,
            Shortlist.created_by == user_id,
        )
    ).scalar_one_or_none()
    if shortlist is None:
        raise APIError("shortlist.not_found", "Shortlist was not found.", status=404)
    return shortlist


def _shortlist_item_for_user(public_id: str, user_id: object) -> ShortlistItem:
    item = db.session.execute(
        select(ShortlistItem)
        .join(Shortlist, ShortlistItem.shortlist_id == Shortlist.id)
        .where(
            ShortlistItem.public_id == public_id,
            Shortlist.created_by == user_id,
        )
    ).scalar_one_or_none()
    if item is None:
        raise APIError(
            "shortlist_item.not_found",
            "Shortlist item was not found.",
            status=404,
        )
    return item


def _sync_listing_media(
    listing: MarketplaceListing,
    user_id: object,
    payload: dict[str, Any],
) -> None:
    requested_items = payload.get("portfolio_item_ids")
    requested_files = payload.get("media_file_ids")
    if requested_items is None and requested_files is None:
        return

    media_rows: list[tuple[FileAsset, str | None]] = []
    if requested_items is not None:
        if not isinstance(requested_items, list):
            raise _field_error("portfolio_item_ids", "Value must be a list.")
        for raw_id in requested_items[:12]:
            item = _portfolio_item_for_user(str(raw_id), user_id)
            if item.file is None:
                continue
            if item.status != "published" or item.moderation_status != "approved":
                raise _field_error(
                    "portfolio_item_ids",
                    "Only approved published portfolio items can be attached.",
                )
            if (
                item.file.scan_status != "clean"
                or item.file.processing_status != "ready"
            ):
                raise _field_error(
                    "portfolio_item_ids",
                    "Attached portfolio files must be clean and ready.",
                )
            media_rows.append((item.file, item.title))
    if requested_files is not None:
        if not isinstance(requested_files, list):
            raise _field_error("media_file_ids", "Value must be a list.")
        for raw_id in requested_files[:12]:
            media_rows.append(
                (_owned_ready_file(str(raw_id), user_id, "media_file_ids"), None)
            )

    listing.media.clear()
    seen: set[str] = set()
    for index, (file, caption) in enumerate(media_rows, start=1):
        if file.public_id in seen:
            continue
        seen.add(file.public_id)
        listing.media.append(
            ListingMedia(
                file_id=file.id,
                sort_order=index,
                is_cover=index == 1,
                caption=caption,
            )
        )


@marketplace_blueprint.get("/cities")
def cities() -> Response:
    rows = db.session.execute(
        select(City).where(City.active.is_(True)).order_by(City.name.asc())
    ).scalars()
    return jsonify(success({"cities": [_city_payload(city) for city in rows]}))


@marketplace_blueprint.get("/me/profile")
def my_profile() -> Response:
    user = _current_user()
    profile = db.session.execute(
        select(UserProfile).where(UserProfile.user_id == user.id)
    ).scalar_one_or_none()
    return jsonify(success({"profile": _profile_payload(profile)}))


@marketplace_blueprint.patch("/me/profile")
def update_my_profile() -> Response:
    user = _current_user()
    payload = _json_body()
    city = _city_by_public_id(str(payload.get("city_id", "")).strip() or None)
    visibility = str(payload.get("profile_visibility", "private")).strip()
    if visibility not in {"private", "public"}:
        raise _field_error(
            "profile_visibility", "Visibility must be private or public."
        )
    profile = db.session.execute(
        select(UserProfile).where(UserProfile.user_id == user.id)
    ).scalar_one_or_none()
    if profile is None:
        profile = UserProfile(user_id=user.id, profile_visibility=visibility)
        db.session.add(profile)
    profile.bio = str(payload.get("bio", "")).strip()[:2000] or None
    profile.city_id = city.id if city else None
    profile.website_url = str(payload.get("website_url", "")).strip()[:255] or None
    profile.profile_visibility = visibility
    if "avatar_file_id" in payload:
        raw_avatar_id = str(payload.get("avatar_file_id") or "").strip()
        profile.avatar_file_id = (
            _owned_ready_file(raw_avatar_id, user.id, "avatar_file_id").id
            if raw_avatar_id
            else None
        )
    if "cover_file_id" in payload:
        raw_cover_id = str(payload.get("cover_file_id") or "").strip()
        profile.cover_file_id = (
            _owned_ready_file(raw_cover_id, user.id, "cover_file_id").id
            if raw_cover_id
            else None
        )
    db.session.commit()
    return jsonify(success({"profile": _profile_payload(profile)}))


@marketplace_blueprint.get("/talent/profile")
def get_talent_profile() -> Response:
    user = _current_user()
    profile = db.session.execute(
        select(TalentProfile).where(TalentProfile.user_id == user.id)
    ).scalar_one_or_none()
    return jsonify(success({"talent_profile": _talent_payload(profile)}))


@marketplace_blueprint.patch("/talent/profile")
def update_talent_profile() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    screen_name = str(payload.get("screen_name", "")).strip()
    if len(screen_name) < 2:
        raise _field_error("screen_name", "Screen name must contain 2+ characters.")
    currency = None
    if "currency" in payload:
        currency = str(payload.get("currency", "")).strip().upper()
        if len(currency) != 3:
            raise _field_error("currency", "Currency must be a 3-letter ISO code.")
    day_rate_minor = None
    if "day_rate_minor" in payload:
        day_rate_minor = _optional_int(payload.get("day_rate_minor"), "day_rate_minor")
        if day_rate_minor is not None and day_rate_minor < 0:
            raise _field_error("day_rate_minor", "Day rate cannot be negative.")

    profile = db.session.execute(
        select(TalentProfile).where(TalentProfile.user_id == user.id)
    ).scalar_one_or_none()
    if profile is None:
        profile = TalentProfile(user_id=user.id, screen_name=screen_name)
        db.session.add(profile)
    profile.screen_name = screen_name
    if "age_range" in payload:
        profile.age_range = str(payload.get("age_range", "")).strip()[:32] or None
    if "gender_identity" in payload:
        profile.gender_identity = (
            str(payload.get("gender_identity", "")).strip()[:64] or None
        )
    if "height_cm" in payload:
        profile.height_cm = _optional_int(payload.get("height_cm"), "height_cm")
    if "union_note" in payload:
        profile.union_note = str(payload.get("union_note", "")).strip()[:255] or None
    if "experience_years" in payload:
        profile.experience_years = _optional_int(
            payload.get("experience_years"), "experience_years"
        )
    if "availability_status" in payload:
        profile.availability_status = str(
            payload.get("availability_status", "")
        ).strip()
    if "day_rate_minor" in payload:
        profile.day_rate_minor = day_rate_minor
    if currency is not None:
        profile.currency = currency
    if "resume_file_id" in payload:
        raw_resume_id = str(payload.get("resume_file_id") or "").strip()
        profile.resume_file_id = (
            _owned_ready_file(raw_resume_id, user.id, "resume_file_id").id
            if raw_resume_id
            else None
        )
    db.session.flush()

    if "languages" in payload:
        profile.languages.clear()
        for item in payload.get("languages") or []:
            if not isinstance(item, dict):
                continue
            language = str(item.get("language", "")).strip()
            proficiency = str(item.get("proficiency", "conversational")).strip()
            if language:
                db.session.add(
                    TalentLanguage(
                        talent_profile_id=profile.id,
                        language=language[:64],
                        proficiency=proficiency[:32],
                    )
                )
    db.session.commit()
    return jsonify(success({"talent_profile": _talent_payload(profile)}))


@marketplace_blueprint.get("/portfolio")
def portfolio_items() -> Response:
    user = _current_user()
    profile_type = request.args.get("profile_type", "talent")
    if profile_type not in {"talent", "model"}:
        raise _field_error("profile_type", "Only talent or model portfolio is enabled.")
    profile_id = _profile_public_id_for_type(profile_type, user.id)
    rows = db.session.execute(
        select(PortfolioItem)
        .where(
            PortfolioItem.owner_user_id == user.id,
            PortfolioItem.profile_type == profile_type,
            PortfolioItem.profile_id == profile_id,
        )
        .order_by(PortfolioItem.sort_order.asc(), PortfolioItem.created_at.desc())
    ).scalars()
    return jsonify(success({"items": [_portfolio_payload(item) for item in rows]}))


@marketplace_blueprint.post("/portfolio")
def create_portfolio_item() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    profile_type = str(payload.get("profile_type", "talent")).strip()
    if profile_type not in {"talent", "model"}:
        raise _field_error("profile_type", "Only talent or model portfolio is enabled.")
    profile_id = _profile_public_id_for_type(profile_type, user.id)
    title = str(payload.get("title", "")).strip()
    if len(title) < 2:
        raise _field_error("title", "Portfolio title is required.")
    category = str(payload.get("category", "showreel")).strip()[:64] or "showreel"
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
    status = str(payload.get("status", "published")).strip()
    if status not in {"draft", "published"}:
        raise _field_error("status", "Status must be draft or published.")
    item = PortfolioItem(
        owner_user_id=user.id,
        profile_type=profile_type,
        profile_id=profile_id,
        title=title[:180],
        category=category,
        file_id=file.id,
        thumbnail_file_id=thumbnail_file.id if thumbnail_file else None,
        duration_seconds=_optional_int(
            payload.get("duration_seconds"), "duration_seconds"
        ),
        status=status,
        is_cover=bool(payload.get("is_cover", False)),
        sort_order=_optional_int(payload.get("sort_order"), "sort_order") or 100,
        moderation_status="approved",
    )
    db.session.add(item)
    db.session.commit()
    return jsonify(success({"item": _portfolio_payload(item)})), 201


@marketplace_blueprint.patch("/portfolio/<public_id>")
def update_portfolio_item(public_id: str) -> Response:
    user = _current_user()
    payload = _json_body()
    item = _portfolio_item_for_user(public_id, user.id)
    if "title" in payload:
        title = str(payload.get("title", "")).strip()
        if len(title) < 2:
            raise _field_error("title", "Portfolio title is required.")
        item.title = title[:180]
    if "category" in payload:
        item.category = str(payload.get("category", "showreel")).strip()[:64]
    if "status" in payload:
        status = str(payload.get("status", "")).strip()
        if status not in {"draft", "published"}:
            raise _field_error("status", "Status must be draft or published.")
        item.status = status
    if "is_cover" in payload:
        item.is_cover = bool(payload.get("is_cover"))
    if "sort_order" in payload:
        item.sort_order = _optional_int(payload.get("sort_order"), "sort_order") or 100
    if "file_id" in payload:
        item.file_id = _owned_ready_file(
            str(payload.get("file_id", "")).strip(), user.id, "file_id"
        ).id
    db.session.commit()
    return jsonify(success({"item": _portfolio_payload(item)}))


@marketplace_blueprint.delete("/portfolio/<public_id>")
def delete_portfolio_item(public_id: str) -> Response:
    user = _current_user()
    item = _portfolio_item_for_user(public_id, user.id)
    db.session.delete(item)
    db.session.commit()
    return jsonify(success({"deleted": True}))


@marketplace_blueprint.get("/saved-searches")
def saved_searches() -> Response:
    user = _current_user()
    rows = db.session.execute(
        select(SavedSearch)
        .where(SavedSearch.owner_user_id == user.id)
        .order_by(SavedSearch.created_at.desc())
    ).scalars()
    return jsonify(
        success({"saved_searches": [_saved_search_payload(row) for row in rows]})
    )


@marketplace_blueprint.post("/saved-searches")
def create_saved_search() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    name = str(payload.get("name", "")).strip()
    if len(name) < 2:
        raise _field_error("name", "Saved search name is required.")
    city = _city_by_public_id(str(payload.get("city_id", "")).strip() or None)
    listing_type = str(payload.get("listing_type", "")).strip() or None
    supported_listing_types = {
        "actor",
        "model",
        "location",
        "equipment",
        "agency",
        "distribution",
        "talent",
    }
    if listing_type and listing_type not in supported_listing_types:
        raise _field_error("listing_type", "Unsupported saved-search listing type.")
    filters = payload.get("filters") or {}
    if not isinstance(filters, dict):
        raise _field_error("filters", "Filters must be an object.")
    item = SavedSearch(
        owner_user_id=user.id,
        name=name[:120],
        listing_type=listing_type,
        city_id=city.id if city else None,
        query_text=str(payload.get("query_text", "")).strip()[:255] or None,
        filters_json=json.dumps(filters, sort_keys=True),
        notify_enabled=bool(payload.get("notify_enabled", False)),
    )
    db.session.add(item)
    db.session.commit()
    return jsonify(success({"saved_search": _saved_search_payload(item)})), 201


@marketplace_blueprint.delete("/saved-searches/<public_id>")
def delete_saved_search(public_id: str) -> Response:
    user = _current_user()
    item = db.session.execute(
        select(SavedSearch).where(
            SavedSearch.public_id == public_id,
            SavedSearch.owner_user_id == user.id,
        )
    ).scalar_one_or_none()
    if item is None:
        raise APIError(
            "saved_search.not_found", "Saved search was not found.", status=404
        )
    db.session.delete(item)
    db.session.commit()
    return jsonify(success({"deleted": True}))


@marketplace_blueprint.get("/shortlists")
def shortlists() -> Response:
    user = _current_user()
    rows = db.session.execute(
        select(Shortlist)
        .where(Shortlist.created_by == user.id)
        .order_by(Shortlist.created_at.desc())
    ).scalars()
    return jsonify(success({"shortlists": [_shortlist_payload(row) for row in rows]}))


@marketplace_blueprint.post("/shortlists")
def create_shortlist() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    name = str(payload.get("name", "")).strip()
    if len(name) < 2:
        raise _field_error("name", "Shortlist name is required.")
    item = Shortlist(
        created_by=user.id,
        name=name[:160],
        project_id=str(payload.get("project_id", "")).strip()[:40] or None,
        requirement_id=str(payload.get("requirement_id", "")).strip()[:40] or None,
    )
    db.session.add(item)
    db.session.commit()
    return jsonify(success({"shortlist": _shortlist_payload(item)})), 201


@marketplace_blueprint.post("/shortlists/<public_id>/items")
def add_shortlist_item(public_id: str) -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    shortlist = _shortlist_for_user(public_id, user.id)
    listing = _public_listing(str(payload.get("listing_id", "")).strip())
    existing = db.session.execute(
        select(ShortlistItem).where(
            ShortlistItem.shortlist_id == shortlist.id,
            ShortlistItem.listing_id == listing.id,
        )
    ).scalar_one_or_none()
    rank = _optional_int(payload.get("rank"), "rank")
    if existing is None:
        existing = ShortlistItem(
            shortlist_id=shortlist.id,
            listing_id=listing.id,
            candidate_user_id=listing.owner_user_id,
            rank=rank or len(shortlist.items) + 1,
            status=str(payload.get("status", "active")).strip() or "active",
        )
        db.session.add(existing)
        status_code = 201
    else:
        if rank is not None:
            existing.rank = rank
        status_code = 200
    if "notes" in payload:
        existing.notes = str(payload.get("notes", "")).strip()[:2000] or None
    db.session.commit()
    return jsonify(success({"item": _shortlist_item_payload(existing)})), status_code


@marketplace_blueprint.patch("/shortlist-items/<public_id>")
def update_shortlist_item(public_id: str) -> Response:
    user = _current_user()
    payload = _json_body()
    item = _shortlist_item_for_user(public_id, user.id)
    if "rank" in payload:
        item.rank = _optional_int(payload.get("rank"), "rank") or item.rank
    if "notes" in payload:
        item.notes = str(payload.get("notes", "")).strip()[:2000] or None
    if "status" in payload:
        status = str(payload.get("status", "")).strip()
        if status not in {"active", "selected", "rejected", "archived"}:
            raise _field_error("status", "Unsupported shortlist item status.")
        item.status = status
    db.session.commit()
    return jsonify(success({"item": _shortlist_item_payload(item)}))


@marketplace_blueprint.delete("/shortlist-items/<public_id>")
def delete_shortlist_item(public_id: str) -> Response:
    user = _current_user()
    item = _shortlist_item_for_user(public_id, user.id)
    db.session.delete(item)
    db.session.commit()
    return jsonify(success({"deleted": True}))


@marketplace_blueprint.post("/marketplace/listings")
def publish_listing() -> ResponseReturnValue:
    user = _current_user()
    payload = _json_body()
    listing_type = str(payload.get("listing_type", "")).strip()
    if listing_type not in {"talent", "location"}:
        raise _field_error(
            "listing_type", "Only talent and location listings can be published."
        )
    if listing_type == "location":
        property_id = str(
            payload.get("profile_entity_id") or payload.get("property_id") or ""
        ).strip()
        location = db.session.execute(
            select(LocationProperty).where(
                LocationProperty.public_id == property_id,
                LocationProperty.owner_user_id == user.id,
            )
        ).scalar_one_or_none()
        if location is None:
            raise APIError(
                "marketplace.profile_required",
                "Create or select a location property before publishing.",
                status=409,
            )
        title = str(payload.get("title") or location.name).strip()
        summary = str(
            payload.get("summary")
            or location.description
            or (
                f"{location.name} is available for film and commercial "
                "productions in "
                f"{location.area_name or location.public_address or 'Pakistan'}."
            )
        ).strip()
        if len(title) < 2:
            raise _field_error("title", "Listing title is required.")
        if len(summary) < 10:
            raise _field_error(
                "summary", "Listing summary must contain 10+ characters."
            )
        requested_city = str(payload.get("city_id", "")).strip()
        city = _city_by_public_id(requested_city) if requested_city else location.city
        listing = db.session.execute(
            select(MarketplaceListing).where(
                MarketplaceListing.owner_user_id == user.id,
                MarketplaceListing.listing_type == "location",
                MarketplaceListing.profile_entity_id == location.public_id,
            )
        ).scalar_one_or_none()
        if listing is None:
            listing = MarketplaceListing(
                owner_user_id=user.id,
                listing_type="location",
                profile_entity_id=location.public_id,
                verification_status="unverified",
                moderation_status="approved",
                visibility="public",
            )
            db.session.add(listing)
        enabled_prices = [
            price.amount_minor for price in location.pricing if price.enabled
        ]
        listing.title = title[:180]
        listing.summary = summary[:2000]
        listing.city_id = city.id if city else location.city_id
        listing.price_from_minor = min(enabled_prices) if enabled_prices else None
        listing.currency = str(payload.get("currency", "PKR")).strip().upper()[:3]
        listing.published_at = listing.published_at or utc_now()
        location.status = "published"
        db.session.flush()
        _sync_listing_media(listing, user.id, payload)
        db.session.commit()
        return jsonify(success({"listing": _listing_payload(listing)})), 201
    if not _has_approved_kyc_for_role(user.id, "actor_talent"):
        raise APIError(
            "marketplace.kyc_required",
            "Approved Actor / Talent KYC is required before publishing.",
            status=403,
        )
    talent = db.session.execute(
        select(TalentProfile).where(TalentProfile.user_id == user.id)
    ).scalar_one_or_none()
    if talent is None:
        raise APIError(
            "marketplace.profile_required",
            "Create a talent profile before publishing.",
            status=409,
        )
    title = str(payload.get("title") or talent.screen_name).strip()
    summary = str(payload.get("summary", "")).strip()
    if len(title) < 2:
        raise _field_error("title", "Listing title is required.")
    if len(summary) < 10:
        raise _field_error("summary", "Listing summary must contain 10+ characters.")
    city = _city_by_public_id(str(payload.get("city_id", "")).strip() or None)
    listing = db.session.execute(
        select(MarketplaceListing).where(
            MarketplaceListing.owner_user_id == user.id,
            MarketplaceListing.listing_type == "talent",
            MarketplaceListing.profile_entity_id == talent.public_id,
        )
    ).scalar_one_or_none()
    if listing is None:
        listing = MarketplaceListing(
            owner_user_id=user.id,
            listing_type="talent",
            profile_entity_id=talent.public_id,
            verification_status="approved",
            moderation_status="approved",
            visibility="public",
        )
        db.session.add(listing)
    listing.title = title[:180]
    listing.summary = summary[:2000]
    listing.city_id = city.id if city else None
    listing.price_from_minor = talent.day_rate_minor
    listing.currency = talent.currency
    listing.published_at = listing.published_at or utc_now()
    db.session.flush()
    _sync_listing_media(listing, user.id, payload)
    db.session.commit()
    return jsonify(success({"listing": _listing_payload(listing)})), 201


@marketplace_blueprint.get("/marketplace/listings")
def marketplace_listings() -> Response:
    query = _marketplace_query_from_payload(
        {
            "type": request.args.get("type"),
            "city": request.args.get("city"),
            "q": request.args.get("q"),
        }
    )
    listings = db.session.execute(
        query.order_by(MarketplaceListing.published_at.desc()).limit(50)
    ).scalars()
    return jsonify(success({"listings": [_listing_payload(item) for item in listings]}))


@marketplace_blueprint.get("/marketplace/listings/<public_id>")
def marketplace_listing_detail(public_id: str) -> Response:
    listing = db.session.execute(
        select(MarketplaceListing).where(
            MarketplaceListing.public_id == public_id,
            MarketplaceListing.visibility == "public",
            MarketplaceListing.moderation_status == "approved",
        )
    ).scalar_one_or_none()
    if listing is None:
        raise APIError(
            "marketplace.not_found", "Marketplace listing was not found.", status=404
        )
    return jsonify(success({"listing": _listing_payload(listing)}))


@marketplace_blueprint.post("/marketplace/result-count")
def marketplace_result_count() -> Response:
    payload = _json_body()
    count = db.session.execute(
        select(func.count()).select_from(
            _marketplace_query_from_payload(payload).subquery()
        )
    ).scalar_one()
    return jsonify(success({"count": count}))


@marketplace_blueprint.get("/marketplace/facets")
def marketplace_facets() -> Response:
    listing_counts = db.session.execute(
        select(MarketplaceListing.listing_type, func.count(MarketplaceListing.id))
        .where(
            MarketplaceListing.visibility == "public",
            MarketplaceListing.moderation_status == "approved",
        )
        .group_by(MarketplaceListing.listing_type)
    ).all()
    cities = db.session.execute(
        select(City).where(City.active.is_(True)).order_by(City.name.asc())
    ).scalars()
    return jsonify(
        success(
            {
                "listing_types": [
                    {"type": item[0], "count": item[1]} for item in listing_counts
                ],
                "cities": [_city_payload(city) for city in cities],
            }
        )
    )
