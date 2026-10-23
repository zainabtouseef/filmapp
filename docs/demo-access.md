# Demo account access

The separate Flutter route `/#/demo-access?key=<capability>` lists database
accounts under their active roles and signs in with the selected existing role.
It has no link from the normal login page or application navigation.

This feature permits anyone with the private link to use all active accounts,
including staff accounts. Enable it only on a site explicitly intended for this
demo behavior. Normal password login remains available.

## Configuration

- `DEMO_ACCOUNT_PICKER_ENABLED` defaults to `false`.
- `DEMO_ACCOUNT_PICKER_KEY` is a cryptographically random secret of at least
  64 characters. Generate it with `secrets.token_urlsafe(48)` and store it only
  in the server's protected environment file.
- Share the complete fragment URL above. Do not include the capability in
  Flutter build arguments, source files, a query before `#`, or public docs.

Both `POST /api/v1/auth/demo/accounts` and `POST /api/v1/auth/demo/login`
require `access_key` in a JSON body. Invalid or disabled access returns 404.
Responses are not cached; the directory also specifies `noindex`.
The login body additionally requires `user_id` and `role_code`.

The directory includes all accounts. Suspended accounts, inactive assignments,
and accounts without an active role cannot log in. A user with multiple active
roles appears in each applicable category. Selecting a role updates the user's
primary role and issues the regular access/refresh token pair. Passwords are
not changed. Successful demo logins create a `demo_login` security event without
recording the private capability. The normal refresh/logout lifecycle applies.

Rotate the capability and restart API workers to invalidate shared links.
Set the feature flag to `false` to close the picker. Disabling or rotating the
link does not revoke sessions already issued; revoke those separately through
the existing session controls if needed.
