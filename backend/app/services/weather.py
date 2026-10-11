from __future__ import annotations

import json
import threading
import time
from typing import Any, cast
from urllib.parse import urlencode
from urllib.request import Request, urlopen

from flask import current_app

_CACHE_TTL_SECONDS = 900
_cache: dict[str, tuple[float, dict[str, str]]] = {}
_cache_lock = threading.Lock()

_WEATHER_LABELS = {
    0: "Clear sky",
    1: "Mostly clear",
    2: "Partly cloudy",
    3: "Overcast",
    45: "Fog",
    48: "Rime fog",
    51: "Light drizzle",
    53: "Drizzle",
    55: "Heavy drizzle",
    56: "Light freezing drizzle",
    57: "Freezing drizzle",
    61: "Light rain",
    63: "Rain",
    65: "Heavy rain",
    66: "Light freezing rain",
    67: "Freezing rain",
    71: "Light snow",
    73: "Snow",
    75: "Heavy snow",
    77: "Snow grains",
    80: "Light rain showers",
    81: "Rain showers",
    82: "Heavy rain showers",
    85: "Light snow showers",
    86: "Heavy snow showers",
    95: "Thunderstorms",
    96: "Thunderstorms with light hail",
    99: "Thunderstorms with hail",
}


def _json_get(url: str, *, timeout: float) -> dict[str, Any]:
    request = Request(
        url,
        headers={
            "Accept": "application/json",
            "User-Agent": "CineConnect/1.0 (cine.nalexustechnologies.com)",
        },
    )
    with urlopen(request, timeout=timeout) as response:
        payload = json.loads(response.read().decode("utf-8"))
    if not isinstance(payload, dict):
        raise ValueError("Weather provider returned an invalid response")
    return cast(dict[str, Any], payload)


def _live_weather(location: str) -> dict[str, str]:
    timeout = float(current_app.config.get("WEATHER_TIMEOUT_SECONDS", 3.0))
    geocoding_url = str(current_app.config["WEATHER_GEOCODING_URL"])
    forecast_url = str(current_app.config["WEATHER_FORECAST_URL"])
    geocoding_query = urlencode(
        {"name": location, "count": 1, "language": "en", "format": "json"}
    )
    location_payload = _json_get(f"{geocoding_url}?{geocoding_query}", timeout=timeout)
    results = location_payload.get("results")
    if not isinstance(results, list) or not results or not isinstance(results[0], dict):
        return {
            "status": "location_not_found",
            "summary": f"No weather station was found for {location}.",
        }

    match = cast(dict[str, Any], results[0])
    latitude = match.get("latitude")
    longitude = match.get("longitude")
    if not isinstance(latitude, (int, float)) or not isinstance(
        longitude, (int, float)
    ):
        raise ValueError("Weather provider omitted location coordinates")

    forecast_query = urlencode(
        {
            "latitude": latitude,
            "longitude": longitude,
            "current": "temperature_2m,weather_code,wind_speed_10m",
            "timezone": "auto",
        }
    )
    weather_payload = _json_get(f"{forecast_url}?{forecast_query}", timeout=timeout)
    current = weather_payload.get("current")
    if not isinstance(current, dict):
        raise ValueError("Weather provider omitted current conditions")
    temperature = current.get("temperature_2m")
    wind_speed = current.get("wind_speed_10m")
    code = current.get("weather_code")
    if not isinstance(temperature, (int, float)) or not isinstance(
        wind_speed, (int, float)
    ):
        raise ValueError("Weather provider returned incomplete conditions")

    place = str(match.get("name") or location)
    condition = (
        _WEATHER_LABELS.get(int(code), "Current conditions")
        if code is not None
        else "Current conditions"
    )
    return {
        "status": "live",
        "summary": (
            f"{condition} in {place} · {temperature:.0f}°C · wind {wind_speed:.0f} km/h"
        ),
        "provider": "Open-Meteo",
        "observed_at": str(current.get("time") or ""),
    }


def weather_for_location(location: str | None) -> dict[str, str]:
    if not location:
        return {
            "status": "location_required",
            "summary": "Add a project city to show live weather.",
        }
    if not current_app.config.get("WEATHER_ENABLED", True):
        return {
            "status": "provider_disabled",
            "summary": "Live weather is disabled in this environment.",
        }

    cache_key = location.strip().casefold()
    now = time.monotonic()
    with _cache_lock:
        cached = _cache.get(cache_key)
        if cached and cached[0] > now:
            return dict(cached[1])

    try:
        result = _live_weather(location.strip())
    except (OSError, TimeoutError, ValueError, json.JSONDecodeError):
        result = {
            "status": "temporarily_unavailable",
            "summary": "Live weather is temporarily unavailable.",
        }

    with _cache_lock:
        _cache[cache_key] = (now + _CACHE_TTL_SECONDS, result)
    return dict(result)
