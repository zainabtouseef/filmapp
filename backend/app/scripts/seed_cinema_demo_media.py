from __future__ import annotations

import json
from datetime import date

from sqlalchemy import select

from app import create_app
from app.extensions import db
from app.models.identity import User
from app.models.marketplace import City
from app.models.projects import Project, ProjectFile, ProjectMember


OWNER_EMAIL = "dp01@demo.cine.nalexustechnologies.com"


DEMO_MEDIA = [
    {
        "project": "The Legend of Maula Jatt",
        "type": "Film",
        "city": "Lahore",
        "description": "Official Pakistani film trailer reference for CineConnect cinema demos.",
        "folder": "trailer",
        "label": "The Legend of Maula Jatt — Official Theatrical Trailer",
        "url": "https://www.youtube.com/watch?v=pEWqOAcYgpQ",
        "thumbnail": "https://img.youtube.com/vi/pEWqOAcYgpQ/hqdefault.jpg",
        "duration": 143,
    },
    {
        "project": "Joyland",
        "type": "Film",
        "city": "Lahore",
        "description": "Official Pakistani film trailer reference for public cinema discovery.",
        "folder": "trailer",
        "label": "Joyland — Official Trailer",
        "url": "https://www.youtube.com/watch?v=gy9bNgbZMJI",
        "thumbnail": "https://img.youtube.com/vi/gy9bNgbZMJI/hqdefault.jpg",
        "duration": 115,
    },
    {
        "project": "Khuda Kay Liye",
        "type": "Film",
        "city": "Islamabad",
        "description": "Official Shoaib Mansoor film trailer reference for cinema demos.",
        "folder": "trailer",
        "label": "Khuda Kay Liye — Official Trailer",
        "url": "https://www.youtube.com/watch?v=CwPTOak6NPI",
        "thumbnail": "https://img.youtube.com/vi/CwPTOak6NPI/hqdefault.jpg",
        "duration": 112,
    },
    {
        "project": "Bol",
        "type": "Film",
        "city": "Karachi",
        "description": "Official Shoaib Mansoor film trailer reference for cinema demos.",
        "folder": "trailer",
        "label": "Bol — Official Trailer",
        "url": "https://www.youtube.com/watch?v=mVKuPAklU9w",
        "thumbnail": "https://img.youtube.com/vi/mVKuPAklU9w/hqdefault.jpg",
        "duration": 157,
    },
    {
        "project": "Humsafar",
        "type": "Drama",
        "city": "Karachi",
        "description": "Official HUM Music OST reference for Pakistani drama cinema demos.",
        "folder": "ost",
        "label": "Humsafar — OST by Qurat-ul-Ain Balouch",
        "url": "https://www.youtube.com/watch?v=2OCjfBPfFgs",
        "thumbnail": "https://img.youtube.com/vi/2OCjfBPfFgs/hqdefault.jpg",
        "duration": 245,
    },
    {
        "project": "Mere Humsafar",
        "type": "Drama",
        "city": "Karachi",
        "description": "Official ARY Digital OST reference for Pakistani drama cinema demos.",
        "folder": "ost",
        "label": "Mere Humsafar — Official OST",
        "url": "https://www.youtube.com/watch?v=X8IU4jaBEzs",
        "thumbnail": "https://img.youtube.com/vi/X8IU4jaBEzs/hqdefault.jpg",
        "duration": 270,
    },
    {
        "project": "Parizaad",
        "type": "Drama",
        "city": "Lahore",
        "description": "Official HUM TV drama OST reference for premium cinema demos.",
        "folder": "ost",
        "label": "Parizaad — Unplugged OST",
        "url": "https://www.youtube.com/watch?v=M1lKUg_aAk8",
        "thumbnail": "https://img.youtube.com/vi/M1lKUg_aAk8/hqdefault.jpg",
        "duration": 292,
    },
    {
        "project": "Tere Bin",
        "type": "Drama",
        "city": "Karachi",
        "description": "Official Har Pal Geo OST reference for public cinema demos.",
        "folder": "ost",
        "label": "Tere Bin — Official OST",
        "url": "https://www.youtube.com/watch?v=X20tWrpYAA4",
        "thumbnail": "https://img.youtube.com/vi/X20tWrpYAA4/hqdefault.jpg",
        "duration": 244,
    },
]


def _city(name: str) -> City | None:
    return db.session.execute(select(City).where(City.name == name)).scalar_one_or_none()


def _project(owner: User, item: dict[str, object]) -> Project:
    project = db.session.execute(
        select(Project).where(Project.owner_user_id == owner.id, Project.title == item["project"])
    ).scalar_one_or_none()
    if project is None:
        project = Project(
            owner_user_id=owner.id,
            title=str(item["project"]),
            project_type=str(item["type"]),
            description=str(item["description"]),
            city_id=_city(str(item["city"])).id if _city(str(item["city"])) else None,
            start_date=date(2026, 8, 1),
            end_date=date(2026, 12, 31),
            status="active",
            estimated_budget_minor=25_000_000,
            currency="PKR",
            visibility="project_members",
            progress_percent=65,
        )
        db.session.add(project)
        db.session.flush()
        db.session.add(
            ProjectMember(
                project_id=project.id,
                user_id=owner.id,
                role_label="Owner",
                permissions_json=json.dumps(
                    {
                        "manage_project": True,
                        "manage_requirements": True,
                        "manage_members": True,
                    },
                    sort_keys=True,
                ),
                status="active",
            )
        )
    else:
        project.project_type = str(item["type"])
        project.description = str(item["description"])
        project.status = "active"
        project.progress_percent = max(project.progress_percent or 0, 65)
    return project


def seed() -> None:
    owner = db.session.execute(select(User).where(User.email == OWNER_EMAIL)).scalar_one_or_none()
    if owner is None:
        raise RuntimeError(f"Demo owner not found: {OWNER_EMAIL}")

    created = 0
    updated = 0
    for item in DEMO_MEDIA:
        project = _project(owner, item)
        media = db.session.execute(
            select(ProjectFile).where(
                ProjectFile.project_id == project.id,
                ProjectFile.external_url == item["url"],
            )
        ).scalar_one_or_none()
        if media is None:
            media = ProjectFile(
                project_id=project.id,
                file_id=None,
                uploaded_by=owner.id,
                folder=str(item["folder"]),
                label=str(item["label"]),
                visibility="public",
                sort_order=10 if item["folder"] == "trailer" else 20,
            )
            db.session.add(media)
            created += 1
        else:
            updated += 1
        media.external_url = str(item["url"])
        media.external_provider = "youtube"
        media.external_thumbnail_url = str(item["thumbnail"])
        media.external_duration_seconds = int(item["duration"])
        media.folder = str(item["folder"])
        media.label = str(item["label"])
        media.visibility = "public"

    db.session.commit()
    print(f"Seeded cinema demo media: created={created} updated={updated}")


def main() -> None:
    app = create_app()
    with app.app_context():
        seed()


if __name__ == "__main__":
    main()
