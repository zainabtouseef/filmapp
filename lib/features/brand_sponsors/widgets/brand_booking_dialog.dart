import 'package:flutter/material.dart';

import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/projects/project_models.dart';
import 'brand_sponsor_components.dart';
import 'brand_sponsor_live.dart';

Future<bool> showBrandBookingDialog(
  BuildContext context, {
  required String listingId,
  required String listingTitle,
  required List<Project> projects,
  String? initialProjectId,
  int? suggestedRateMinor,
  String currency = 'PKR',
  String pricingMode = 'negotiable',
  bool allowsBargaining = true,
}) async {
  final bookings = BookingsScope.maybeOf(context);
  if (bookings == null) {
    brandSnack(context, 'Sign in to send a booking request');
    return false;
  }
  final availableProjects = projects
      .where((project) => !{'archived', 'cancelled', 'completed'}
          .contains(project.status.toLowerCase()))
      .toList();
  if (availableProjects.isEmpty) {
    brandSnack(context, 'Create an active project before sending a request');
    return false;
  }

  Project selected = availableProjects.firstWhere(
    (project) => project.publicId == initialProjectId,
    orElse: () => availableProjects.first,
  );
  final amount = TextEditingController(
    text: suggestedRateMinor == null
        ? ''
        : (suggestedRateMinor / 100).round().toString(),
  );
  final message = TextEditingController(
    text: 'Request for $listingTitle on ${selected.title}.',
  );
  final today = DateUtils.dateOnly(DateTime.now());
  DateTime start =
      selected.startDate == null || selected.startDate!.isBefore(today)
          ? today.add(const Duration(days: 14))
          : selected.startDate!;
  DateTime end = selected.endDate ?? start.add(const Duration(days: 1));
  if (!end.isAfter(start)) end = start.add(const Duration(days: 1));
  var saving = false;
  String? error;

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        Future<void> submit() async {
          final wholeAmount = int.tryParse(
            amount.text.trim().replaceAll(',', ''),
          );
          if (wholeAmount == null || wholeAmount <= 0) {
            setDialogState(() => error = 'Enter a valid proposed rate.');
            return;
          }
          if (!end.isAfter(start)) {
            setDialogState(() => error = 'End date must be after start date.');
            return;
          }
          setDialogState(() {
            saving = true;
            error = null;
          });
          try {
            await bookings.createAndSendBooking(
              projectId: selected.publicId,
              listingId: listingId,
              startAt: _atHour(start, 9).toUtc().toIso8601String(),
              endAt: _atHour(end, 18).toUtc().toIso8601String(),
              feeMinor: wholeAmount * 100,
              currency: currency,
              message: message.text.trim(),
            );
            if (dialogContext.mounted) Navigator.pop(dialogContext, true);
          } catch (caught) {
            setDialogState(() {
              error = brandApiMessage(caught);
              saving = false;
            });
          }
        }

        return AlertDialog(
          title: const Text('Send production request'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listingTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selected.publicId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Project',
                      prefixIcon: Icon(Icons.movie_creation_outlined),
                    ),
                    items: [
                      for (final project in availableProjects)
                        DropdownMenuItem(
                          value: project.publicId,
                          child: Text(
                            project.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: saving
                        ? null
                        : (value) {
                            if (value == null) return;
                            setDialogState(() {
                              selected = availableProjects.firstWhere(
                                (project) => project.publicId == value,
                              );
                              start = selected.startDate == null ||
                                      selected.startDate!.isBefore(today)
                                  ? today.add(const Duration(days: 14))
                                  : selected.startDate!;
                              end = selected.endDate ??
                                  start.add(const Duration(days: 1));
                              if (!end.isAfter(start)) {
                                end = start.add(const Duration(days: 1));
                              }
                            });
                          },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: saving
                              ? null
                              : () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: start,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 1095)),
                                  );
                                  if (picked != null) {
                                    setDialogState(() => start = picked);
                                  }
                                },
                          icon: const Icon(Icons.event_outlined),
                          label: Text('Start ${_date(start)}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: saving
                              ? null
                              : () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: end,
                                    firstDate: start,
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 1095)),
                                  );
                                  if (picked != null) {
                                    setDialogState(() => end = picked);
                                  }
                                },
                          icon: const Icon(Icons.event_available_outlined),
                          label: Text('End ${_date(end)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CoreTextField(
                    controller: amount,
                    label: pricingMode == 'fixed'
                        ? 'Fixed listed rate ($currency)'
                        : 'Proposed rate ($currency)',
                    icon: Icons.payments_outlined,
                    keyboardType: TextInputType.number,
                    enabled: !saving && pricingMode != 'fixed',
                  ),
                  const SizedBox(height: 8),
                  InlineNotice(
                    message: switch (pricingMode) {
                      'fixed' =>
                        'This provider publishes a fixed price. Counteroffers are disabled, but you can still discuss scope in chat.',
                      'on_request' =>
                        'The provider keeps pricing private. Enter your offer to begin bargaining.',
                      _ => allowsBargaining
                          ? 'This is a public starting price. You and the provider may counteroffer.'
                          : 'Send the request at the published rate.',
                    },
                    icon: allowsBargaining
                        ? Icons.handshake_outlined
                        : Icons.lock_outline_rounded,
                    tone: CoreStatusTone.info,
                  ),
                  const SizedBox(height: 12),
                  CoreTextField(
                    controller: message,
                    label: 'Request message and scope',
                    icon: Icons.notes_outlined,
                    maxLines: 3,
                    enabled: !saving,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    InlineNotice(
                      message: error!,
                      icon: Icons.error_outline_rounded,
                      tone: CoreStatusTone.danger,
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: saving ? null : submit,
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(saving ? 'Sending...' : 'Send request'),
            ),
          ],
        );
      },
    ),
  );
  amount.dispose();
  message.dispose();
  return result ?? false;
}

DateTime _atHour(DateTime value, int hour) {
  return DateTime(value.year, value.month, value.day, hour);
}

String _date(DateTime value) {
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
