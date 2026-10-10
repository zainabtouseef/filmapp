import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/director/director_dashboard_models.dart';
import '../../../core/network/api_exception.dart';
import '../widgets/dashboard/dp_dashboard_v3.dart';
import '../widgets/dashboard/dp_dashboard_v3_theme.dart';

class DPHomeDashboardScreen extends StatefulWidget {
  const DPHomeDashboardScreen({super.key});

  @override
  State<DPHomeDashboardScreen> createState() => _DPHomeDashboardScreenState();
}

class _DPHomeDashboardScreenState extends State<DPHomeDashboardScreen> {
  Future<DirectorDashboard>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<DirectorDashboard> _load() async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null || !auth.isAuthenticated) {
      throw const ApiException(
        code: 'auth.required',
        message: 'Sign in to load the live Director dashboard.',
      );
    }
    return auth.directorDashboard();
  }

  void _retry() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DirectorDashboard>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _DashboardLoadingState();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          final message = snapshot.error is ApiException
              ? (snapshot.error! as ApiException).message
              : 'Could not load the live Director dashboard.';
          return _DashboardErrorState(message: message, onRetry: _retry);
        }
        return DPV3Dashboard(dashboard: snapshot.data!);
      },
    );
  }
}

class _DashboardLoadingState extends StatelessWidget {
  const _DashboardLoadingState();

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: p.line),
        boxShadow: p.softShadow,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: p.goldFill,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Loading live Director dashboard…',
              style: dpV3Sans(13, p, color: p.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DashboardErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final p = DPV3Palette.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: p.line),
        boxShadow: p.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live dashboard unavailable',
            style: dpV3Sans(18, p, weight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(message, style: dpV3Sans(12.5, p, color: p.muted)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
