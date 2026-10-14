import 'package:flutter/material.dart';

import '../../auth/auth_controller.dart';
import 'runtime_status_screen.dart';
import '../core_back_navigation.dart';
import '../core_routes.dart';
import '../widgets/core_widgets.dart';

class CoreErrorScreen extends StatelessWidget {
  final String title;
  final String message;

  const CoreErrorScreen({
    super.key,
    this.title = 'Something went wrong',
    this.message = 'We could not load this CineConnect view. Please try again.',
  });

  @override
  Widget build(BuildContext context) {
    return CoreScreenScaffold(
      centerContent: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CoreEmptyState(
            icon: Icons.error_outline_rounded,
            title: title,
            message: message,
            actionLabel: 'Retry',
            onAction: () {
              final route = ModalRoute.of(context)?.settings.name;
              if (route != null) {
                Navigator.pushReplacementNamed(context, route);
              } else {
                navigateCoreBack(context);
              }
            },
          ),
          const SizedBox(height: 12),
          CoreSecondaryButton(
            icon: Icons.arrow_back_rounded,
            label: 'Go back',
            onTap: () => navigateCoreBack(context),
          ),
        ],
      ),
    );
  }
}

class CoreEmptyTemplateScreen extends StatelessWidget {
  const CoreEmptyTemplateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CoreScreenScaffold(
      centerContent: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CoreEmptyState(
            icon: Icons.inbox_outlined,
            title: 'No payments yet',
            message:
                'Verified receipts and pending proof submissions will appear here.',
            actionLabel: 'Explore Marketplace',
            onAction: () => Navigator.pushNamed(context, CoreRoutes.dashboard),
          ),
        ],
      ),
    );
  }
}

class NoInternetScreen extends StatefulWidget {
  const NoInternetScreen({super.key});

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen> {
  bool _checking = false;

  Future<void> _retry() async {
    if (_checking) return;
    final auth = AuthScope.maybeOf(context);
    if (auth == null) return;
    setState(() => _checking = true);
    try {
      await auth.apiClient.get('/health/live');
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        auth.isAuthenticated
            ? auth.initialAuthenticatedRoute
            : CoreRoutes.login,
        (route) => false,
      );
    } catch (_) {
      if (mounted) {
        showCoreSnack(
            context, 'CineConnect is still unreachable. Try again shortly.');
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CoreScreenScaffold(
      centerContent: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CoreEmptyState(
            icon: Icons.wifi_off_rounded,
            title: 'No Internet Connection',
            message:
                'Please check your connection and try again. Offline mode keeps saved records visible.',
          ),
          const SizedBox(height: 12),
          CorePrimaryButton(
            icon: Icons.refresh_rounded,
            label: _checking ? 'Checking...' : 'Retry',
            onTap: _checking ? null : _retry,
          ),
        ],
      ),
    );
  }
}

class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const RuntimeStatusScreen(maintenance: false);
}

class MaintenanceModeScreen extends StatelessWidget {
  const MaintenanceModeScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const RuntimeStatusScreen(maintenance: true);
}
