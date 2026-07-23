import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/operations/operations_controller.dart';
import '../../../core/operations/operations_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/uploads/upload_repository.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/location_owner_demo_data.dart';
import '../models/location_owner_models.dart';
import '../routes/location_owner_routes.dart';
import '../widgets/location_owner_components.dart';
import '../widgets/location_owner_live.dart';

class LO02LocationListingWizardScreen extends StatefulWidget {
  const LO02LocationListingWizardScreen({super.key});

  @override
  State<LO02LocationListingWizardScreen> createState() =>
      _LO02LocationListingWizardScreenState();
}

class _LO02LocationListingWizardScreenState
    extends State<LO02LocationListingWizardScreen> {
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _area = TextEditingController();
  final _exactAddress = TextEditingController();
  final _description = TextEditingController();
  final _capacity = TextEditingController();
  final _parking = TextEditingController();
  final _spaces = TextEditingController();

  OperationsController? _operations;
  bool _loaded = false;
  bool _loading = false;
  bool _saving = false;
  bool _uploading = false;
  int _step = 1;
  String _type = 'Home';
  bool _powerBackup = false;
  bool _accessible = false;
  String? _propertyId;
  String? _propertyStatus;
  String _coverImageUrl = '';
  String? _error;
  final List<String> _mediaFileIds = [];
  final List<String> _mediaNames = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final operations = OperationsScope.maybeOf(context);
    if (operations == null || identical(operations, _operations)) return;
    _operations = operations;
    _loadProperty();
  }

  Future<void> _loadProperty() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final properties = await _operations!.locationProperties();
      final property = activeLocationProperty(properties);
      if (property != null) _applyProperty(property);
      _loaded = true;
    } catch (error) {
      _error = locationApiMessage(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyProperty(LocationPropertyDto property) {
    _propertyId = property.publicId;
    _propertyStatus = property.status;
    _coverImageUrl = property.mediaUrls.isEmpty ? '' : property.mediaUrls.first;
    _name.text = property.name;
    _type = _displayType(property.propertyType);
    _city.text = property.cityName;
    _area.text = property.areaName;
    _description.text = property.description;
    _capacity.text = property.capacity?.toString() ?? '';
    _parking.text = property.parkingSpaces?.toString() ?? '';
    _spaces.text = property.spaces
        .map((space) => space['name'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .join(', ');
    _powerBackup = property.powerBackup;
    _accessible = property.accessible;
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _area.dispose();
    _exactAddress.dispose();
    _description.dispose();
    _capacity.dispose();
    _parking.dispose();
    _spaces.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_operations == null && !_loaded) _seedPreview();
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_error != null && !_loaded) {
      return CoreEmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Properties unavailable',
        message: _error!,
        actionLabel: 'Try again',
        onAction: _loadProperty,
      );
    }
    final colors = context.appColors;
    return LocationTwoColumn(
      left: LocationSectionCard(
        title: _propertyId == null ? 'Create property' : 'Edit property',
        icon: Icons.add_location_alt_outlined,
        selected: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StepWizardIndicator(currentStep: _step - 1, totalSteps: 3),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusChip(label: 'STEP $_step OF 3', color: colors.goldMid),
                StatusChip(
                  label: readableLocationStatus(_propertyStatus ?? 'new'),
                  color: _propertyStatus == 'published'
                      ? colors.success
                      : colors.infoBlue,
                ),
                StatusChip(
                  label: 'EXACT ADDRESS PRIVATE',
                  icon: Icons.lock_outline_rounded,
                  color: colors.infoPurple,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _stepContent(),
            if (_error != null) ...[
              const SizedBox(height: 10),
              InlineNotice(
                icon: Icons.error_outline_rounded,
                message: 'Could not save: $_error',
                tone: CoreStatusTone.danger,
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: CoreSecondaryButton(
                    icon: Icons.arrow_back_rounded,
                    label: _step == 1 ? 'Dashboard' : 'Back',
                    compact: true,
                    onTap: _saving
                        ? null
                        : _step == 1
                            ? () => Navigator.pushNamed(
                                  context,
                                  LocationOwnerRoutes.home,
                                )
                            : () => setState(() => _step -= 1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CorePrimaryButton(
                    icon: _step == 3
                        ? Icons.save_outlined
                        : Icons.arrow_forward_rounded,
                    label: _step == 3
                        ? (_saving ? 'Saving...' : 'Save draft')
                        : 'Continue',
                    compact: true,
                    onTap: _saving ? null : _continue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      right: Column(
        children: [
          LocationSectionCard(
            title: 'Public preview',
            icon: Icons.visibility_outlined,
            tone: LocationTone.blue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocationMediaFrame(
                  imageUrl: _operations == null
                      ? LocationOwnerDemoStore.instance.activeProperty.imageUrl
                      : _coverImageUrl,
                  title:
                      _name.text.trim().isEmpty ? 'Property name' : _name.text,
                  badge: '${_type.toUpperCase()} · ${_area.text}',
                  fallbackIcon: Icons.location_city_outlined,
                  aspectRatio: 16 / 10,
                  compact: true,
                ),
                const SizedBox(height: 12),
                LocationInfoRow(
                  icon: Icons.place_outlined,
                  label: 'Public area',
                  value: [_area.text, _city.text]
                      .where((value) => value.trim().isNotEmpty)
                      .join(', '),
                ),
                LocationInfoRow(
                  icon: Icons.groups_2_outlined,
                  label: 'Crew capacity',
                  value: _capacity.text.isEmpty ? 'Not set' : _capacity.text,
                ),
                LocationInfoRow(
                  icon: Icons.dashboard_customize_outlined,
                  label: 'Shoot spaces',
                  value: '${_spaceNames().length}',
                ),
                Text(
                  'The public profile shows the area only. The exact address remains private until the booking workflow allows access.',
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LocationSectionCard(
            title: 'Publication',
            icon: Icons.public_outlined,
            tone: LocationTone.green,
            child: Column(
              children: [
                LocationInfoRow(
                  icon: Icons.photo_library_outlined,
                  label: 'New media',
                  value: '${_mediaFileIds.length} attached',
                ),
                LocationInfoRow(
                  icon: Icons.price_change_outlined,
                  label: 'Rates',
                  value: 'Managed separately',
                ),
                LocationInfoRow(
                  icon: Icons.rule_folder_outlined,
                  label: 'Rules',
                  value: 'Managed separately',
                ),
                const SizedBox(height: 8),
                CorePrimaryButton(
                  icon: Icons.publish_outlined,
                  label: _saving ? 'Publishing...' : 'Publish property',
                  compact: true,
                  onTap: _saving ? null : () => _save(publish: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepContent() {
    return switch (_step) {
      1 => Column(
          children: [
            CoreTextField(
              controller: _name,
              label: 'Property name',
              icon: Icons.location_city_outlined,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            CoreDropdownField<String>(
              value: _type,
              values: const [
                'Home',
                'Studio',
                'Office',
                'Farm',
                'Restaurant',
                'Rooftop',
                'Other',
              ],
              label: 'Property type',
              icon: Icons.category_outlined,
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: 10),
            UploadCard(
              title: _uploading ? 'Uploading photos...' : 'Property photos',
              subtitle: _mediaNames.isEmpty
                  ? 'Add clear daylight and night images'
                  : _mediaNames.join(', '),
              uploaded: _mediaNames.isNotEmpty,
              onTap: _uploading ? null : _pickMedia,
            ),
          ],
        ),
      2 => Column(
          children: [
            CoreTextField(
              controller: _city,
              label: 'City',
              icon: Icons.location_city_outlined,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            CoreTextField(
              controller: _area,
              label: 'Public area',
              icon: Icons.map_outlined,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            CoreTextField(
              controller: _exactAddress,
              label: _propertyId == null
                  ? 'Exact address'
                  : 'Replace exact address (optional)',
              icon: Icons.lock_outline_rounded,
            ),
            const SizedBox(height: 10),
            CoreTextField(
              controller: _description,
              label: 'Production description',
              icon: Icons.notes_outlined,
              maxLines: 3,
            ),
          ],
        ),
      _ => Column(
          children: [
            CoreTextField(
              controller: _spaces,
              label: 'Shoot spaces',
              icon: Icons.dashboard_customize_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            CoreTextField(
              controller: _capacity,
              label: 'Maximum crew capacity',
              icon: Icons.groups_2_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            CoreTextField(
              controller: _parking,
              label: 'Parking spaces',
              icon: Icons.local_parking_outlined,
              keyboardType: TextInputType.number,
            ),
            SwitchListTile.adaptive(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: _powerBackup,
              onChanged: (value) => setState(() => _powerBackup = value),
              title: const Text('Power backup available'),
            ),
            SwitchListTile.adaptive(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: _accessible,
              onChanged: (value) => setState(() => _accessible = value),
              title: const Text('Accessible for equipment movement'),
            ),
          ],
        ),
    };
  }

  void _continue() {
    if (!_validateStep()) return;
    if (_step < 3) {
      setState(() => _step += 1);
      return;
    }
    _save(publish: false);
  }

  bool _validateStep() {
    final message = switch (_step) {
      1 when _name.text.trim().length < 2 => 'Enter a property name',
      2 when _city.text.trim().isEmpty => 'Enter the city',
      2 when _area.text.trim().isEmpty => 'Enter the public area',
      2 when _propertyId == null && _exactAddress.text.trim().isEmpty =>
        'Enter the private exact address',
      2 when _description.text.trim().length < 10 =>
        'Add a production description of at least 10 characters',
      3 when (int.tryParse(_capacity.text.trim()) ?? 0) <= 0 =>
        'Enter a valid crew capacity',
      3 when _spaceNames().isEmpty => 'Add at least one shoot space',
      _ => null,
    };
    if (message != null) locationSnack(context, message);
    return message == null;
  }

  Future<void> _save({required bool publish}) async {
    final originalStep = _step;
    for (var step = 1; step <= 3; step += 1) {
      _step = step;
      if (!_validateStep()) {
        setState(() {});
        return;
      }
    }
    _step = originalStep;
    final operations = _operations;
    if (operations == null) {
      LocationOwnerDemoStore.instance.submitListing();
      locationSnack(
        context,
        publish ? 'Preview property published' : 'Preview draft saved',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final property = _propertyId == null
          ? await operations.createLocationProperty(
              name: _name.text.trim(),
              propertyType: _apiType(_type),
              areaName: _area.text.trim(),
              publicAddress: '${_area.text.trim()}, ${_city.text.trim()}',
              privateAddress: _exactAddress.text.trim(),
              description: _description.text.trim(),
              capacity: int.tryParse(_capacity.text.trim()),
              parkingSpaces: int.tryParse(_parking.text.trim()),
              powerBackup: _powerBackup,
              accessible: _accessible,
              status: publish ? 'published' : 'draft',
            )
          : await operations.updateLocationProperty(
              propertyId: _propertyId!,
              name: _name.text.trim(),
              propertyType: _apiType(_type),
              areaName: _area.text.trim(),
              publicAddress: '${_area.text.trim()}, ${_city.text.trim()}',
              privateAddress: _exactAddress.text.trim().isEmpty
                  ? null
                  : _exactAddress.text.trim(),
              description: _description.text.trim(),
              capacity: int.tryParse(_capacity.text.trim()),
              parkingSpaces: int.tryParse(_parking.text.trim()),
              powerBackup: _powerBackup,
              accessible: _accessible,
              status: publish ? 'published' : 'draft',
            );
      _propertyId = property.publicId;
      LocationOwnerDemoStore.instance.setActiveLiveProperty(property.publicId);
      await _createMissingSpaces(operations, property);
      if (publish) await _publishWithMediaRetry(operations, property);
      final refreshed = await operations.locationProperties(force: true);
      final active = activeLocationProperty(refreshed);
      if (active != null) _applyProperty(active);
      if (!mounted) return;
      locationSnack(
        context,
        publish ? 'Property published to discovery' : 'Property draft saved',
      );
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = locationApiMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _createMissingSpaces(
    OperationsController operations,
    LocationPropertyDto property,
  ) async {
    final existing = property.spaces
        .map((space) => (space['name'] as String? ?? '').toLowerCase())
        .toSet();
    final missing = _spaceNames()
        .where((name) => !existing.contains(name.toLowerCase()))
        .toList();
    for (final name in missing) {
      await operations.createLocationSpace(
        property.publicId,
        {
          'name': name,
          'space_type': 'production_area',
          'capacity': int.tryParse(_capacity.text.trim()),
        },
        refresh: false,
      );
    }
  }

  Future<void> _publishWithMediaRetry(
    OperationsController operations,
    LocationPropertyDto property,
  ) async {
    ApiException? lastError;
    for (var attempt = 0; attempt < 6; attempt += 1) {
      try {
        await operations.publishLocationListing(
          propertyId: property.publicId,
          title: _name.text.trim(),
          summary: _description.text.trim(),
          fileIds: _mediaFileIds,
        );
        return;
      } on ApiException catch (error) {
        lastError = error;
        final waitingForMedia = _mediaFileIds.isNotEmpty &&
            (error.fields.containsKey('file_ids') ||
                error.message.toLowerCase().contains('ready') ||
                error.message.toLowerCase().contains('clean'));
        if (!waitingForMedia || attempt == 5) rethrow;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
    throw lastError ??
        const ApiException(
          code: 'location.publish_failed',
          message: 'The property could not be published.',
        );
  }

  Future<void> _pickMedia() async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null) {
      locationSnack(context, 'Sign in to upload property photos');
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    final files =
        result?.files.where((file) => file.bytes != null).take(12).toList() ??
            const <PlatformFile>[];
    if (files.isEmpty) return;
    setState(() => _uploading = true);
    try {
      for (final file in files) {
        final uploaded = await auth.uploadFile(
          purpose: 'location_media',
          file: PickedFileData(
            name: file.name,
            mimeType: _imageMimeType(file.extension),
            bytes: file.bytes!,
          ),
        );
        _mediaFileIds.add(uploaded.publicId);
        _mediaNames.add(file.name);
      }
      if (!mounted) return;
      locationSnack(context, '${files.length} property photos uploaded');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = locationApiMessage(error));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _seedPreview() {
    if (_loaded) return;
    final property = LocationOwnerDemoStore.instance.activeProperty;
    _name.text = property.name;
    _type = property.type;
    _city.text = property.city;
    _area.text = property.area;
    _exactAddress.text = 'Private address';
    _description.text =
        'Production-ready property with flexible interior and exterior areas.';
    _capacity.text = '${property.capacity}';
    _parking.text = '${property.parking}';
    _spaces.text = 'Living room, kitchen, driveway, rooftop';
    _powerBackup = property.powerBackup;
    _accessible = property.accessible;
    _loaded = true;
  }

  List<String> _spaceNames() {
    return _spaces.text
        .split(',')
        .map((name) => name.trim())
        .where((name) => name.length >= 2)
        .toSet()
        .toList();
  }

  String _apiType(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'\s+'), '_');

  String _displayType(String value) {
    final normalized = readableLocationStatus(value);
    return {
      'Home',
      'Studio',
      'Office',
      'Farm',
      'Restaurant',
      'Rooftop',
      'Other',
    }.contains(normalized)
        ? normalized
        : 'Other';
  }

  String _imageMimeType(String? extension) {
    return switch (extension?.toLowerCase()) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}
