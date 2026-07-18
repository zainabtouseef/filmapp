import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/operations/operations_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/location_owner_demo_data.dart';
import '../routes/location_owner_routes.dart';
import '../widgets/location_owner_components.dart';

class LO02LocationListingWizardScreen extends StatefulWidget {
  const LO02LocationListingWizardScreen({super.key});

  @override
  State<LO02LocationListingWizardScreen> createState() =>
      _LO02LocationListingWizardScreenState();
}

class _LO02LocationListingWizardScreenState
    extends State<LO02LocationListingWizardScreen> {
  final _city = TextEditingController();
  final _area = TextEditingController();
  final _exactAddress = TextEditingController();
  final _capacity = TextEditingController();
  final _parking = TextEditingController();
  final _areas = TextEditingController();

  String _type = 'Home';
  bool _photosUploaded = true;
  bool _videoUploaded = false;
  String? _cityError;
  String? _areaError;
  String? _addressError;

  @override
  void initState() {
    super.initState();
    final store = LocationOwnerDemoStore.instance;
    final property = store.activeProperty;
    _type = property.type;
    _city.text =
        store.listingCity.isNotEmpty ? store.listingCity : property.city;
    _area.text =
        store.listingArea.isNotEmpty ? store.listingArea : property.area;
    _exactAddress.text = store.listingExactAddress.isNotEmpty
        ? store.listingExactAddress
        : 'House 42, secure lane, ${property.area}';
    _capacity.text = store.listingCapacity.isNotEmpty
        ? store.listingCapacity
        : property.capacity.toString();
    _parking.text = store.listingParking.isNotEmpty
        ? store.listingParking
        : property.parking.toString();
    _areas.text = store.listingAvailableAreas.isNotEmpty
        ? store.listingAvailableAreas
        : 'Living room, kitchen, driveway, rooftop';
  }

  @override
  void dispose() {
    _city.dispose();
    _area.dispose();
    _exactAddress.dispose();
    _capacity.dispose();
    _parking.dispose();
    _areas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = LocationOwnerDemoStore.instance;
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return LocationTwoColumn(
          left: LocationSectionCard(
            title: 'Listing wizard',
            icon: Icons.add_location_alt_outlined,
            selected: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StepWizardIndicator(
                  currentStep: store.listingStep - 1,
                  totalSteps: 3,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusChip(
                      label: 'STEP ${store.listingStep} OF 3',
                      color: colors.goldMid,
                    ),
                    StatusChip(
                      label: store.listingSubmitted
                          ? 'SUBMITTED FOR MODERATION'
                          : 'DRAFT SAVED',
                      color: store.listingSubmitted
                          ? colors.success
                          : colors.infoBlue,
                    ),
                    StatusChip(
                      label: store.exactAddressEncrypted
                          ? 'ADDRESS ENCRYPTED'
                          : 'ADDRESS VISIBLE AFTER CONTRACT',
                      color: colors.infoPurple,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _stepContent(store),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: CoreSecondaryButton(
                        icon: Icons.arrow_back_rounded,
                        label: 'Back',
                        compact: true,
                        onTap: store.listingStep == 1
                            ? () => Navigator.pushNamed(
                                  context,
                                  LocationOwnerRoutes.home,
                                )
                            : () => store.setListingStep(store.listingStep - 1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CorePrimaryButton(
                        icon: store.listingStep == 3
                            ? Icons.verified_outlined
                            : Icons.arrow_forward_rounded,
                        label: store.listingStep == 3 ? 'Submit' : 'Continue',
                        compact: true,
                        onTap: () => _advance(store),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocationMediaFrame(
                      imageUrl: store.activeProperty.imageUrl,
                      title: store.activeProperty.name,
                      badge: '${_type.toUpperCase()} - ${_area.text}',
                      fallbackIcon: Icons.location_city_outlined,
                      aspectRatio: 16 / 10,
                      compact: true,
                    ),
                    const SizedBox(height: 12),
                    LocationInfoRow(
                      icon: Icons.place_outlined,
                      label: 'Public area',
                      value: '${_area.text}, ${_city.text}',
                    ),
                    LocationInfoRow(
                      icon: Icons.groups_2_outlined,
                      label: 'Capacity',
                      value: '${_capacity.text} crew',
                    ),
                    LocationInfoRow(
                      icon: Icons.local_parking_outlined,
                      label: 'Parking',
                      value: '${_parking.text} vehicles',
                    ),
                    Text(
                      'The exact address is encrypted and only becomes visible after a verified contract handover.',
                      style: AppTextStyles.smallMeta.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              LocationSectionCard(
                title: 'Moderation route',
                icon: Icons.admin_panel_settings_outlined,
                child: Column(
                  children: [
                    LocationInfoRow(
                      icon: Icons.fact_check_outlined,
                      label: 'Admin review',
                      value: 'SA-05 Listings',
                    ),
                    LocationInfoRow(
                      icon: Icons.search_outlined,
                      label: 'Director search',
                      value: 'DP-06 Locations',
                    ),
                    CoreSecondaryButton(
                      icon: Icons.save_outlined,
                      label: 'Save draft',
                      compact: true,
                      onTap: () {
                        store.saveListingDraft(
                          city: _city.text.trim(),
                          area: _area.text.trim(),
                          exactAddress: _exactAddress.text.trim(),
                          capacity: _capacity.text.trim(),
                          parking: _parking.text.trim(),
                          availableAreas: _areas.text.trim(),
                        );
                        locationSnack(context, 'Listing draft saved');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _stepContent(LocationOwnerDemoStore store) {
    return switch (store.listingStep) {
      1 => _TypeAndMediaStep(
          type: _type,
          onTypeChanged: (value) => setState(() => _type = value ?? _type),
          photosUploaded: _photosUploaded,
          videoUploaded: _videoUploaded,
          onPhotosTap: () {
            setState(() => _photosUploaded = true);
            locationSnack(context, 'Property photos attached');
          },
          onVideoTap: () {
            setState(() => _videoUploaded = true);
            locationSnack(context, 'Walkthrough video attached');
          },
        ),
      2 => Column(
          children: [
            CoreTextField(
              controller: _city,
              label: 'City',
              icon: Icons.location_city_outlined,
              errorText: _cityError,
              onChanged: (_) => setState(() => _cityError = null),
            ),
            const SizedBox(height: 10),
            CoreTextField(
              controller: _area,
              label: 'Public area',
              icon: Icons.map_outlined,
              errorText: _areaError,
              onChanged: (_) => setState(() => _areaError = null),
            ),
            const SizedBox(height: 10),
            CoreTextField(
              controller: _exactAddress,
              label: 'Exact address',
              icon: Icons.lock_outline_rounded,
              errorText: _addressError,
              onChanged: (_) => setState(() => _addressError = null),
            ),
            SwitchListTile.adaptive(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: store.exactAddressEncrypted,
              onChanged: store.setExactAddressEncrypted,
              title: const Text('Store exact address encrypted'),
              subtitle: Text(
                'Public listing only shows city and area.',
                style: AppTextStyles.smallMeta.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      _ => Column(
          children: [
            CoreTextField(
              controller: _areas,
              label: 'Available areas',
              icon: Icons.dashboard_customize_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            CoreTextField(
              controller: _capacity,
              label: 'Crew capacity',
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
              value: store.listingPowerBackup,
              onChanged: store.setListingPowerBackup,
              title: const Text('Power backup available'),
            ),
            SwitchListTile.adaptive(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: store.listingAccessible,
              onChanged: store.setListingAccessible,
              title: const Text('Accessible for equipment movement'),
            ),
          ],
        ),
    };
  }

  Future<void> _advance(LocationOwnerDemoStore store) async {
    if (store.listingStep == 1) {
      if (!_photosUploaded) {
        locationSnack(context, 'Attach at least one property photo');
        return;
      }
      store.setListingStep(2);
      return;
    }
    if (store.listingStep == 2) {
      final valid = _validateAddress();
      if (!valid) return;
      store.setListingStep(3);
      return;
    }
    final operations = OperationsScope.maybeOf(context);
    if (operations != null) {
      try {
        final property = await operations.createLocationProperty(
          name: '${_area.text.trim()} ${_type.toLowerCase()} location',
          propertyType: _type.toLowerCase().replaceAll(' ', '_'),
          areaName: _area.text.trim(),
          publicAddress: '${_area.text.trim()}, ${_city.text.trim()}',
          privateAddress: _exactAddress.text.trim(),
          description: _areas.text.trim(),
          capacity: int.tryParse(_capacity.text.trim()),
          parkingSpaces: int.tryParse(_parking.text.trim()),
          powerBackup: store.listingPowerBackup,
          accessible: store.listingAccessible,
          status: 'draft',
        );
        await operations.createLocationSpace(property.publicId, {
          'name': _areas.text.trim().split(',').first.trim().isEmpty
              ? 'Main shoot area'
              : _areas.text.trim().split(',').first.trim(),
          'space_type': 'interior',
          'capacity': int.tryParse(_capacity.text.trim()),
          'description': _areas.text.trim(),
        });
        await operations.createLocationPricing(property.publicId, {
          'label': 'Day shoot',
          'amount_minor': 15000000,
          'currency': 'PKR',
          'unit': 'day',
          'enabled': true,
        });
        await operations.createLocationRule(property.publicId, {
          'rule_type': 'noise',
          'label': 'Noise after 10 PM requires approval',
          'allowed': false,
        });
        if (!mounted) return;
        locationSnack(context, 'Live property ${property.publicId} created');
      } catch (error) {
        if (!mounted) return;
        locationSnack(context, 'Live save skipped: $error');
      }
    }
    if (!mounted) return;
    store.submitListing();
    showCoreSuccessDialog(
      context,
      title: 'Listing submitted',
      message:
          'Your location listing is ready for moderation and director discovery.',
      buttonLabel: 'Open calendar',
      onDone: () => Navigator.pushNamed(context, LocationOwnerRoutes.calendar),
    );
  }

  bool _validateAddress() {
    setState(() {
      _cityError = _city.text.trim().isEmpty ? 'City is required' : null;
      _areaError = _area.text.trim().isEmpty ? 'Area is required' : null;
      _addressError = _exactAddress.text.trim().isEmpty
          ? 'Exact address is required'
          : null;
    });
    return _cityError == null && _areaError == null && _addressError == null;
  }
}

class _TypeAndMediaStep extends StatelessWidget {
  final String type;
  final ValueChanged<String?> onTypeChanged;
  final bool photosUploaded;
  final bool videoUploaded;
  final VoidCallback onPhotosTap;
  final VoidCallback onVideoTap;

  const _TypeAndMediaStep({
    required this.type,
    required this.onTypeChanged,
    required this.photosUploaded,
    required this.videoUploaded,
    required this.onPhotosTap,
    required this.onVideoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CoreDropdownField<String>(
          value: type,
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
          onChanged: onTypeChanged,
        ),
        const SizedBox(height: 10),
        UploadCard(
          title: 'Property photos',
          subtitle: 'Upload 5-12 daylight and night frames',
          uploaded: photosUploaded,
          onTap: onPhotosTap,
        ),
        const SizedBox(height: 10),
        UploadCard(
          title: 'Walkthrough video',
          subtitle: 'Optional 30-60 second video preview',
          uploaded: videoUploaded,
          onTap: onVideoTap,
        ),
      ],
    );
  }
}
