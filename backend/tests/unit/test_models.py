from datetime import UTC

from app.models.base import EntityMixin, utc_now


def test_utc_now_is_timezone_aware() -> None:
    value = utc_now()

    assert value.tzinfo is UTC


def test_entity_mixin_exposes_required_columns() -> None:
    annotations = EntityMixin.__annotations__

    assert set(annotations) == {
        "id",
        "created_at",
        "updated_at",
        "deleted_at",
        "version",
    }
