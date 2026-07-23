import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/operations/operations_controller.dart';
import '../../../core/operations/operations_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/uploads/upload_repository.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import 'media_equipment_components.dart';

class EquipmentInspectionWorkspace extends StatefulWidget {
  final String inspectionType;

  const EquipmentInspectionWorkspace({
    super.key,
    required this.inspectionType,
  });

  bool get isReturn => inspectionType == 'return';

  @override
  State<EquipmentInspectionWorkspace> createState() =>
      _EquipmentInspectionWorkspaceState();
}

class _EquipmentInspectionWorkspaceState
    extends State<EquipmentInspectionWorkspace> {
  Future<_InspectionData>? _dataFuture;
  String? _busyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dataFuture != null) return;
    _reload();
  }

  void _reload() {
    final operations = OperationsScope.maybeOf(context);
    final bookings = BookingsScope.maybeOf(context);
    if (operations == null || bookings == null) return;
    _dataFuture = _load(operations, bookings);
  }

  Future<_InspectionData> _load(
    OperationsController operations,
    BookingsController bookings,
  ) async {
    final values = await Future.wait([
      operations.equipmentProfile(force: true),
      operations.equipmentItems(force: true),
      operations.equipmentInspections(
        inspectionType: widget.inspectionType,
        force: true,
      ),
      bookings.bookings(role: 'provider', force: true),
    ]);
    return _InspectionData(
      profile: values[0] as EquipmentProfileDto?,
      items: values[1] as List<EquipmentItemDto>,
      inspections: values[2] as List<EquipmentInspectionDto>,
      bookings: (values[3] as List<Booking>)
          .where((booking) => booking.category == 'equipment')
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_dataFuture == null) {
      return InlineNotice(
        message:
            'Preview mode. Sign in to manage ${widget.inspectionType} inspections.',
        icon: Icons.visibility_outlined,
      );
    }
    return FutureBuilder<_InspectionData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return InlineNotice(
            message: 'Loading ${widget.inspectionType} inspections...',
            icon: Icons.hourglass_top_rounded,
          );
        }
        if (snapshot.hasError) {
          return InlineNotice(
            message: 'Could not load inspections: ${snapshot.error}',
            icon: Icons.cloud_off_outlined,
          );
        }
        final data = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MediaSectionCard(
              title: widget.isReturn
                  ? 'Return Inspection Control'
                  : 'Handover Inspection Control',
              icon: widget.isReturn
                  ? Icons.assignment_return_outlined
                  : Icons.qr_code_scanner_rounded,
              selected: true,
              child: MediaResponsiveGrid(
                minWidth: 220,
                children: [
                  MediaInfoRow(
                    icon: Icons.fact_check_outlined,
                    label: 'Workflow',
                    value: widget.isReturn
                        ? 'Compare return against handover'
                        : 'Record condition before release',
                  ),
                  const MediaInfoRow(
                    icon: Icons.qr_code_outlined,
                    label: 'Assets',
                    value: 'Serial and accessory record',
                  ),
                  const MediaInfoRow(
                    icon: Icons.draw_outlined,
                    label: 'Signatures',
                    value: 'Provider and renter confirmation',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (data.profile == null)
              const CoreEmptyState(
                icon: Icons.storefront_outlined,
                title: 'Provider profile required',
                message:
                    'Create the equipment provider profile before inspections.',
              )
            else if (data.inspections.isEmpty)
              CoreEmptyState(
                icon: widget.isReturn
                    ? Icons.assignment_return_outlined
                    : Icons.qr_code_scanner_rounded,
                title: 'No ${widget.inspectionType} inspection',
                message:
                    'Start from an accepted equipment booking and select every asset being transferred.',
                actionLabel: 'Start inspection',
                onAction: _eligibleBookings(data).isEmpty
                    ? null
                    : () => _showCreate(data),
              )
            else ...[
              for (final inspection in data.inspections)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _InspectionCard(
                    inspection: inspection,
                    isReturn: widget.isReturn,
                    busy: _busyId == inspection.publicId,
                    onRecord: (item, issue) =>
                        _showRecord(inspection, item, issue),
                    onConfirm: () => _confirm(inspection),
                    onClaim:
                        widget.isReturn ? () => _showClaim(inspection) : null,
                  ),
                ),
              CoreSecondaryButton(
                icon: Icons.add_rounded,
                label: 'Start another ${widget.inspectionType}',
                compact: true,
                onTap: _eligibleBookings(data).isEmpty
                    ? null
                    : () => _showCreate(data),
              ),
            ],
          ],
        );
      },
    );
  }

  List<Booking> _eligibleBookings(_InspectionData data) {
    return data.bookings
        .where(
          (booking) => {
            'accepted',
            'secured',
            'in_progress',
            'completed',
          }.contains(booking.status),
        )
        .toList();
  }

  void _showCreate(_InspectionData data) {
    final pageContext = context;
    final eligible = _eligibleBookings(data);
    if (eligible.isEmpty || data.profile == null) {
      mediaSnack(context, 'An accepted equipment booking is required');
      return;
    }
    var bookingId = eligible.first.publicId;
    final selected = data.items.map((item) => item.publicId).toSet();
    showMediaSheet(
      context,
      title: 'Start ${widget.inspectionType} inspection',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Booking',
                style: AppTextStyles.cardLabel.copyWith(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final booking in eligible)
                    CoreChip(
                      label:
                          '${booking.publicId} · ${booking.requester.displayName}',
                      selected: bookingId == booking.publicId,
                      onTap: () =>
                          setSheetState(() => bookingId = booking.publicId),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Transferred inventory',
                style: AppTextStyles.cardLabel.copyWith(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: data.items.length,
                  itemBuilder: (context, index) {
                    final item = data.items[index];
                    return CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.modelName),
                      subtitle: Text('${item.category} · ${item.publicId}'),
                      value: selected.contains(item.publicId),
                      onChanged: (value) => setSheetState(() {
                        if (value == true) {
                          selected.add(item.publicId);
                        } else {
                          selected.remove(item.publicId);
                        }
                      }),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              CorePrimaryButton(
                icon: Icons.playlist_add_check_rounded,
                label: 'Create inspection',
                onTap: selected.isEmpty
                    ? null
                    : () async {
                        final operations = OperationsScope.maybeOf(context);
                        if (operations == null) return;
                        try {
                          final inspection =
                              await operations.createEquipmentInspection(
                            bookingId: bookingId,
                            providerProfileId: data.profile!.publicId,
                            inspectionType: widget.inspectionType,
                          );
                          for (final itemId in selected) {
                            await operations.addEquipmentInspectionItem(
                              inspectionId: inspection.publicId,
                              equipmentItemId: itemId,
                              accessories: const [],
                              stage: 'pending',
                              note: 'Awaiting condition capture',
                            );
                          }
                          if (!mounted || !context.mounted) return;
                          Navigator.pop(context);
                          setState(_reload);
                          mediaSnack(
                            pageContext,
                            '${_title(widget.inspectionType)} inspection created',
                          );
                        } catch (error) {
                          if (context.mounted) {
                            mediaSnack(
                              context,
                              'Could not create inspection: $error',
                            );
                          }
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRecord(
    EquipmentInspectionDto inspection,
    EquipmentItemDto item,
    bool issue,
  ) {
    final pageContext = context;
    final accessories = TextEditingController();
    final note = TextEditingController(
      text: issue
          ? (widget.isReturn
              ? 'Missing accessory or condition mismatch'
              : 'Condition issue before release')
          : (widget.isReturn
              ? 'Return condition matches handover'
              : 'Condition verified before release'),
    );
    PlatformFile? evidence;
    showMediaSheet(
      context,
      title: '${widget.isReturn ? 'Return' : 'Handover'} · ${item.modelName}',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CoreTextField(
                controller: accessories,
                label: 'Accessories, comma separated',
                icon: Icons.cable_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: note,
                label: 'Condition and evidence note',
                icon: Icons.fact_check_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              UploadCard(
                title: evidence?.name ?? 'Condition evidence photo',
                subtitle: evidence == null
                    ? 'Optional JPG, PNG, or WebP'
                    : 'Ready to upload securely',
                uploaded: evidence != null,
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
                    withData: true,
                  );
                  if (result?.files.single.bytes == null) return;
                  setSheetState(() => evidence = result!.files.single);
                },
              ),
              const SizedBox(height: 12),
              CorePrimaryButton(
                icon: issue
                    ? Icons.report_problem_outlined
                    : Icons.camera_alt_outlined,
                label: issue ? 'Record issue' : 'Save condition',
                onTap: () async {
                  final operations = OperationsScope.maybeOf(context);
                  if (operations == null) return;
                  try {
                    final fileId = evidence == null
                        ? null
                        : await _uploadEvidence(evidence!);
                    await _saveInspectionItem(
                      operations: operations,
                      inspection: inspection,
                      item: item,
                      accessories: accessories.text,
                      note: note.text,
                      issue: issue,
                      fileId: fileId,
                    );
                    if (!mounted || !context.mounted) return;
                    Navigator.pop(context);
                    setState(_reload);
                    mediaSnack(pageContext, '${item.modelName} recorded');
                  } catch (error) {
                    if (context.mounted) {
                      mediaSnack(context, 'Could not save condition: $error');
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      accessories.dispose();
      note.dispose();
    });
  }

  Future<String> _uploadEvidence(PlatformFile file) async {
    final auth = AuthScope.of(context);
    final uploaded = await auth.uploadFile(
      purpose: 'inspection_evidence',
      file: PickedFileData(
        name: file.name,
        mimeType: _mimeType(file),
        bytes: file.bytes!,
      ),
    );
    return uploaded.publicId;
  }

  Future<void> _saveInspectionItem({
    required OperationsController operations,
    required EquipmentInspectionDto inspection,
    required EquipmentItemDto item,
    required String accessories,
    required String note,
    required bool issue,
    required String? fileId,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt < 6; attempt += 1) {
      try {
        await operations.addEquipmentInspectionItem(
          inspectionId: inspection.publicId,
          equipmentItemId: item.publicId,
          accessories: accessories
              .split(',')
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toList(),
          stage: issue
              ? (widget.isReturn ? 'missing' : 'issue')
              : (widget.isReturn ? 'verified' : 'captured'),
          note: note.trim(),
          beforeFileId: widget.isReturn ? null : fileId,
          afterFileId: widget.isReturn ? fileId : null,
        );
        return;
      } catch (error) {
        lastError = error;
        if (fileId == null || attempt == 5) rethrow;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
    throw lastError ?? StateError('Inspection item could not be saved');
  }

  Future<void> _confirm(EquipmentInspectionDto inspection) async {
    final operations = OperationsScope.maybeOf(context);
    if (operations == null) return;
    setState(() => _busyId = inspection.publicId);
    try {
      await operations.confirmEquipmentInspection(inspection.publicId);
      if (!mounted) return;
      setState(_reload);
      mediaSnack(
        context,
        inspection.signedByProvider
            ? 'Provider signature already recorded'
            : 'Provider signature recorded',
      );
    } catch (error) {
      if (mounted) mediaSnack(context, 'Could not confirm inspection: $error');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  void _showClaim(EquipmentInspectionDto inspection) {
    final pageContext = context;
    final amount = TextEditingController();
    final description = TextEditingController(
      text: 'Return inspection identified missing or damaged equipment.',
    );
    showMediaSheet(
      context,
      title: 'Submit damage or missing-item claim',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CoreTextField(
            controller: amount,
            label: 'Claim amount in PKR',
            icon: Icons.payments_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          CoreTextField(
            controller: description,
            label: 'Claim explanation',
            icon: Icons.gavel_outlined,
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          CorePrimaryButton(
            icon: Icons.report_problem_outlined,
            label: 'Submit claim for review',
            onTap: () async {
              final value = int.tryParse(amount.text.trim());
              if (value == null ||
                  value <= 0 ||
                  description.text.trim().length < 10) {
                mediaSnack(context, 'Enter amount and detailed explanation');
                return;
              }
              final operations = OperationsScope.maybeOf(context);
              if (operations == null) return;
              try {
                await operations.createDamageClaim(
                  bookingId: inspection.bookingId,
                  description: description.text.trim(),
                  claimedMinor: value * 100,
                  inspectionId: inspection.publicId,
                );
                if (!mounted || !context.mounted) return;
                Navigator.pop(context);
                mediaSnack(pageContext, 'Claim submitted for admin review');
              } catch (error) {
                if (context.mounted) {
                  mediaSnack(context, 'Could not submit claim: $error');
                }
              }
            },
          ),
        ],
      ),
    ).whenComplete(() {
      amount.dispose();
      description.dispose();
    });
  }
}

class _InspectionCard extends StatelessWidget {
  final EquipmentInspectionDto inspection;
  final bool isReturn;
  final bool busy;
  final void Function(EquipmentItemDto item, bool issue) onRecord;
  final VoidCallback onConfirm;
  final VoidCallback? onClaim;

  const _InspectionCard({
    required this.inspection,
    required this.isReturn,
    required this.busy,
    required this.onRecord,
    required this.onConfirm,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final complete = inspection.status == 'confirmed';
    final parsed = inspection.items
        .map(_InspectionItemView.fromJson)
        .whereType<_InspectionItemView>()
        .toList();
    final allRecorded =
        parsed.isNotEmpty && parsed.every((item) => item.stage != 'pending');
    return MediaSectionCard(
      title: 'Booking ${inspection.bookingId}',
      icon: isReturn
          ? Icons.assignment_return_outlined
          : Icons.qr_code_scanner_rounded,
      selected: !complete,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusChip(
                label: _title(inspection.status),
                color: complete ? colors.success : colors.goldMid,
              ),
              StatusChip(
                label: inspection.signedByProvider
                    ? 'Provider signed'
                    : 'Provider signature pending',
                color: inspection.signedByProvider
                    ? colors.success
                    : colors.infoBlue,
              ),
              StatusChip(
                label: inspection.signedByRenter
                    ? 'Renter signed'
                    : 'Renter signature pending',
                color: inspection.signedByRenter
                    ? colors.success
                    : colors.infoPurple,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (parsed.isEmpty)
            const InlineNotice(
              message: 'No inventory items attached to this inspection.',
              icon: Icons.info_outline,
            )
          else
            MediaResponsiveGrid(
              minWidth: 280,
              children: [
                for (final row in parsed)
                  _InspectionItemCard(
                    row: row,
                    isReturn: isReturn,
                    locked: complete || busy,
                    onVerified: () => onRecord(row.item, false),
                    onIssue: () => onRecord(row.item, true),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (onClaim != null) ...[
                Expanded(
                  child: CoreSecondaryButton(
                    icon: Icons.gavel_outlined,
                    label: 'Damage claim',
                    compact: true,
                    onTap: complete ? onClaim : null,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: CorePrimaryButton(
                  icon: complete ? Icons.verified_rounded : Icons.draw_outlined,
                  label: complete
                      ? 'Inspection confirmed'
                      : inspection.signedByProvider
                          ? 'Await renter signature'
                          : 'Sign as provider',
                  compact: true,
                  onTap: complete ||
                          inspection.signedByProvider ||
                          !allRecorded ||
                          busy
                      ? null
                      : onConfirm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InspectionItemCard extends StatelessWidget {
  final _InspectionItemView row;
  final bool isReturn;
  final bool locked;
  final VoidCallback onVerified;
  final VoidCallback onIssue;

  const _InspectionItemCard({
    required this.row,
    required this.isReturn,
    required this.locked,
    required this.onVerified,
    required this.onIssue,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final issue = {'issue', 'missing'}.contains(row.stage);
    return GlassSectionCard(
      radius: 8,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.videocam_outlined,
                color: issue ? colors.danger : colors.goldDark,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  row.item.modelName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              StatusChip(
                label: _title(row.stage),
                color: issue
                    ? colors.danger
                    : row.stage == 'pending'
                        ? colors.goldMid
                        : colors.success,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            row.note.isEmpty ? 'Condition not yet recorded' : row.note,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
            ),
          ),
          if (row.accessories.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              'Accessories: ${row.accessories.join(', ')}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              StatusChip(
                label: row.hasEvidence ? 'Evidence attached' : 'No photo',
                color: row.hasEvidence ? colors.infoBlue : colors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.report_problem_outlined,
                  label: isReturn ? 'Missing / damaged' : 'Record issue',
                  compact: true,
                  onTap: locked ? null : onIssue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CorePrimaryButton(
                  icon: Icons.camera_alt_outlined,
                  label: isReturn ? 'Verify return' : 'Capture condition',
                  compact: true,
                  onTap: locked ? null : onVerified,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InspectionItemView {
  final EquipmentItemDto item;
  final List<String> accessories;
  final String stage;
  final String note;
  final bool hasEvidence;

  const _InspectionItemView({
    required this.item,
    required this.accessories,
    required this.stage,
    required this.note,
    required this.hasEvidence,
  });

  static _InspectionItemView? fromJson(Map<String, dynamic> json) {
    final rawItem = json['equipment_item'];
    if (rawItem is! Map<String, dynamic>) return null;
    return _InspectionItemView(
      item: EquipmentItemDto.fromJson(rawItem),
      accessories: (json['accessories'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      stage: json['stage'] as String? ?? 'pending',
      note: json['note'] as String? ?? '',
      hasEvidence: json['before_file'] != null || json['after_file'] != null,
    );
  }
}

class _InspectionData {
  final EquipmentProfileDto? profile;
  final List<EquipmentItemDto> items;
  final List<EquipmentInspectionDto> inspections;
  final List<Booking> bookings;

  const _InspectionData({
    required this.profile,
    required this.items,
    required this.inspections,
    required this.bookings,
  });
}

String _mimeType(PlatformFile file) {
  return switch ((file.extension ?? '').toLowerCase()) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'application/octet-stream',
  };
}

String _title(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
