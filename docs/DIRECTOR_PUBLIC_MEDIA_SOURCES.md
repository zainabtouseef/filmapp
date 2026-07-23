# Director Portal Public Demo Media Sources

Generated: 2026-07-22  
Seed script: `backend/scripts/seed_director_public_media.py`  
Purpose: attach Pakistan-relevant public images to demo Director projects and marketplace listings through real backend `FileAsset` rows.

## Selection principles

- Use stable Wikimedia-hosted images reachable through public URLs.
- Prefer places/landmarks/landscapes over recognizable private individuals, so the demo does not imply a real person is a CineConnect user.
- Store downloaded bytes in CineConnect public storage and expose them only through backend `public_url`.
- Keep images traceable to source pages for later attribution/licensing review.

## Seeded assets

| Project | Listing | Image theme | Source page | Why this image |
|---|---|---|---|---|
| `DEMO-PROJ-001` River Lights | `DEMO-LST-AT-001` | Lahore Fort | https://en.wikipedia.org/wiki/Lahore_Fort | Historic Lahore production mood |
| `DEMO-PROJ-002` City of Dust | `DEMO-LST-AT-002` | Clifton Karachi | https://en.wikipedia.org/wiki/Karachi | Urban Karachi skyline |
| `DEMO-PROJ-003` Blue Van | `DEMO-LST-AT-003` | Faisal Mosque | https://en.wikipedia.org/wiki/Faisal_Mosque | Clean Islamabad landmark |
| `DEMO-PROJ-004` Eid Run | `DEMO-LST-AT-004` | Badshahi Mosque | https://en.wikipedia.org/wiki/Badshahi_Mosque | Recognizable Lahore heritage |
| `DEMO-PROJ-005` Salt Road | `DEMO-LST-AT-005` | Gwadar coast | https://en.wikipedia.org/wiki/Gwadar | Coastal Balochistan context |
| `DEMO-PROJ-006` Campus Beat | `DEMO-LST-AT-006` | Mazar-e-Quaid | https://en.wikipedia.org/wiki/Mazar-e-Quaid | Karachi civic landmark |
| `DEMO-PROJ-007` Night Bazaar | `DEMO-LST-AT-007` | Rawalpindi railway station | https://en.wikipedia.org/wiki/Rawalpindi | Rawalpindi movement/transport cue |
| `DEMO-PROJ-008` Monsoon Menu | `DEMO-LST-AT-008` | Noor Mahal | https://en.wikipedia.org/wiki/Noor_Mahal | Elegant palace/campaign feel |
| `DEMO-PROJ-009` Safe Set PSA | `DEMO-LST-AT-009` | Hunza Valley | https://en.wikipedia.org/wiki/Hunza_Valley | Northern Pakistan mountain context |
| `DEMO-PROJ-010` Desert Echo | `DEMO-LST-AT-010` | Derawar Fort | https://en.wikipedia.org/wiki/Derawar_Fort | Bahawalpur desert scale |

## Follow-up required

Before commercial production launch, review each Wikimedia file page and store final attribution/license text in a dedicated legal/credits location if the app publicly displays these images beyond internal demo usage.
