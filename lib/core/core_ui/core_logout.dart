import 'package:flutter/material.dart';

import 'core_routes.dart';

void logoutToLogin(BuildContext context) {
  Navigator.of(context).pushNamedAndRemoveUntil(
    CoreRoutes.login,
    (route) => false,
  );
}
