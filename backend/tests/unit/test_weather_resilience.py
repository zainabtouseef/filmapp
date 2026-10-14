"""Weather must identify provider failures and cache only the actual observation."""

import json
from io import BytesIO
from unittest.mock import patch

import pytest

from app.services import weather


@pytest.fixture(autouse=True)
def empty_weather_cache():
    weather._cache.clear()
    yield
    weather._cache.clear()


def test_weather_uses_provider_coordinates_and_returns_cached_copy(app):
    app.config["WEATHER_ENABLED"] = True
    responses = [
        {"results": [{"latitude": 31.5, "longitude": 74.3, "name": "Lahore"}]},
        {
            "current": {
                "temperature_2m": 29.3,
                "wind_speed_10m": 8.1,
                "weather_code": 61,
                "time": "2026-10-14T10:00",
            }
        },
    ]
    with (
        app.app_context(),
        patch.object(weather, "_json_get", side_effect=responses) as fetch,
    ):
        first = weather.weather_for_location("Lahore")
        assert first["status"] == "live" and first["provider"] == "Open-Meteo"
        assert first["summary"] == "Light rain in Lahore · 29°C · wind 8 km/h"
        assert "latitude=31.5" in fetch.call_args_list[1].args[0]
        first["summary"] = "mutated by caller"
        cached = weather.weather_for_location(" lahore ")
        assert cached["summary"] != first["summary"] and fetch.call_count == 2


@pytest.mark.parametrize("payload", [{}, {"results": []}, {"results": ["invalid"]}])
def test_weather_missing_location_is_explicit(app, payload):
    app.config["WEATHER_ENABLED"] = True
    with app.app_context(), patch.object(weather, "_json_get", return_value=payload):
        assert weather.weather_for_location("Unknown")["status"] == "location_not_found"


@pytest.mark.parametrize(
    "responses",
    [
        [{"results": [{"latitude": None, "longitude": 1}]}],
        [{"results": [{"latitude": 1, "longitude": 2}]}, {}],
        [{"results": [{"latitude": 1, "longitude": 2}]}, {"current": {}}],
    ],
)
def test_weather_malformed_provider_data_never_claims_live(app, responses):
    app.config["WEATHER_ENABLED"] = True
    with app.app_context(), patch.object(weather, "_json_get", side_effect=responses):
        assert (
            weather.weather_for_location("Unknown")["status"]
            == "temporarily_unavailable"
        )


@pytest.mark.parametrize("error", [TimeoutError(), OSError(), ValueError()])
def test_weather_outage_can_recover_after_cache_expiry(app, error):
    app.config["WEATHER_ENABLED"] = True
    with app.app_context(), patch.object(weather, "_live_weather", side_effect=error):
        assert (
            weather.weather_for_location("Lahore")["status"]
            == "temporarily_unavailable"
        )
    with (
        app.app_context(),
        patch.object(weather.time, "monotonic", return_value=10**15),
        patch.object(
            weather,
            "_live_weather",
            return_value={"status": "live", "summary": "Recovered"},
        ),
    ):
        assert weather.weather_for_location("Lahore")["status"] == "live"


def test_disabled_weather_and_missing_city_do_not_make_requests(app):
    with app.app_context(), patch.object(weather, "_json_get") as fetch:
        assert weather.weather_for_location(None)["status"] == "location_required"
        app.config["WEATHER_ENABLED"] = False
        assert weather.weather_for_location("Lahore")["status"] == "provider_disabled"
        fetch.assert_not_called()


@pytest.mark.parametrize("payload", [{"current": {}}, []])
def test_json_transport_validates_provider_shape(payload):
    with patch.object(
        weather, "urlopen", return_value=BytesIO(json.dumps(payload).encode())
    ) as fetch:
        if isinstance(payload, dict):
            assert (
                weather._json_get("https://weather.example.test", timeout=1) == payload
            )
        else:
            with pytest.raises(ValueError):
                weather._json_get("https://weather.example.test", timeout=1)
        assert fetch.call_args.kwargs["timeout"] == 1
