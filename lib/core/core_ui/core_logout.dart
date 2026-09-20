import 'package:flutter/material.dart';

import '../auth/auth_controller.dart';
import 'core_routes.dart';

Future<void> logoutToLogin(BuildContext context) async {
  final auth = AuthScope.maybeOf(context);
  try {
    await auth?.logout();
  } catch (_) {
    // Local session state is cleared even if server-side revocation fails.
  }
  if (!context.mounted) return;
  Navigator.of(context).pushNamedAndRemoveUntil(
    CoreRoutes.login,
    (route) => false,
  );
}
