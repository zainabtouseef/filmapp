from __future__ import annotations

from app.errors import APIError
from app.models.identity import User


def has_permission(user: User, permission_code: str) -> bool:
    for user_role in user.roles:
        if user_role.status != "active":
            continue
        if any(
            role_permission.permission.code == permission_code
            for role_permission in user_role.role.permissions
        ):
            return True
    return False


def require_permission(user: User, permission_code: str) -> None:
    if not has_permission(user, permission_code):
        raise APIError(
            "auth.permission_denied",
            "You do not have permission to perform this action.",
            status=403,
        )
