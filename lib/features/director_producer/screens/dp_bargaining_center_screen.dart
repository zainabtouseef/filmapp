import 'package:flutter/material.dart';

import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/projects/projects_controller.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_bargaining_v3.dart';
import 'dp_negotiation_thread_screen.dart';

/// Presents the full negotiation thread (rounds, counter-offer form,
/// accept, chat) as a tall bottom sheet instead of a page navigation.
void openNegotiationSheet(BuildContext context, String? negotiationId) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  final card = dark ? const Color(0xFF131316) : Colors.white;
  final border = dark
      ? Colors.white.withValues(alpha: .10)
      : const Color(0xFF17150E).withValues(alpha: .10);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: dark ? .64 : .38),
    builder: (sheetContext) => DraggableScrollableSheet(
      initialChildSize: 0.90,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .26),
              blurRadius: 60,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: border,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
                child: DPNegotiationThreadScreen(
                  negotiationId: negotiationId,
                  onClose: () => Navigator.pop(sheetContext),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class DPBargainingCenterScreen extends StatefulWidget {
  const DPBargainingCenterScreen({super.key});

  @override
  State<DPBargainingCenterScreen> createState() =>
      _DPBargainingCenterScreenState();
}

class _DPBargainingCenterScreenState extends State<DPBargainingCenterScreen> {
  Future<List<NegotiationThread>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= BookingsScope.maybeOf(context)?.negotiations();
    ProjectsScope.maybeOf(context)?.projects();
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;
    final projectTitles = <String, String>{
      for (final project
          in ProjectsScope.maybeOf(context)?.cachedProjects ?? const [])
        project.publicId: project.title,
    };

    if (future == null) {
      return DPBargainingV3(
        loading: false,
        error: 'Connect a live Director account to view bargaining threads.',
        negotiations: const [],
        projectTitles: projectTitles,
        onRefresh: _reload,
        onFindTalent: _findTalent,
        onOpenNegotiation: _openNegotiation,
      );
    }

    return FutureBuilder<List<NegotiationThread>>(
      future: future,
      builder: (context, snapshot) {
        return DPBargainingV3(
          loading: snapshot.connectionState == ConnectionState.waiting,
          error: snapshot.hasError
              ? 'Could not load live bargaining threads from the database. Check the API connection and try again.'
              : null,
          negotiations: snapshot.data ?? const [],
          projectTitles: projectTitles,
          onRefresh: _reload,
          onFindTalent: _findTalent,
          onOpenNegotiation: _openNegotiation,
        );
      },
    );
  }

  Future<void> _reload() async {
    final bookings = BookingsScope.maybeOf(context);
    if (bookings == null) return;
    final next = bookings.negotiations();
    setState(() => _future = next);
    await next;
    if (!mounted) return;
    final projects = ProjectsScope.maybeOf(context);
    if (projects != null) {
      await projects.projects(force: true);
    }
    if (mounted) setState(() {});
  }

  void _findTalent() {
    Navigator.pushNamed(context, DirectorProducerRoutes.marketplace);
  }

  void _openNegotiation(String id) {
    openNegotiationSheet(context, id);
  }
}
