from unittest.mock import patch

import pytest

from app.api.director import _with_listing
from app.api.marketplace import _pricing_payload
from app.models.marketplace import MarketplaceListing
from app.services.marketplace_categories import crew_categories, equipment_categories


@pytest.mark.parametrize("listing_type", ["talent", "actor", "model", "influencer"])
@pytest.mark.parametrize("mode", ["fixed", "negotiable", "on_request"])
def test_talent_prices_are_private_for_every_public_pricing_mode(
    listing_type: str, mode: str
) -> None:
    listing = MarketplaceListing(
        listing_type=listing_type,
        pricing_mode=mode,
        price_from_minor=18000000,
        currency="PKR",
    )
    public = _pricing_payload(listing)
    assert public["shows_price"] is False
    assert public["price_from_minor"] is None
    assert "configured_price_from_minor" not in public
    assert public["price_label"] == "Open to offers"
    owned = _pricing_payload(listing, reveal_private_price=True)
    assert owned["configured_price_from_minor"] == 18000000
    assert listing.price_from_minor == 18000000


def test_equipment_public_prices_are_preserved() -> None:
    listing = MarketplaceListing(
        listing_type="equipment",
        pricing_mode="fixed",
        price_from_minor=2000000,
        currency="PKR",
    )
    public = _pricing_payload(listing)
    assert public["shows_price"] is True
    assert public["price_from_minor"] == 2000000


@pytest.mark.parametrize("listing_type", ["actor", "model", "influencer"])
def test_talent_can_opt_in_to_public_price(listing_type: str) -> None:
    listing = MarketplaceListing(
        listing_type=listing_type,
        pricing_mode="negotiable",
        public_price_visible=True,
        price_from_minor=18000000,
        currency="PKR",
    )
    public = _pricing_payload(listing)
    assert public["shows_price"] is True
    assert public["price_from_minor"] == 18000000


def test_discovery_does_not_leak_rates_through_media_kit() -> None:
    listing = MarketplaceListing(
        public_id="LST-PRIVATE",
        listing_type="model",
        pricing_mode="fixed",
        price_from_minor=18000000,
        currency="PKR",
        verification_status="approved",
    )
    with patch("app.api.director._listing_for_profile", return_value=listing):
        payload = _with_listing({"media_kit": {}}, "model", "MOD-1")
    assert payload["rate_from_minor"] is None
    assert payload["shows_price"] is False
    assert payload["media_kit"]["rate_cards"][0]["price_label"] == "Open to offers"


def test_equipment_groups_map_real_inventory_and_retain_other_services() -> None:
    assert equipment_categories(["Camera", "lenses", "Light", "Audio", "Grip"]) == [
        "Cameras",
        "Lighting Equipment",
        "Audio",
        "Grip",
    ]
    assert equipment_categories([]) == []


def test_dop_and_existing_crew_roles_are_discoverable() -> None:
    assert crew_categories("DOP services", "Director of Photography") == ["DOP"]
    assert crew_categories("Sound recordist", "Boom operator") == ["Sound"]
    assert crew_categories("Production crew", "") == ["General Crew"]
