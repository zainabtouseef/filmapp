from app.api.specialist import _brand_payment_schedule_payload


def test_brand_payment_schedule_normalizes_legacy_object() -> None:
    assert _brand_payment_schedule_payload('{"advance": 50, "delivery": 50}') == [
        {"key": "advance", "percent": 50},
        {"key": "delivery", "percent": 50},
    ]


def test_brand_payment_schedule_keeps_current_milestone_list() -> None:
    schedule = '[{"key": "advance", "percent": 40}]'
    assert _brand_payment_schedule_payload(schedule) == [
        {"key": "advance", "percent": 40}
    ]


def test_brand_payment_schedule_handles_invalid_legacy_data() -> None:
    assert _brand_payment_schedule_payload("not-json") == []
