import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/operations/operations_controller.dart';
import '../../../core/operations/operations_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/uploads/upload_repository.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/location_owner_demo_data.dart';
import '../models/location_owner_models.dart';
import '../routes/location_owner_routes.dart';
import '../widgets/location_owner_components.dart';
import '../widgets/location_owner_live.dart';

class LO07CheckInInspectionScreen extends StatefulWidget {
  const LO07CheckInInspectionScreen({super.key});

  @override
  State<LO07CheckInInspectionScreen> createState() =>
      _LO07CheckInInspectionScreenState();
}

class _LO07CheckInInspectionScreenState
    extends State<LO07CheckInInspectionScreen> {
  OperationsController? _operations;
  BookingsController? _bookings;
  Future<_InspectionData>? _future;
  _InspectionData? _data;
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

  Future<_InspectionData> _load({bool force = false}) async {
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
      inspectionType: 'check_in',
    );
    final data = _InspectionData(
      property: property,
      bookings: bookings,
      inspections: inspections,
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
    if (_future == null) return _buildPreview();
    return FutureBuilder<_InspectionData>(
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
            title: 'Check-in unavailable',
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
            message: 'Create or select a property before starting check-in.',
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
            message:
                'Check-in becomes available after a location offer is accepted.',
            actionLabel: 'Open requests',
            onAction: () => Navigator.pushNamed(
              context,
              LocationOwnerRoutes.requests,
            ),
          );
        }
        return _buildInspection(data);
      },
    );
  }

  Widget _buildInspection(_InspectionData data) {
    final colors = context.appColors;
    final booking = _selectedBooking(data.bookings);
    final inspection = _inspectionFor(data.inspections, booking.publicId);
    final spaces = data.property!.spaces;
    final captured = inspection?.items.length ?? 0;
    final total = spaces.isEmpty ? 1 : spaces.length;
    final progress = (captured / total).clamp(0.0, 1.0);
    final ownerConfirmed = inspection?.confirmedByOwnerAt != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocationSectionCard(
          title: 'Check-in progress',
          icon: Icons.fact_check_outlined,
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
                  if (value == null) return;
                  setState(() => _selectedBookingId = value);
                },
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(999),
                backgroundColor: colors.border,
                color: progress >= 1 ? colors.success : colors.goldMid,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusChip(
                    label: inspection == null
                        ? 'NOT STARTED'
                        : ownerConfirmed
                            ? 'OWNER CONFIRMED'
                            : 'EVIDENCE IN PROGRESS',
                    icon: ownerConfirmed
                        ? Icons.verified_outlined
                        : Icons.camera_alt_outlined,
                    color: ownerConfirmed ? colors.success : colors.goldMid,
                  ),
                  StatusChip(
                    label: '$captured/$total AREAS',
                    icon: Icons.dashboard_customize_outlined,
                    color: colors.infoBlue,
                  ),
                  StatusChip(
                    label: inspection?.meterReading?.isNotEmpty == true
                        ? 'METER RECORDED'
                        : 'METER OPTIONAL',
                    icon: Icons.electric_meter_outlined,
                    color: colors.infoPurple,
                  ),
                ],
              ),
              if (inspection == null) ...[
                const SizedBox(height: 12),
                CorePrimaryButton(
                  icon: Icons.play_arrow_rounded,
                  label: _busy ? 'Starting...' : 'Start check-in record',
                  compact: true,
                  onTap: _busy
                      ? null
                      : () => _startInspection(booking, data.property!),
                ),
              ],
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
                  title: 'Inspection areas',
                  icon: Icons.dashboard_customize_outlined,
                  child: CoreEmptyState(
                    icon: Icons.add_box_outlined,
                    title: 'No shoot spaces defined',
                    message:
                        'Add production areas to the property before check-in.',
                    actionLabel: 'Edit property',
                    onAction: () => Navigator.pushNamed(
                      context,
                      LocationOwnerRoutes.listing,
                    ),
                  ),
                )
              else
                for (final space in spaces)
                  _LiveInspectionAreaCard(
                    area: space['name'] as String? ?? 'Property area',
                    item: _itemFor(
                      inspection,
                      space['name'] as String? ?? '',
                    ),
                    locked: inspection == null || ownerConfirmed,
                    busy: _busyArea == (space['name'] as String? ?? ''),
                    onCapture: () => _captureArea(
                      inspection!,
                      space['name'] as String? ?? 'Property area',
                    ),
                    onIssue: () => _reportAreaIssue(
                      inspection!,
                      space['name'] as String? ?? 'Property area',
                    ),
                  ),
            ],
          ),
          right: LocationSectionCard(
            title: 'Handover review',
            icon: Icons.draw_outlined,
            tone: LocationTone.green,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocationInfoRow(
                  icon: Icons.movie_creation_outlined,
                  label: 'Booking',
                  value: booking.publicId,
                ),
                LocationInfoRow(
                  icon: Icons.business_outlined,
                  label: 'Producer',
                  value: booking.requester.displayName,
                ),
                LocationInfoRow(
                  icon: Icons.location_city_outlined,
                  label: 'Property',
                  value: data.property!.name,
                ),
                LocationInfoRow(
                  icon: Icons.people_alt_outlined,
                  label: 'Renter confirmation',
                  value: inspection?.confirmedByRenterAt != null
                      ? 'Confirmed'
                      : 'Waiting',
                ),
                const SizedBox(height: 8),
                Text(
                  'Owner confirmation locks the current evidence record. The renter confirms the same record separately.',
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                CorePrimaryButton(
                  icon: Icons.verified_outlined,
                  label: ownerConfirmed
                      ? 'Owner confirmed'
                      : _busy
                          ? 'Confirming...'
                          : 'Confirm handover',
                  compact: true,
                  onTap: inspection == null || ownerConfirmed || _busy
                      ? null
                      : captured < total
                          ? () => locationSnack(
                                context,
                                'Capture every property area first',
                              )
                          : () => _confirmInspection(inspection),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _startInspection(
    Booking booking,
    LocationPropertyDto property,
  ) async {
    final meter = TextEditingController();
    final notes = TextEditingController();
    showLocationSheet(
      context,
      title: 'Start check-in',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CoreTextField(
            controller: meter,
            label: 'Meter reading (optional)',
            icon: Icons.electric_meter_outlined,
          ),
          const SizedBox(height: 10),
          CoreTextField(
            controller: notes,
            label: 'Handover notes',
            icon: Icons.edit_note_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          CorePrimaryButton(
            icon: Icons.play_arrow_rounded,
            label: 'Create check-in record',
            onTap: () {
              Navigator.pop(context);
              _createInspection(
                booking,
                property,
                meter.text.trim(),
                notes.text.trim(),
              );
            },
          ),
        ],
      ),
    ).whenComplete(() {
      meter.dispose();
      notes.dispose();
    });
  }

  Future<void> _createInspection(
    Booking booking,
    LocationPropertyDto property,
    String meter,
    String notes,
  ) async {
    setState(() => _busy = true);
    try {
      await _operations!.createLocationInspection(
        bookingId: booking.publicId,
        propertyId: property.publicId,
        inspectionType: 'check_in',
        meterReading: meter.isEmpty ? null : meter,
        notes: notes.isEmpty ? null : notes,
      );
      if (!mounted) return;
      locationSnack(context, 'Check-in record created');
      _reload();
    } catch (error) {
      if (!mounted) return;
      locationSnack(context, locationApiMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _captureArea(
    LocationInspectionDto inspection,
    String area,
  ) async {
    await _addAreaEvidence(
      inspection: inspection,
      area: area,
      severity: 'none',
      note: 'Check-in condition captured.',
    );
  }

  void _reportAreaIssue(
    LocationInspectionDto inspection,
    String area,
  ) {
    final note = TextEditingController();
    showLocationSheet(
      context,
      title: 'Document issue',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CoreTextField(
            controller: note,
            label: 'Condition note',
            icon: Icons.report_problem_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          CorePrimaryButton(
            icon: Icons.camera_alt_outlined,
            label: 'Add issue evidence',
            onTap: () {
              if (note.text.trim().length < 3) {
                locationSnack(context, 'Describe the condition issue');
                return;
              }
              Navigator.pop(context);
              _addAreaEvidence(
                inspection: inspection,
                area: area,
                severity: 'medium',
                note: note.text.trim(),
              );
            },
          ),
        ],
      ),
    ).whenComplete(note.dispose);
  }

  Future<void> _addAreaEvidence({
    required LocationInspectionDto inspection,
    required String area,
    required String severity,
    required String note,
  }) async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null) {
      locationSnack(context, 'Sign in to add inspection evidence');
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
      await _addInspectionItemWhenReady(
        inspectionId: inspection.publicId,
        area: area,
        fileId: uploaded.publicId,
        severity: severity,
        note: note,
      );
      if (!mounted) return;
      locationSnack(context, '$area evidence added');
      _reload();
    } catch (error) {
      if (!mounted) return;
      locationSnack(context, locationApiMessage(error));
    } finally {
      if (mounted) setState(() => _busyArea = null);
    }
  }

  Future<void> _addInspectionItemWhenReady({
    required String inspectionId,
    required String area,
    required String fileId,
    required String severity,
    required String note,
  }) async {
    ApiException? lastError;
    for (var attempt = 0; attempt < 6; attempt += 1) {
      try {
        await _operations!.addLocationInspectionItem(
          inspectionId: inspectionId,
          areaLabel: area,
          beforeFileId: fileId,
          note: note,
          issueSeverity: severity,
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

  Future<void> _confirmInspection(LocationInspectionDto inspection) async {
    setState(() => _busy = true);
    try {
      await _operations!.confirmLocationInspection(inspection.publicId);
      if (!mounted) return;
      locationSnack(context, 'Owner handover confirmation saved');
      _reload();
    } catch (error) {
      if (!mounted) return;
      locationSnack(context, locationApiMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
  ) {
    for (final inspection in inspections) {
      if (inspection.bookingId == bookingId) return inspection;
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

  Widget _buildPreview() {
    final items = LocationOwnerDemoStore.instance.inspection;
    return LocationSectionCard(
      title: 'Check-in preview',
      icon: Icons.fact_check_outlined,
      selected: true,
      child: Column(
        children: [
          for (final item in items)
            LocationInfoRow(
              icon: Icons.camera_alt_outlined,
              label: item.area,
              value: 'Evidence pending',
            ),
        ],
      ),
    );
  }
}

class _LiveInspectionAreaCard extends StatelessWidget {
  final String area;
  final Map<String, dynamic>? item;
  final bool locked;
  final bool busy;
  final VoidCallback onCapture;
  final VoidCallback onIssue;

  const _LiveInspectionAreaCard({
    required this.area,
    required this.item,
    required this.locked,
    required this.busy,
    required this.onCapture,
    required this.onIssue,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final severity = item?['issue_severity'] as String? ?? 'none';
    final complete = item != null;
    final issue = severity != 'none';
    return GlassSectionCard(
      radius: 18,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 92,
            decoration: BoxDecoration(
              gradient: colors.inactiveChipGradient,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            alignment: Alignment.center,
            child: Icon(
              complete ? Icons.image_outlined : Icons.add_a_photo_outlined,
              color: complete ? colors.success : colors.goldDark,
              size: 30,
            ),
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
                    ? 'ISSUE'
                    : complete
                        ? 'CAPTURED'
                        : 'PENDING',
                color: issue
                    ? colors.danger
                    : complete
                        ? colors.success
                        : colors.goldMid,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            item?['note'] as String? ??
                'Add a clear condition photo before handover.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.report_problem_outlined,
                  label: 'Issue',
                  compact: true,
                  onTap: locked || complete || busy ? null : onIssue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CorePrimaryButton(
                  icon: Icons.camera_alt_outlined,
                  label: busy ? 'Adding...' : 'Capture',
                  compact: true,
                  onTap: locked || complete || busy ? null : onCapture,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InspectionData {
  final LocationPropertyDto? property;
  final List<Booking> bookings;
  final List<LocationInspectionDto> inspections;

  const _InspectionData({
    required this.property,
    required this.bookings,
    required this.inspections,
  });
}
