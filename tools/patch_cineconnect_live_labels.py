"""Apply presentation-copy updates to a copy of the currently deployed web build.

The live build contains newer work than this checkout. This script updates only
referenced dart2js chunks, preserving the live features and backend role codes.
"""

from __future__ import annotations

import argparse
import hashlib
import re
from pathlib import Path


PHRASES = (
    ("Actor / Talent Portal", "Actor Portal"),
    ("Actor / Talent workspace", "Actor workspace"),
    ("Talent Workspace", "Actor Workspace"),
    ("Talent workspace", "Actor workspace"),
    ("Talent Snapshot", "Actor Snapshot"),
    ("Talent operations", "Actor activity"),
    ("Verified talent", "Verified actor"),
    ("Talent profile", "Actor profile"),
    ("Talent Roster Manager", "Artist Roster"),
    ("Talent roster", "Artist roster"),
    ("Talent Portal", "Actor Portal"),
    ("Find Talent", "Find Actors"),
    ("Crew Dashboard", "Dashboard"),
    ("Crew Workspace", "Production Services"),
    ("Crew workspace", "Production services workspace"),
    ("Crew production workspace", "Production services workspace"),
    ("Crew Services", "Production Services"),
    ("Crew Pro", "Service Professional"),
    ("CREW / PRODUCTION SERVICES", "PRODUCTION SERVICES"),
    ("Crew Request Inbox", "Request Inbox"),
    ("Open Crew Requests", "Open Service Requests"),
    ("Crew Provider", "Service Professional"),
    ("Crew marketplace pricing", "Service pricing"),
    ("Find Crew", "Find Production Services"),
    ("Actor \\xb7 Talent", "Actor"),
    ('["All","Director / Producer","Actor / Talent"',
     '["All","Director / Producer","Actor"'),
    ("Talent Profile", "Actor Profile"),
    ("Talent & vendors", "People & vendors"),
    ("Talent categories", "Creative categories"),
    ("Talent details", "Actor details"),
    ("Talent type", "Performer type"),
    ("Talent fee", "Actor fee"),
    ("Talent base rate card", "Base rate card"),
    ("Talent availability", "Actor availability"),
    ("Talent safety concern", "Profile safety concern"),
    ("Browse Talent", "Browse People"),
    ("Browse talent", "Browse people"),
    ("Add represented talent", "Add represented artist"),
    ("Manage represented talent profiles", "Manage represented artist profiles"),
    ("Search represented talent", "Search represented artists"),
    ("Represented talent records", "Represented artist records"),
    ("represented talent records", "represented artist records"),
    ("Book talent for your brand", "Find people for your production"),
    ("talent profile", "actor profile"),
    ("talent fee", "actor fee"),
    ("talent roles", "acting roles"),
    ("talent to rank", "actors to rank"),
    ("talent profiles", "actor profiles"),
    ("saved talent", "saved people"),
    ("Talent \\xb7 crew", "Actors \\xb7 production services"),
    ("Actor \\xb7 model \\xb7 crew", "Actor \\xb7 model \\xb7 production services"),
    ("Crew Portal", "Production Services Portal"),
    ("Crew service screens", "Production service screens"),
    ("Crew service details", "Production service details"),
    ("Crew service", "Production service"),
    ("Crew operations", "Service activity"),
    ("Crew booking accepted", "Booking accepted"),
    ("Crew contract generated", "Contract generated"),
    ("Crew contracts", "Contracts"),
    ("Crew provider counteroffer", "Service provider counteroffer"),
    ("Crew schedule block", "Availability block"),
    ("Crew on call", "Production team on call"),
    ("Crew assigned", "Production team assigned"),
    ("Crew attendance", "Production team attendance"),
    ("Crew capacity", "Team capacity"),
    ("Crew limit", "Team limit"),
    ("Crew size", "Team size"),
    ("Add crew member", "Add team member"),
    ("Add crew", "Add team member"),
    ("Edit crew hiring profile", "Edit service profile"),
    ("Production-ready crew", "Production-ready professional"),
    ("No crew members added", "No team members added"),
    ("No crew contracts", "No contracts"),
    ("No crew ledger", "No ledger"),
    ("No crew requests", "No requests"),
    ("No crew assigned", "No team members assigned"),
    ("Counter crew request", "Counter request"),
    ("Reject crew request", "Reject request"),
    ("Loading crew booking requests", "Loading booking requests"),
    ("Crew member added", "Team member added"),
    ("crew bookings", "bookings"),
    ("crew requirements", "production service requests"),
    ("crew requests", "service requests"),
    ("crew role", "production role"),
    ("crew capacity", "team capacity"),
    ("crew card", "service card"),
    ("crew schedule", "availability"),
    ("your crew", "your team"),
    ("Correct talent type", "Correct performer type"),
    ("Sign in to load your talent snapshot", "Sign in to load your actor dashboard"),
    ("Sign in to load crew operations", "Sign in to load your work dashboard"),
    ("Search talent and resources", "Search people and resources"),
    ("Search talent, crew, locations", "Search actors, production services, locations"),
    ("Search talent, crew, equipment, and locations", "Search actors, production services, equipment, and locations"),
    ("Search vetted crew, gear and locations", "Search production professionals, gear and locations"),
    ("See how directors search for crew", "See how directors search for production services"),
    ("Need actors, models, crew, locations or equipment", "Need actors, models, production services, locations or equipment"),
    ("Equipment and crew categories", "Equipment and service categories"),
    ("Lock shoot dates once talent is booked", "Lock shoot dates once actors are booked"),
    ("talent and resources", "people and resources"),
    ("This actor / talent has not uploaded", "This actor has not uploaded"),
    ("real actor/talent lifecycle", "actor workflow"),
    ("real crew lifecycle", "service provider workflow"),
    ("28 crew + 6 cast", "28 team members + 6 cast"),
    ("Crew call ", "Team call "),
    ("crew services", "production services"),
    ("crew, media teams", "production professionals, media teams"),
    ("crew, locations or equipment", "production services, locations or equipment"),
    ("crew, locations and equipment", "production services, locations and equipment"),
    ("talent, crew", "actors, production services"),
    ("talent, model, crew", "actors, models, production services"),
    ("\"Talent\"", "\"Actor\""),
    ("\"Crew\"", "\"Production Services\""),
)


def patch(root: Path) -> None:
    main = root / "main.dart.js"
    main_text = main.read_text()
    chunk_names = sorted(set(re.findall(r"main\.dart\.js_\d+\.part\.js", main_text)))
    if len(chunk_names) < 100:
        raise RuntimeError("Unexpectedly small deferred-chunk manifest")
    files = [main, *(root / name for name in chunk_names)]
    missing = [str(path) for path in files if not path.is_file()]
    if missing:
        raise RuntimeError(f"Missing referenced chunks: {missing[:5]}")
    all_text = "".join(path.read_text() for path in files)
    for required in ("New on CineConnect", "main.dart.js_"):
        if required not in all_text:
            raise RuntimeError(f"Expected live label missing: {required}")

    changed = 0
    counts: dict[str, int] = {}
    for path in files:
        original = path.read_text()
        updated = original
        for old, new in PHRASES:
            count = updated.count(old)
            if count:
                updated = updated.replace(old, new)
                counts[old] = counts.get(old, 0) + count
        if updated != original:
            path.write_text(updated)
            changed += 1

    index = root / "index.html"
    html = index.read_text()
    digest = hashlib.sha256()
    for path in files:
        digest.update(path.read_bytes())
    release_id = digest.hexdigest()[:16]
    html, release_count = re.subn(
        r"const releaseVersion = '[^']+';",
        f"const releaseVersion = '{release_id}';",
        html,
    )
    if release_count != 1:
        raise RuntimeError("Could not update exactly one releaseVersion")
    html, overlay_count = re.subn(
        r"unified_workspaces\.js\?v=[^\"]+",
        f"unified_workspaces.js?v={release_id}",
        html,
    )
    if overlay_count != 1:
        raise RuntimeError("Could not update the workspace overlay version")
    index.write_text(html)
    print(f"patched_files={changed} referenced_chunks={len(chunk_names)} release={release_id}")
    for old, count in counts.items():
        print(f"{count:3} {old}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("release_dir", type=Path)
    patch(parser.parse_args().release_dir)
