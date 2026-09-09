from __future__ import annotations


import hashlib
import json
import mimetypes
import os
import sys
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from sqlalchemy import select

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app import create_app
from app.extensions import db
from app.models import (
    FileAsset,
    ListingMedia,
    MarketplaceListing,
    Project,
)


SEED_BATCH = "cineconnect-director-public-media-2026-07-22"
USER_AGENT = "CineConnectDemoSeeder/1.0"
OFFLINE_MEDIA = os.getenv("CINECONNECT_PUBLIC_MEDIA_OFFLINE", "").lower() in {
    "1",
    "true",
    "yes",
}


@dataclass(frozen=True)
class DirectorMediaAsset:
    idx: int
    title: str
    project_id: str
    listing_id: str
    filename: str
    url: str
    source_page: str
    reason: str

    @property
    def project_file_id(self) -> str:
        return f"DEMO-DIR-PROJ-MEDIA-{self.idx:03}"

    @property
    def listing_file_id(self) -> str:
        return f"DEMO-DIR-LISTING-MEDIA-{self.idx:03}"


ASSETS = [
    DirectorMediaAsset(
        1,
        "Lahore Fort production mood",
        "DEMO-PROJ-001",
        "DEMO-LST-AT-001",
        "lahore-fort-river-lights.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/4/4f/Lahore_Fort_view_from_Baradari.jpg",
        "https://en.wikipedia.org/wiki/Lahore_Fort",
        "Historic Lahore texture for the River Lights feature-film card.",
    ),
    DirectorMediaAsset(
        2,
        "Karachi Clifton skyline",
        "DEMO-PROJ-002",
        "DEMO-LST-AT-002",
        "karachi-clifton-city-of-dust.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/2/20/Clifton_Karachi_View.jpg",
        "https://en.wikipedia.org/wiki/Karachi",
        "Urban Karachi skyline for the City of Dust TV-drama card.",
    ),
    DirectorMediaAsset(
        3,
        "Faisal Mosque Islamabad",
        "DEMO-PROJ-003",
        "DEMO-LST-AT-003",
        "faisal-mosque-blue-van.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Ali_Mujtaba_WLM2017_FAISAL_MOSQUE_019.jpg/3840px-Ali_Mujtaba_WLM2017_FAISAL_MOSQUE_019.jpg",
        "https://en.wikipedia.org/wiki/Faisal_Mosque",
        "Clean Islamabad landmark mood for the Blue Van commercial.",
    ),
    DirectorMediaAsset(
        4,
        "Badshahi Mosque Lahore",
        "DEMO-PROJ-004",
        "DEMO-LST-AT-004",
        "badshahi-mosque-eid-run.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/c/c8/Badshahi_Mosque_front_picture.jpg",
        "https://en.wikipedia.org/wiki/Badshahi_Mosque",
        "Recognizable Lahore heritage frame for the Eid Run music video.",
    ),
    DirectorMediaAsset(
        5,
        "Gwadar coast aerial",
        "DEMO-PROJ-005",
        "DEMO-LST-AT-005",
        "gwadar-coast-salt-road.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f7/Gwadar_city%2C_the_doors_of_Air.jpg/3840px-Gwadar_city%2C_the_doors_of_Air.jpg",
        "https://en.wikipedia.org/wiki/Gwadar",
        "Coastal Balochistan context for the Salt Road documentary.",
    ),
    DirectorMediaAsset(
        6,
        "Mazar-e-Quaid Karachi",
        "DEMO-PROJ-006",
        "DEMO-LST-AT-006",
        "mazar-e-quaid-campus-beat.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/PK_Karachi_asv2020-02_img52_Mazar-e-Quaid.jpg/3840px-PK_Karachi_asv2020-02_img52_Mazar-e-Quaid.jpg",
        "https://en.wikipedia.org/wiki/Mazar-e-Quaid",
        "Karachi civic landmark for the Campus Beat web-series card.",
    ),
    DirectorMediaAsset(
        7,
        "Rawalpindi railway station",
        "DEMO-PROJ-007",
        "DEMO-LST-AT-007",
        "rawalpindi-station-night-bazaar.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7d/Rawalpindi_railway_station_4.JPG/3840px-Rawalpindi_railway_station_4.JPG",
        "https://en.wikipedia.org/wiki/Rawalpindi",
        "Rawalpindi street-movement cue for the Night Bazaar short film.",
    ),
    DirectorMediaAsset(
        8,
        "Noor Mahal Bahawalpur",
        "DEMO-PROJ-008",
        "DEMO-LST-AT-008",
        "noor-mahal-monsoon-menu.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/thumb/4/40/Front_Elevation_of_Noor_Mahal.jpg/3840px-Front_Elevation_of_Noor_Mahal.jpg",
        "https://en.wikipedia.org/wiki/Noor_Mahal",
        "Elegant palace exterior for the Monsoon Menu campaign card.",
    ),
    DirectorMediaAsset(
        9,
        "Hunza Valley mountain unit",
        "DEMO-PROJ-009",
        "DEMO-LST-AT-009",
        "hunza-valley-safe-set-psa.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/d/dc/Hunza_Valley_HDR.jpg",
        "https://en.wikipedia.org/wiki/Hunza_Valley",
        "Northern Pakistan mountain context for the Safe Set PSA.",
    ),
    DirectorMediaAsset(
        10,
        "Derawar Fort desert exterior",
        "DEMO-PROJ-010",
        "DEMO-LST-AT-010",
        "derawar-fort-desert-echo.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/thumb/0/00/Derawar_Fort%2C_Bahawalpur_I.jpg/3840px-Derawar_Fort%2C_Bahawalpur_I.jpg",
        "https://en.wikipedia.org/wiki/Derawar_Fort",
        "Bahawalpur desert scale for the Desert Echo OTT-pilot card.",
    ),
]


def remember(stats: dict[str, int], key: str, created: bool) -> None:
    suffix = "created" if created else "existing"
    stats[f"{key}_{suffix}"] = stats.get(f"{key}_{suffix}", 0) + 1


def public_root() -> Path:
    root = Path(
        os.getenv("LOCAL_STORAGE_PUBLIC_ROOT", "/data/storage/public")
    ).expanduser()
    root.mkdir(parents=True, exist_ok=True)
    return root


def download_bytes(url: str) -> tuple[bytes, str]:
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=60) as response:
        data = response.read()
        mime = response.headers.get_content_type()
    if not data:
        raise RuntimeError(f"Downloaded empty media response: {url}")
    if not mime.startswith("image/"):
        guessed = mimetypes.guess_type(url)[0]
        if guessed and guessed.startswith("image/"):
            mime = guessed
        else:
            raise RuntimeError(f"Downloaded media is not an image: {url} ({mime})")
    return data, mime


def write_public_media(
    asset: DirectorMediaAsset,
    variant: str,
    downloaded: tuple[bytes, str] | None = None,
) -> dict[str, Any]:
    storage_key = f"demo/{SEED_BATCH}/{variant}/{asset.filename}"
    target = public_root() / storage_key
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        data = target.read_bytes()
        mime = mimetypes.guess_type(target.name)[0] or "image/jpeg"
    else:
        if OFFLINE_MEDIA:
            raise RuntimeError(f"Missing offline media file: {target}")
        data, mime = downloaded or download_bytes(asset.url)
        target.write_bytes(data)
    return {
        "storage_key": storage_key,
        "mime_type": mime,
        "size_bytes": len(data),
        "checksum_sha256": hashlib.sha256(data).hexdigest(),
        "original_name": f"{variant}-{asset.filename}",
    }


def file_asset(public_id: str) -> FileAsset | None:
    return db.session.execute(
        select(FileAsset).where(FileAsset.public_id == public_id)
    ).scalar_one_or_none()


def ensure_public_file(
    public_id: str,
    owner_user_id: Any,
    media: dict[str, Any],
    stats: dict[str, int],
) -> FileAsset:
    file = file_asset(public_id)
    created = False
    if file is None:
        file = FileAsset(public_id=public_id, owner_user_id=owner_user_id)
        db.session.add(file)
        created = True
    file.owner_user_id = owner_user_id
    file.storage_key = media["storage_key"]
    file.bucket = os.getenv("OBJECT_STORAGE_BUCKET_PUBLIC", "cineconnect-public")
    file.mime_type = media["mime_type"]
    file.size_bytes = media["size_bytes"]
    file.checksum_sha256 = media["checksum_sha256"]
    file.visibility = "public"
    file.scan_status = "clean"
    file.processing_status = "ready"
    file.original_name = media["original_name"]
    db.session.flush()
    remember(stats, "public_file", created)
    return file


def attach_asset(asset: DirectorMediaAsset, stats: dict[str, int]) -> None:
    project = db.session.execute(
        select(Project).where(Project.public_id == asset.project_id)
    ).scalar_one_or_none()
    listing = db.session.execute(
        select(MarketplaceListing).where(
            MarketplaceListing.public_id == asset.listing_id
        )
    ).scalar_one_or_none()
    if project is None:
        raise RuntimeError(f"Missing seeded project: {asset.project_id}")
    if listing is None:
        raise RuntimeError(f"Missing seeded listing: {asset.listing_id}")

    downloaded = None
    if not OFFLINE_MEDIA:
        downloaded = download_bytes(asset.url)
    project_media = write_public_media(asset, "project-covers", downloaded)
    project_file = ensure_public_file(
        asset.project_file_id,
        project.owner_user_id,
        project_media,
        stats,
    )
    project.cover_file_id = project_file.id
    remember(stats, "project_cover_attached", False)

    listing_media = write_public_media(asset, "listing-covers", downloaded)
    listing_file = ensure_public_file(
        asset.listing_file_id,
        listing.owner_user_id,
        listing_media,
        stats,
    )
    row = db.session.execute(
        select(ListingMedia).where(
            ListingMedia.listing_id == listing.id,
            ListingMedia.file_id == listing_file.id,
        )
    ).scalar_one_or_none()
    created = False
    if row is None:
        row = ListingMedia(listing_id=listing.id, file_id=listing_file.id)
        db.session.add(row)
        created = True
    row.sort_order = 0
    row.is_cover = True
    row.caption = asset.title
    remember(stats, "listing_media", created)


def main() -> None:
    app = create_app()
    stats: dict[str, int] = {}
    with app.app_context():
        for asset in ASSETS:
            attach_asset(asset, stats)
        db.session.commit()
    print(
        json.dumps(
            {
                "seed_batch": SEED_BATCH,
                "assets": len(ASSETS),
                "stats": dict(sorted(stats.items())),
            },
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
