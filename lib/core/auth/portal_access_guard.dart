import 'package:flutter/material.dart';

import 'auth_controller.dart';
import 'role_mapper.dart';

/// Frontend privacy gate. Backend authorization remains the security boundary.
class PortalAccessGuard extends StatelessWidget {
  final String routeName;
  final Widget child;

  const PortalAccessGuard({
    super.key,
    required this.routeName,
    required this.child,
  });

  static const _portals = {
    'director',
    'talent',
    'model',
    'influencer',
    'public',
    'crew',
    'equipment-provider',
    'location-owner',
    'agency',
    'brand',
    'legal',
    'insurance',
    'distribution',
    'admin',
  };

  // Shared private screens are available to any active signed-in account;
  // resource ownership and operation permissions are enforced by the API.
  static const _accountScreens = {
    'verification',
    'profile',
    'notifications',
    'booking',
    'contract',
    'payment',
    'payments',
    'review',
    'report',
    'settings',
    'portal',
  };

  @override
  Widget build(BuildContext context) {
    final rawSegment = Uri.tryParse(routeName)?.pathSegments.firstOrNull;
    final segment = rawSegment == 'console' || rawSegment == 'project'
        ? 'director'
        : rawSegment;
    final sharedAccountScreen = _accountScreens.contains(segment);
    if (!_portals.contains(segment) && !sharedAccountScreen) return child;
    final auth = AuthScope.maybeOf(context);
    // Isolated component previews have no session scope.
    if (auth == null) return child;
    if (!auth.ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final allowed = auth.isAuthenticated &&
        auth.user?.status == 'active' &&
        (sharedAccountScreen ||
            (auth.user?.roles.any((role) =>
                    role.status == 'active' &&
                    Uri.tryParse(RoleMapper.portalRouteForCode(role.code) ??
                                role.portalRoute)
                            ?.pathSegments
                            .firstOrNull ==
                        segment) ??
                false));
    if (allowed) return child;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.lock_outline, size: 32),
            const SizedBox(height: 16),
            Text(auth.isAuthenticated
                ? 'This workspace requires an active authorized role.'
                : 'Sign in to access this workspace.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  auth.isAuthenticated ? '/roles' : '/login', (_) => false),
              child: Text(
                  auth.isAuthenticated ? 'Choose your workspace' : 'Sign in'),
            ),
          ]),
        ),
      ),
    );
  }
}
