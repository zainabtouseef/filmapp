import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/profile/profile_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/uploads/upload_repository.dart';
import '../../../shared/widgets/marketplace_pricing_preference_panel.dart';
import '../widgets/crew_services_components.dart';

/// CR-02 Service Profile
///
/// A crew provider's public identity: photo, cover, bio and social links.
/// Directors see this alongside the provider's portfolio and open
/// applications. This lives on the generic `UserProfile` row (same as the
/// Location Owner and Media/Equipment provider profiles) — no dedicated
/// crew profile model needed.
class CR02ServiceProfileScreen extends StatefulWidget {
  const CR02ServiceProfileScreen({super.key});

  @override
  State<CR02ServiceProfileScreen> createState() =>
      _CR02ServiceProfileScreenState();
}

class _CR02ServiceProfileScreenState extends State<CR02ServiceProfileScreen> {
  late final TextEditingController city;
  late final TextEditingController website;
  late final TextEditingController bio;
  late final TextEditingController instagram;
  late final TextEditingController tiktok;

  String? error;
  String? remoteStatus;
  bool loadingRemote = false;
  bool savingRemote = false;
  bool attemptedRemoteLoad = false;
  List<ProfileCity> supportedCities = const [];
  String? avatarUrl;
  bool uploadingAvatar = false;
  String? avatarError;
  String? coverUrl;
  bool uploadingCover = false;
  String? coverError;

  @override
  void initState() {
    super.initState();
    city = TextEditingController();
    website = TextEditingController();
    bio = TextEditingController();
    instagram = TextEditingController();
    tiktok = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!attemptedRemoteLoad) {
      attemptedRemoteLoad = true;
      _loadRemoteProfile();
    }
  }

  @override
  void dispose() {
    city.dispose();
    website.dispose();
    bio.dispose();
    instagram.dispose();
    tiktok.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CrewTwoColumn(
      left: Column(
        children: [
          const MarketplacePricingPreferencePanel(
            listingTypes: {'crew'},
            title: 'Crew marketplace pricing',
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Build your public service profile. Directors see this alongside your portfolio and requirement applications.',
                  style: AppTextStyles.smallMeta.copyWith(
                    color: context.appColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                if (loadingRemote) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(minHeight: 2),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          CrewSectionCard(
            title: 'Photos',
            icon: Icons.photo_camera_outlined,
            selected: true,
            child: Column(
              children: [
                _avatarField(),
                const SizedBox(height: 14),
                _coverField(),
              ],
            ),
          ),
          const SizedBox(height: 10),
          CrewSectionCard(
            title: 'Identity',
            icon: Icons.badge_outlined,
            child: Column(
              children: [
                CoreTextField(
                  controller: city,
                  label: 'City',
                  icon: Icons.location_on_outlined,
                  errorText: _fieldError(city),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                CoreTextField(
                  controller: website,
                  label: 'Website',
                  icon: Icons.language_outlined,
                  keyboardType: TextInputType.url,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                CoreTextField(
                  controller: bio,
                  label: 'Bio / services offered',
                  icon: Icons.history_edu_outlined,
                  maxLines: 3,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          CrewSectionCard(
            title: 'Social',
            icon: Icons.apartment_outlined,
            child: Row(
              children: [
                Expanded(
                  child: CoreTextField(
                    controller: instagram,
                    label: 'Instagram',
                    icon: Icons.alternate_email_rounded,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CoreTextField(
                    controller: tiktok,
                    label: 'TikTok',
                    icon: Icons.music_note_rounded,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                error!,
                style: AppTextStyles.smallMeta.copyWith(
                  color: context.appColors.danger,
                ),
              ),
            ),
          ],
          if (remoteStatus != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                remoteStatus!,
                style: AppTextStyles.smallMeta.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          CorePrimaryButton(
            icon: Icons.verified_outlined,
            label: 'Save profile',
            compact: true,
            loading: savingRemote,
            onTap: savingRemote ? null : _submit,
          ),
        ],
      ),
      right: _ProfileSummary(
        avatarUrl: avatarUrl,
        city: city.text,
        instagram: instagram.text,
        tiktok: tiktok.text,
        bio: bio.text,
      ),
    );
  }

  Widget _avatarField() {
    final colors = context.appColors;
    return Row(
      children: [
        GestureDetector(
          onTap: uploadingAvatar ? null : _pickAvatar,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.softSurface,
              border: Border.all(color: colors.border),
              image: avatarUrl == null
                  ? null
                  : DecorationImage(
                      image: NetworkImage(avatarUrl!),
                      fit: BoxFit.cover,
                    ),
            ),
            child: uploadingAvatar
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : avatarUrl == null
                    ? Icon(Icons.add_a_photo_outlined,
                        color: colors.goldDark, size: 22)
                    : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                avatarUrl == null ? 'Add profile photo' : 'Profile photo',
                style: AppTextStyles.cardLabel.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Shown to directors browsing crew requirements.',
                style: AppTextStyles.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              if (avatarError != null) ...[
                const SizedBox(height: 3),
                Text(
                  avatarError!,
                  style: AppTextStyles.caption.copyWith(color: colors.danger),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _coverField() {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: uploadingCover ? null : _pickCover,
          child: AspectRatio(
            aspectRatio: 3.2,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: colors.softSurface,
                border: Border.all(color: colors.border),
                image: coverUrl == null
                    ? null
                    : DecorationImage(
                        image: NetworkImage(coverUrl!),
                        fit: BoxFit.cover,
                      ),
              ),
              child: uploadingCover
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : coverUrl == null
                      ? Icon(
                          Icons.add_photo_alternate_outlined,
                          color: colors.goldDark,
                          size: 28,
                        )
                      : null,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          coverUrl == null ? 'Add profile cover' : 'Profile cover',
          style: AppTextStyles.cardLabel.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (coverError != null) ...[
          const SizedBox(height: 3),
          Text(
            coverError!,
            style: AppTextStyles.caption.copyWith(color: colors.danger),
          ),
        ],
      ],
    );
  }

  String? _fieldError(TextEditingController controller) {
    if (error == null) return null;
    return controller.text.trim().isEmpty ? error : null;
  }

  Future<void> _loadRemoteProfile() async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null || !auth.isAuthenticated) return;
    setState(() {
      loadingRemote = true;
      remoteStatus = 'Loading saved CineConnect profile…';
    });
    try {
      final cities = await auth.cities();
      final profile = await auth.myProfile();
      if (!mounted) return;
      setState(() {
        supportedCities = cities;
        avatarUrl = profile.avatarFile?.publicUrl;
        coverUrl = profile.coverFile?.publicUrl;
        if ((profile.city?.name ?? '').trim().isNotEmpty) {
          city.text = profile.city!.name;
        }
        website.text = profile.websiteUrl ?? '';
        bio.text = profile.bio ?? '';
        instagram.text = profile.socialLinks['instagram']?.toString() ?? '';
        tiktok.text = profile.socialLinks['tiktok']?.toString() ?? '';
        remoteStatus = 'Synced with backend profile';
      });
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() {
        remoteStatus = 'Backend profile unavailable: ${exception.message}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        remoteStatus = 'Backend profile is currently unreachable';
      });
    } finally {
      if (mounted) {
        setState(() => loadingRemote = false);
      }
    }
  }

  Future<void> _pickAvatar() async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null || !auth.isAuthenticated) {
      crewSnack(context, 'Sign in to upload a profile photo');
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    final item = result?.files.single;
    final bytes = item?.bytes;
    if (item == null || bytes == null) return;
    setState(() {
      uploadingAvatar = true;
      avatarError = null;
    });
    try {
      final uploaded = await auth.uploadFile(
        purpose: 'profile_media',
        file: PickedFileData(
          name: item.name,
          mimeType: switch (item.extension?.toLowerCase()) {
            'png' => 'image/png',
            'webp' => 'image/webp',
            _ => 'image/jpeg',
          },
          bytes: bytes,
        ),
      );
      final profile = await auth.updateMyProfile(
        bio: bio.text.trim(),
        cityId: _matchedCity()?.publicId,
        visibility: 'public',
        websiteUrl: website.text.trim(),
        avatarFileId: uploaded.publicId,
      );
      if (!mounted) return;
      setState(() => avatarUrl = profile.avatarFile?.publicUrl);
      crewSnack(context, 'Profile photo updated');
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() => avatarError = _apiErrorMessage(exception));
    } catch (_) {
      if (!mounted) return;
      setState(() => avatarError = 'Could not upload the photo. Try again.');
    } finally {
      if (mounted) setState(() => uploadingAvatar = false);
    }
  }

  Future<void> _pickCover() async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null || !auth.isAuthenticated) {
      crewSnack(context, 'Sign in to upload a profile cover');
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    final item = result?.files.single;
    final bytes = item?.bytes;
    if (item == null || bytes == null) return;
    setState(() {
      uploadingCover = true;
      coverError = null;
    });
    try {
      final uploaded = await auth.uploadFile(
        purpose: 'profile_media',
        file: PickedFileData(
          name: item.name,
          mimeType: switch (item.extension?.toLowerCase()) {
            'png' => 'image/png',
            'webp' => 'image/webp',
            _ => 'image/jpeg',
          },
          bytes: bytes,
        ),
      );
      final profile = await auth.updateMyProfile(
        bio: bio.text.trim(),
        cityId: _matchedCity()?.publicId,
        visibility: 'public',
        websiteUrl: website.text.trim(),
        coverFileId: uploaded.publicId,
      );
      if (!mounted) return;
      setState(() => coverUrl = profile.coverFile?.publicUrl);
      crewSnack(context, 'Profile cover updated');
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() => coverError = exception.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => coverError = 'Could not upload the cover. Try again.');
    } finally {
      if (mounted) setState(() => uploadingCover = false);
    }
  }

  String _apiErrorMessage(ApiException exception) {
    final fieldMessages = exception.fields.values
        .expand((messages) => messages)
        .map((message) => message.trim())
        .where((message) => message.isNotEmpty)
        .toList();
    if (fieldMessages.isNotEmpty) return fieldMessages.join(' ');
    return exception.message;
  }

  Future<void> _submit() async {
    if (city.text.trim().isEmpty) {
      setState(() => error = 'Required');
      return;
    }
    final matchedCity = _matchedCity();
    if (supportedCities.isNotEmpty && matchedCity == null) {
      setState(() {
        error = 'Choose a supported city';
        remoteStatus =
            'Supported cities: ${supportedCities.map((item) => item.name).join(', ')}';
      });
      return;
    }
    final auth = AuthScope.maybeOf(context);
    if (auth == null || !auth.isAuthenticated) {
      setState(() => error = 'Sign in required');
      crewSnack(context, 'Sign in to save your profile');
      return;
    }
    setState(() {
      error = null;
      savingRemote = true;
      remoteStatus = 'Saving profile to backend…';
    });
    try {
      await auth.updateMyProfile(
        bio: bio.text.trim(),
        cityId: matchedCity?.publicId,
        visibility: 'public',
        websiteUrl: website.text.trim(),
        socialLinks: _socialLinksForBackend(),
      );
      if (!mounted) return;
      setState(() => remoteStatus = 'Backend profile saved');
      crewSnack(context, 'Service profile saved');
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() {
        error = exception.message;
        remoteStatus = 'Fix the highlighted fields and try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        error = 'Could not reach backend';
        remoteStatus = 'Profile was not saved. Try again when online.';
      });
    } finally {
      if (mounted) {
        setState(() => savingRemote = false);
      }
    }
  }

  ProfileCity? _matchedCity() {
    final value = city.text.trim().toLowerCase();
    for (final item in supportedCities) {
      if (item.name.toLowerCase() == value ||
          item.publicId.toLowerCase() == value) {
        return item;
      }
    }
    return null;
  }

  Map<String, dynamic> _socialLinksForBackend() {
    return {
      if (instagram.text.trim().isNotEmpty) 'instagram': instagram.text.trim(),
      if (tiktok.text.trim().isNotEmpty) 'tiktok': tiktok.text.trim(),
    };
  }
}

class _ProfileSummary extends StatelessWidget {
  final String? avatarUrl;
  final String city;
  final String instagram;
  final String tiktok;
  final String bio;

  const _ProfileSummary({
    this.avatarUrl,
    required this.city,
    required this.instagram,
    required this.tiktok,
    required this.bio,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return CrewSectionCard(
      title: 'Director-facing Profile',
      icon: Icons.visibility_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CrewMediaFrame(
            imageUrl: avatarUrl ?? '',
            title: 'Provider photo',
            badge: 'Draft',
            fallbackIcon: Icons.person_outline_rounded,
            aspectRatio: 4 / 5,
          ),
          const SizedBox(height: 12),
          Text(
            city.isEmpty ? 'City not set' : city,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.sectionHeading.copyWith(
              color: colors.textPrimary,
              fontSize: 18,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
          CrewInfoRow(
            icon: Icons.alternate_email_rounded,
            label: 'Instagram',
            value: instagram.isEmpty ? 'Not connected' : instagram,
          ),
          CrewInfoRow(
            icon: Icons.music_note_rounded,
            label: 'TikTok',
            value: tiktok.isEmpty ? 'Not connected' : tiktok,
          ),
          CrewInfoRow(
            icon: Icons.history_edu_outlined,
            label: 'Bio',
            value: bio.isEmpty ? 'Not set' : bio,
          ),
        ],
      ),
    );
  }
}
