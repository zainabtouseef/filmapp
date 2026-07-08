import 'package:flutter/material.dart';

import 'core_routes.dart';

void navigateCoreBack(BuildContext context) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop();
    return;
  }

  final currentRoute = ModalRoute.of(context)?.settings.name;
  final fallbackRoute = _fallbackRouteFor(currentRoute);
  if (fallbackRoute == null || fallbackRoute == currentRoute) return;

  navigator.pushReplacementNamed(fallbackRoute);
}

String? _fallbackRouteFor(String? currentRoute) {
  if (currentRoute?.startsWith('/admin/') ?? false) {
    return CoreRoutes.login;
  }

  return switch (currentRoute) {
    CoreRoutes.splash => CoreRoutes.onboarding,
    CoreRoutes.onboarding => CoreRoutes.login,
    CoreRoutes.roleSelection => CoreRoutes.onboarding,
    CoreRoutes.login => CoreRoutes.roleSelection,
    CoreRoutes.signup => CoreRoutes.roleSelection,
    CoreRoutes.forgotPassword => CoreRoutes.login,
    CoreRoutes.kyc => CoreRoutes.roleSelection,
    CoreRoutes.verificationStatus => CoreRoutes.kyc,
    CoreRoutes.dashboard => CoreRoutes.login,
    CoreRoutes.forceUpdate ||
    CoreRoutes.maintenance ||
    CoreRoutes.noInternet ||
    CoreRoutes.error ||
    CoreRoutes.empty =>
      CoreRoutes.onboarding,
    CoreRoutes.notifications ||
    CoreRoutes.profileRoles ||
    CoreRoutes.chat ||
    CoreRoutes.contract ||
    CoreRoutes.paymentProof ||
    CoreRoutes.ledger ||
    CoreRoutes.review ||
    CoreRoutes.report ||
    CoreRoutes.settings =>
      CoreRoutes.dashboard,
    _ => CoreRoutes.dashboard,
  };
}
