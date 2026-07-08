import 'package:flutter/material.dart';

import '../../theme/app_color_scheme.dart';
import '../../theme/app_text_styles.dart';
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
      child: Column(
        children: [
          CoreEmptyState(
            icon: Icons.error_outline_rounded,
            title: title,
            message: message,
            actionLabel: 'Retry',
            onAction: () => showCoreSnack(context, 'Retrying static state'),
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
      child: Column(
        children: [
          const CoreAppHeader(
            title: 'Empty State Template',
            subtitle:
                'Reusable no-data surface for contracts, chats, payments and search.',
            icon: Icons.inbox_outlined,
          ),
          const SizedBox(height: 20),
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

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CoreScreenScaffold(
      child: Column(
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
            label: 'Retry',
            onTap: () => showCoreSnack(context, 'Connection check simulated'),
          ),
        ],
      ),
    );
  }
}

class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return CoreScreenScaffold(
      child: Column(
        children: [
          const CoreEmptyState(
            icon: Icons.system_update_alt_rounded,
            title: 'Update Required',
            message: 'A newer version of CineConnect is required to continue.',
          ),
          const SizedBox(height: 16),
          CoreGlassCard(
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: colors.goldDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Current v1.0.0 · Required v1.1.0',
                    style:
                        AppTextStyles.label.copyWith(color: colors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CorePrimaryButton(
            icon: Icons.open_in_new_rounded,
            label: 'Update App',
            onTap: () => showCoreSnack(context, 'App store redirect simulated'),
          ),
        ],
      ),
    );
  }
}

class MaintenanceModeScreen extends StatelessWidget {
  const MaintenanceModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return CoreScreenScaffold(
      child: Column(
        children: [
          const CoreEmptyState(
            icon: Icons.construction_rounded,
            title: 'CineConnect is Under Maintenance',
            message:
                'We are improving your production experience. Please check back soon.',
          ),
          const SizedBox(height: 16),
          CoreGlassCard(
            child: Row(
              children: [
                Icon(Icons.schedule_rounded, color: colors.goldDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Estimated return: Today, 8:30 PM PKT',
                    style:
                        AppTextStyles.label.copyWith(color: colors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CoreSecondaryButton(
            icon: Icons.support_agent_outlined,
            label: 'Contact support',
            onTap: () =>
                showCoreSnack(context, 'Support contact panel simulated'),
          ),
        ],
      ),
    );
  }
}
