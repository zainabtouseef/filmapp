import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/operations/operations_controller.dart';
import '../../../core/operations/operations_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/uploads/upload_repository.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../models/location_owner_models.dart';
import '../routes/location_owner_routes.dart';
import '../widgets/location_owner_components.dart';
import '../widgets/location_owner_live.dart';

class LO08CheckOutDamageClaimScreen extends StatefulWidget {
  const LO08CheckOutDamageClaimScreen({super.key});

  @override
  State<LO08CheckOutDamageClaimScreen> createState() =>
      _LO08CheckOutDamageClaimScreenState();
}

class _LO08CheckOutDamageClaimScreenState
    extends State<LO08CheckOutDamageClaimScreen> {
  OperationsController? _operations;
  BookingsController? _bookings;
  Future<_CheckOutData>? _future;
  _CheckOutData? _data;
  String? _selectedBookingId;
  bool _busy = false;
  String? _busyArea;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final operations = OperationsScope.maybeOf(context);
    final bookings = BookingsScope.maybeOf(context);
    if (operations == null || bookings == null) return;
    if (identical(operations, _operations) && identical(bookings, _bookings)) {
      return;
    }
    _operations = operations;
    _bookings = bookings;
    _future = _load();
  }

  Future<_CheckOutData> _load({bool force = false}) async {
    final properties = await _operations!.locationProperties(force: force);
    final property = activeLocationProperty(properties);
    final allBookings =
        await _bookings!.bookings(role: 'provider', force: force);
    final bookings = allBookings.where((booking) {
      return booking.category == 'location' &&
          {'accepted', 'secured', 'in_progress'}.contains(booking.status);
    }).toList();
    if (_selectedBookingId == null ||
        !bookings.any((item) => item.publicId == _selectedBookingId)) {
      _selectedBookingId = bookings.isEmpty ? null : bookings.first.publicId;
    }
    final inspections = await _operations!.locationInspections(
      propertyId: property?.publicId,
      force: force,
    );
    final claims = await _operations!.damageClaims(force: force);
    final data = _CheckOutData(
      property: property,
      bookings: bookings,
      inspections: inspections,
      claims: claims,
    );
    if (mounted) setState(() => _data = data);
    return data;
  }

  void _reload() {
    if (_operations == null || _bookings == null) return;
    setState(() => _future = _load(force: true));
  }

  @override
  Widget build(BuildContext context) {
    if (_future == null) {
      return const CoreEmptyState(
        icon: Icons.cloud_sync_outlined,
        title: 'Sign in to start check-out',
        message:
            'Check-out inspections, comparison evidence, damage claims and claim evidence are fetched from the backend.',
      );
    }
    return FutureBuilder<_CheckOutData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return CoreEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Check-out unavailable',
            message: locationApiMessage(snapshot.error!),
            actionLabel: 'Try again',
            onAction: _reload,
          );
        }
        final data = _data ?? snapshot.data!;
        if (data.property == null) {
          return CoreEmptyState(
            icon: Icons.add_location_alt_outlined,
            title: 'No active property',
            message: 'Create or select a property before check-out.',
            actionLabel: 'Open properties',
            onAction: () => Navigator.pushNamed(
              context,
              LocationOwnerRoutes.listing,
            ),
          );
        }
        if (data.bookings.isEmpty) {
          return CoreEmptyState(
            icon: Icons.event_busy_outlined,
            title: 'No accepted location booking',
            message: 'Check-out and damage claims require an accepted booking.',
            actionLabel: 'Open requests',
            onAction: () => Navigator.pushNamed(
              context,
              LocationOwnerRoutes.requests,
            ),
          );
        }
        return _buildCheckOut(data);
      },
    );
  }

  Widget _buildCheckOut(_CheckOutData data) {
    final colors = context.appColors;
    final booking = _selectedBooking(data.bookings);
    final checkIn =
        _inspectionFor(data.inspections, booking.publicId, 'check_in');
    final checkOut =
        _inspectionFor(data.inspections, booking.publicId, 'check_out');
    final claims = data.claims
        .where((claim) => claim.bookingId == booking.publicId)
        .toList();
    final spaces = data.property!.spaces;
    final captured = checkOut?.items.length ?? 0;
    final total = spaces.isEmpty ? 1 : spaces.length;
    final ownerConfirmed = checkOut?.confirmedByOwnerAt != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocationSectionCard(
          title: 'Check-out decision',
          icon: Icons.verified_user_outlined,
          selected: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CoreDropdownField<String>(
                value: booking.publicId,
                values: data.bookings.map((item) => item.publicId).toList(),
                label: 'Accepted booking',
                icon: Icons.movie_creation_outlined,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedBookingId = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusChip(
                    label: checkOut == null
                        ? 'NOT STARTED'
                        : ownerConfirmed
                            ? 'OWNER CONFIRMED'
                            : 'AFTER EVIDENCE REQUIRED',
                    icon: ownerConfirmed
                        ? Icons.check_circle_outline
                        : Icons.camera_alt_outlined,
                    color: ownerConfirmed ? colors.success : colors.goldMid,
                  ),
                  StatusChip(
                    label: claims.isEmpty
                        ? 'NO CLAIM FILED'
                        : '${claims.length} CLAIMS',
                    icon: Icons.report_problem_outlined,
                    color: claims.isEmpty ? colors.infoBlue : colors.danger,
                  ),
                  StatusChip(
                    label: checkIn == null
                        ? 'CHECK-IN MISSING'
                        : 'CHECK-IN AVAILABLE',
                    icon: checkIn == null
                        ? Icons.warning_amber_outlined
                        : Icons.fact_check_outlined,
                    color: checkIn == null ? colors.goldMid : colors.success,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CoreSecondaryButton(
                      icon: Icons.report_problem_outlined,
                      label: 'File claim',
                      compact: true,
                      onTap: _busy
                          ? null
                          : () => _showClaimSheet(
                                booking,
                                checkOut ?? checkIn,
                              ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CorePrimaryButton(
                      icon: checkOut == null
                          ? Icons.play_arrow_rounded
                          : Icons.receipt_long_outlined,
                      label: checkOut == null
                          ? (_busy ? 'Starting...' : 'Start check-out')
                          : 'View ledger',
                      compact: true,
                      onTap: _busy
                          ? null
                          : checkOut == null
                              ? () => _startCheckOut(
                                    booking,
                                    data.property!,
                                  )
                              : () => Navigator.pushNamed(
                                    context,
                                    CoreRoutes.ledger,
                                  ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LocationTwoColumn(
          left: LocationResponsiveGrid(
            minWidth: 300,
            children: [
              if (spaces.isEmpty)
                LocationSectionCard(
                  title: 'Condition comparison',
                  icon: Icons.compare_outlined,
                  child: const CoreEmptyState(
                    icon: Icons.dashboard_customize_outlined,
                    title: 'No property spaces',
                    message:
                        'Add shoot spaces before recording condition evidence.',
                  ),
                )
              else
                for (final space in spaces)
                  _ConditionComparisonCard(
                    area: space['name'] as String? ?? 'Property area',
                    before: _itemFor(
                      checkIn,
                      space['name'] as String? ?? '',
                    ),
                    after: _itemFor(
                      checkOut,
                      space['name'] as String? ?? '',
                    ),
                    locked: checkOut == null || ownerConfirmed,
                    busy: _busyArea == (space['name'] as String? ?? ''),
                    onCapture: () => _captureAfter(
                      checkOut!,
                      space['name'] as String? ?? 'Property area',
                    ),
                  ),
            ],
          ),
          right: Column(
            children: [
              LocationSectionCard(
                title: 'Completion review',
                icon: Icons.task_alt_outlined,
                tone: LocationTone.green,
                child: Column(
                  children: [
                    LocationInfoRow(
                      icon: Icons.photo_library_outlined,
                      label: 'After areas',
                      value: '$captured/$total',
                    ),
                    LocationInfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Owner confirmation',
                      value: ownerConfirmed ? 'Confirmed' : 'Waiting',
                    ),
                    LocationInfoRow(
                      icon: Icons.people_alt_outlined,
                      label: 'Renter confirmation',
                      value: checkOut?.confirmedByRenterAt != null
                          ? 'Confirmed'
                          : 'Waiting',
                    ),
                    const SizedBox(height: 8),
                    CorePrimaryButton(
                      icon: Icons.verified_outlined,
                      label: ownerConfirmed
                          ? 'Owner confirmed'
                          : _busy
                              ? 'Confirming...'
                              : 'Confirm check-out',
                      compact: true,
                      onTap: checkOut == null || ownerConfirmed || _busy
                          ? null
                          : captured < total
                              ? () => locationSnack(
                                    context,
                                    'Capture every property area first',
                                  )
                              : () => _confirmCheckOut(checkOut),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              LocationSectionCard(
                title: 'Damage claims',
                icon: Icons.gavel_outlined,
                tone: LocationTone.danger,
                child: claims.isEmpty
                    ? const CoreEmptyState(
                        icon: Icons.verified_user_outlined,
                        title: 'No claims filed',
                        message:
                            'A submitted claim and its evidence will appear here.',
                      )
                    : Column(
                        children: [
                          for (final claim in claims)
                            LocationInfoRow(
                              icon: Icons.report_problem_outlined,
                              label: claim.description,
                              value:
                                  '${claim.currency} ${compactLocationMoney(claim.claimedMinor ~/ 100)} · '
                                  '${readableLocationStatus(claim.status)}',
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _startCheckOut(
    Booking booking,
    LocationPropertyDto property,
  ) async {
    setState(() => _busy = true);
    try {
      await _operations!.createLocationInspection(
        bookingId: booking.publicId,
        propertyId: property.publicId,
        inspectionType: 'check_out',
        notes: 'Owner check-out condition record.',
      );
      if (!mounted) return;
      locationSnack(context, 'Check-out record created');
      _reload();
    } catch (error) {
      if (!mounted) return;
      locationSnack(context, locationApiMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _captureAfter(
    LocationInspectionDto inspection,
    String area,
  ) async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null) {
      locationSnack(context, 'Sign in to add condition evidence');
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null) return;
    setState(() => _busyArea = area);
    try {
      final uploaded = await auth.uploadFile(
        purpose: 'inspection_evidence',
        file: PickedFileData(
          name: file!.name,
          mimeType: _imageMimeType(file.extension),
          bytes: file.bytes!,
        ),
      );
      await _addAfterItemWhenReady(
        inspectionId: inspection.publicId,
        area: area,
        fileId: uploaded.publicId,
      );
      if (!mounted) return;
      locationSnack(context, '$area after-condition added');
      _reload();
    } catch (error) {
      if (!mounted) return;
      locationSnack(context, locationApiMessage(error));
    } finally {
      if (mounted) setState(() => _busyArea = null);
    }
  }

  Future<void> _addAfterItemWhenReady({
    required String inspectionId,
    required String area,
    required String fileId,
  }) async {
    ApiException? lastError;
    for (var attempt = 0; attempt < 6; attempt += 1) {
      try {
        await _operations!.addLocationInspectionItem(
          inspectionId: inspectionId,
          areaLabel: area,
          afterFileId: fileId,
          note: 'Check-out condition captured.',
        );
        return;
      } on ApiException catch (error) {
        lastError = error;
        final waiting = error.fields.containsKey('file_id') ||
            error.message.toLowerCase().contains('ready') ||
            error.message.toLowerCase().contains('clean');
        if (!waiting || attempt == 5) rethrow;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
    throw lastError!;
  }

  Future<void> _confirmCheckOut(LocationInspectionDto inspection) async {
    setState(() => _busy = true);
    try {
      await _operations!.confirmLocationInspection(inspection.publicId);
      if (!mounted) return;
      locationSnack(context, 'Owner check-out confirmation saved');
      _reload();
    } catch (error) {
      if (!mounted) return;
      locationSnack(context, locationApiMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showClaimSheet(
    Booking booking,
    LocationInspectionDto? inspection,
  ) {
    final amount = TextEditingController();
    final description = TextEditingController();
    PlatformFile? evidence;
    showLocationSheet(
      context,
      title: 'File damage claim',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CoreTextField(
                controller: amount,
                label: 'Claim amount (PKR)',
                icon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: description,
                label: 'Damage description',
                icon: Icons.edit_note_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              UploadCard(
                title: 'Damage evidence',
                subtitle: evidence?.name ?? 'Attach a clear supporting photo',
                uploaded: evidence != null,
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.image,
                    withData: true,
                  );
                  if (result?.files.single.bytes != null) {
                    setSheetState(() => evidence = result!.files.single);
                  }
                },
              ),
              const SizedBox(height: 12),
              CorePrimaryButton(
                icon: Icons.gavel_outlined,
                label: 'Submit claim',
                onTap: () {
                  final value = int.tryParse(amount.text.trim()) ?? 0;
                  if (value <= 0) {
                    locationSnack(context, 'Enter a valid claim amount');
                    return;
                  }
                  if (description.text.trim().length < 5) {
                    locationSnack(context, 'Describe the damage clearly');
                    return;
                  }
                  if (evidence == null) {
                    locationSnack(context, 'Attach damage evidence');
                    return;
                  }
                  Navigator.pop(context);
                  _submitClaim(
                    booking: booking,
                    inspection: inspection,
                    amountMinor: value * 100,
                    description: description.text.trim(),
                    evidence: evidence!,
                  );
                },
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      amount.dispose();
      description.dispose();
    });
  }

  Future<void> _submitClaim({
    required Booking booking,
    required LocationInspectionDto? inspection,
    required int amountMinor,
    required String description,
    required PlatformFile evidence,
  }) async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null || evidence.bytes == null) return;
    setState(() => _busy = true);
    try {
      final uploaded = await auth.uploadFile(
        purpose: 'damage_evidence',
        file: PickedFileData(
          name: evidence.name,
          mimeType: _imageMimeType(evidence.extension),
          bytes: evidence.bytes!,
        ),
      );
      final claim = await _operations!.createDamageClaim(
        bookingId: booking.publicId,
        description: description,
        claimedMinor: amountMinor,
        inspectionId: inspection?.publicId,
      );
      await _addClaimEvidenceWhenReady(
        claimId: claim.publicId,
        fileId: uploaded.publicId,
        caption: description,
      );
      if (!mounted) return;
      locationSnack(context, 'Damage claim submitted with evidence');
      _reload();
    } catch (error) {
      if (!mounted) return;
      locationSnack(context, locationApiMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addClaimEvidenceWhenReady({
    required String claimId,
    required String fileId,
    required String caption,
  }) async {
    ApiException? lastError;
    for (var attempt = 0; attempt < 6; attempt += 1) {
      try {
        await _operations!.addDamageClaimEvidence(
          claimId: claimId,
          fileId: fileId,
          caption: caption,
        );
        return;
      } on ApiException catch (error) {
        lastError = error;
        final waiting = error.fields.containsKey('file_id') ||
            error.message.toLowerCase().contains('ready') ||
            error.message.toLowerCase().contains('clean');
        if (!waiting || attempt == 5) rethrow;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
    throw lastError!;
  }

  Booking _selectedBooking(List<Booking> bookings) {
    for (final booking in bookings) {
      if (booking.publicId == _selectedBookingId) return booking;
    }
    return bookings.first;
  }

  LocationInspectionDto? _inspectionFor(
    List<LocationInspectionDto> inspections,
    String bookingId,
    String type,
  ) {
    for (final inspection in inspections) {
      if (inspection.bookingId == bookingId &&
          inspection.inspectionType == type) {
        return inspection;
      }
    }
    return null;
  }

  Map<String, dynamic>? _itemFor(
    LocationInspectionDto? inspection,
    String area,
  ) {
    if (inspection == null) return null;
    for (final item in inspection.items) {
      if ((item['area_label'] as String? ?? '').toLowerCase() ==
          area.toLowerCase()) {
        return item;
      }
    }
    return null;
  }

  String _imageMimeType(String? extension) {
    return switch (extension?.toLowerCase()) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}

class _ConditionComparisonCard extends StatelessWidget {
  final String area;
  final Map<String, dynamic>? before;
  final Map<String, dynamic>? after;
  final bool locked;
  final bool busy;
  final VoidCallback onCapture;

  const _ConditionComparisonCard({
    required this.area,
    required this.before,
    required this.after,
    required this.locked,
    required this.busy,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final issue = (after?['issue_severity'] as String? ?? 'none') != 'none';
    return GlassSectionCard(
      radius: 18,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _EvidenceBox(
                  label: 'Before',
                  available: before != null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _EvidenceBox(
                  label: 'After',
                  available: after != null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  area,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              StatusChip(
                label: issue
                    ? 'REVIEW'
                    : after != null
                        ? 'CAPTURED'
                        : 'PENDING',
                color: issue
                    ? colors.danger
                    : after != null
                        ? colors.success
                        : colors.goldMid,
              ),
            ],
          ),
          const SizedBox(height: 8),
          CorePrimaryButton(
            icon: Icons.camera_alt_outlined,
            label: busy ? 'Adding...' : 'Capture after',
            compact: true,
            onTap: locked || after != null || busy ? null : onCapture,
          ),
        ],
      ),
    );
  }
}

class _EvidenceBox extends StatelessWidget {
  final String label;
  final bool available;

  const _EvidenceBox({required this.label, required this.available});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      height: 82,
      decoration: BoxDecoration(
        gradient: colors.inactiveChipGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            available ? Icons.image_outlined : Icons.hide_image_outlined,
            color: available ? colors.success : colors.iconMuted,
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckOutData {
  final LocationPropertyDto? property;
  final List<Booking> bookings;
  final List<LocationInspectionDto> inspections;
  final List<DamageClaimDto> claims;

  const _CheckOutData({
    required this.property,
    required this.bookings,
    required this.inspections,
    required this.claims,
  });
}
