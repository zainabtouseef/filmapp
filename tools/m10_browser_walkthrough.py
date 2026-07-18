#!/usr/bin/env python3
"""Headless Chrome route walkthrough for CineConnect Flutter web.

This is a lightweight CDP client that avoids extra npm/python dependencies.
It serves as an evidence collector for M10: navigate important Flutter routes,
capture screenshots, and record browser/runtime errors.
"""

from __future__ import annotations

import base64
import json
import shutil
import subprocess
import time
import urllib.request
from pathlib import Path
from typing import Any

import websocket


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "docs" / "m10_walkthrough_screenshots"
REPORT_PATH = ROOT / "docs" / "M10_BROWSER_WALKTHROUGH_RESULTS.json"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
APP_URL = "http://127.0.0.1:53117"
DEBUG_PORT = 9226


ROUTES = [
    "/",
    "/login",
    "/roles",
    "/notifications",
    "/portal/dashboard",
    "/director",
    "/director/projects",
    "/director/marketplace",
    "/director/shortlist",
    "/director/bargaining",
    "/director/contracts",
    "/director/payments",
    "/director/room",
    "/director/reports",
    "/talent",
    "/talent/profile",
    "/talent/portfolio",
    "/talent/availability",
    "/talent/rates",
    "/talent/opportunities",
    "/talent/contracts",
    "/talent/earnings",
    "/talent/reputation",
    "/talent/safety",
    "/model",
    "/model/usage-rights",
    "/model/rate-by-usage",
    "/model/brand-safety",
    "/location-owner",
    "/location-owner/listing-wizard",
    "/location-owner/pricing",
    "/location-owner/rules",
    "/location-owner/check-in",
    "/location-owner/check-out",
    "/equipment-provider",
    "/equipment-provider/profile",
    "/equipment-provider/inventory",
    "/equipment-provider/packages",
    "/equipment-provider/terms",
    "/equipment-provider/handover",
    "/equipment-provider/return",
    "/crew",
    "/crew/profile",
    "/crew/availability",
    "/crew/requests",
    "/crew/contracts-payments",
    "/agency",
    "/agency/roster",
    "/agency/auditions",
    "/agency/self-tapes",
    "/agency/commission",
    "/brand",
    "/brand/profile",
    "/brand/opportunity-composer",
    "/brand/applications",
    "/brand/campaign-tracker",
    "/brand/payments",
    "/legal",
    "/legal/contract-review",
    "/legal/addendum-review",
    "/legal/history-billing",
    "/insurance",
    "/insurance/records",
    "/insurance/claims",
    "/insurance/safety-permits",
    "/insurance/incidents",
    "/distribution",
    "/distribution/contacts",
    "/distribution/release",
    "/distribution/reports",
    "/admin/dashboard",
    "/admin/review-hub",
    "/admin/verifications",
    "/admin/content-moderation",
    "/admin/bookings-monitor",
    "/admin/payments",
    "/admin/payment-queue",
    "/admin/payments/ledger",
    "/admin/disputes",
    "/admin/support",
    "/admin/broadcasts",
    "/admin/analytics",
]


def safe_route_name(route: str) -> str:
    return route.strip("/").replace("/", "_").replace(":", "_") or "root"


def page_target(debug_port: int) -> dict[str, Any]:
    for _ in range(80):
        try:
            with urllib.request.urlopen(
                f"http://127.0.0.1:{debug_port}/json/list", timeout=1
            ) as response:
                targets = json.loads(response.read())
            pages = [
                target
                for target in targets
                if target.get("type") == "page" and target.get("webSocketDebuggerUrl")
            ]
            if pages:
                return pages[0]
        except Exception:
            pass
        time.sleep(0.25)
    raise RuntimeError("Chrome page target did not start")


def main() -> None:
    if OUT_DIR.exists():
        shutil.rmtree(OUT_DIR)
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    chrome = subprocess.Popen(
        [
            CHROME,
            "--headless=new",
            f"--remote-debugging-port={DEBUG_PORT}",
            "--remote-allow-origins=*",
            "--user-data-dir=/tmp/cineconnect-m10-chrome-profile",
            "--disable-gpu",
            "--no-first-run",
            "--no-default-browser-check",
            "--window-size=390,844",
            f"{APP_URL}/#/login",
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    ws = None
    try:
        target = page_target(DEBUG_PORT)
        ws = websocket.create_connection(
            target["webSocketDebuggerUrl"],
            timeout=10,
            origin=f"http://127.0.0.1:{DEBUG_PORT}",
        )
        seq = 0
        events: list[dict[str, Any]] = []

        def send(method: str, params: dict[str, Any] | None = None) -> dict[str, Any]:
            nonlocal seq
            seq += 1
            message: dict[str, Any] = {"id": seq, "method": method}
            if params is not None:
                message["params"] = params
            ws.send(json.dumps(message))
            while True:
                data = json.loads(ws.recv())
                if data.get("method") in {
                    "Runtime.exceptionThrown",
                    "Log.entryAdded",
                    "Page.javascriptDialogOpening",
                    "Console.messageAdded",
                }:
                    events.append(data)
                if data.get("id") == seq:
                    return data

        for method in ["Page.enable", "Runtime.enable", "Log.enable"]:
            send(method)

        results: list[dict[str, Any]] = []
        for index, route in enumerate(ROUTES, start=1):
            before = len(events)
            route_errors: list[str] = []
            url = f"{APP_URL}/#{route}" if route != "/" else f"{APP_URL}/#/"

            nav = send("Page.navigate", {"url": url})
            if "error" in nav:
                route_errors.append("navigate: " + json.dumps(nav["error"]))

            time.sleep(1.35)

            value: dict[str, Any] = {}
            expression = (
                "({"
                "href: location.href,"
                "title: document.title,"
                "bodyText: document.body ? document.body.innerText.slice(0,1200) : '',"
                "canvasCount: document.querySelectorAll('canvas').length,"
                "semantics: !!document.querySelector('flt-semantics-host'),"
                "htmlLength: document.documentElement.outerHTML.length"
                "})"
            )
            evaluated = send(
                "Runtime.evaluate",
                {"expression": expression, "returnByValue": True},
            )
            try:
                value = evaluated["result"]["result"].get("value", {}) or {}
            except Exception:
                route_errors.append(
                    "evaluate: " + json.dumps(evaluated.get("error", evaluated))[:300]
                )

            screenshot_path = None
            screenshot = send(
                "Page.captureScreenshot",
                {"format": "png", "captureBeyondViewport": False},
            )
            if "result" in screenshot and "data" in screenshot["result"]:
                screenshot_path = OUT_DIR / f"{index:03}_{safe_route_name(route)}.png"
                screenshot_path.write_bytes(base64.b64decode(screenshot["result"]["data"]))
            else:
                route_errors.append(
                    "screenshot: "
                    + json.dumps(screenshot.get("error", screenshot))[:300]
                )

            serious: list[str] = []
            for event in events[before:]:
                if event.get("method") == "Runtime.exceptionThrown":
                    detail = event.get("params", {}).get("exceptionDetails", {})
                    serious.append(
                        "exception: "
                        + str(
                            detail.get("text")
                            or detail.get("exception", {}).get("description", "")
                        )[:220]
                    )
                elif event.get("method") == "Log.entryAdded":
                    entry = event.get("params", {}).get("entry", {})
                    text = entry.get("text", "")
                    if (
                        entry.get("level") == "error"
                        and "Failed to load resource" not in text
                        and "404" not in text
                    ):
                        serious.append(f"{entry.get('level')}: {text[:220]}")

            results.append(
                {
                    "route": route,
                    "href": value.get("href"),
                    "title": value.get("title"),
                    "canvas_count": value.get("canvasCount"),
                    "semantics": value.get("semantics"),
                    "html_length": value.get("htmlLength"),
                    "screenshot": str(screenshot_path.relative_to(ROOT))
                    if screenshot_path
                    else None,
                    "events": serious + route_errors,
                }
            )

        report = {
            "generated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "routes_checked": len(ROUTES),
            "screenshots_dir": str(OUT_DIR.relative_to(ROOT)),
            "results": results,
        }
        REPORT_PATH.write_text(json.dumps(report, indent=2))
        failures = [result for result in results if result["events"]]
        print(
            json.dumps(
                {
                    "routes_checked": len(ROUTES),
                    "screenshots_dir": str(OUT_DIR.relative_to(ROOT)),
                    "screenshots": len(list(OUT_DIR.glob("*.png"))),
                    "event_routes": len(failures),
                    "report": str(REPORT_PATH.relative_to(ROOT)),
                },
                indent=2,
            )
        )
        if failures:
            print(json.dumps(failures[:12], indent=2)[:7000])
    finally:
        if ws is not None:
            try:
                ws.close()
            except Exception:
                pass
        chrome.terminate()
        try:
            chrome.wait(timeout=5)
        except Exception:
            chrome.kill()


if __name__ == "__main__":
    main()
