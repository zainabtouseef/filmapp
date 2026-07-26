import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/open_url.dart';
import '../../../core/profile/profile_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/uploads/upload_repository.dart';
import '../../actor_talent/models/actor_talent_models.dart';
import '../../actor_talent/widgets/actor_talent_components.dart';

/// MD-06 Model Profile
///
/// A model's identity/photos/CV/social links live on the same
/// `TalentProfile`/`UserProfile` rows the Actor/Talent portal edits — this
/// screen is a leaner AT-02, without the acting-specific sections (skills,
/// credits, physical details) that aren't relevant to campaign fit here.
class MD06ModelProfileScreen extends StatefulWidget {
  const MD06ModelProfileScreen({super.key});

  @override
  State<MD06ModelProfileScreen> createState() =>
      _MD06ModelProfileScreenState();
}

class _MD06ModelProfileScreenState extends State<MD06ModelProfileScreen> {
  late final TextEditingController stageName;
  late final TextEditingController city;
  late final TextEditingController website;
  late final TextEditingController bio;
  late final TextEditingController instagram;
  late final TextEditingController tiktok;
  late final TextEditingController followers;
  late final TextEditingController agency;

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
  String? resumeUrl;
  String? resumeFileName;
  bool uploadingResume = false;
  String? resumeError;

  @override
  void initState() {
    super.initState();
    stageName = TextEditingController();
    city = TextEditingController();
    website = TextEditingController();
    bio = TextEditingController();
    instagram = TextEditingController();
    tiktok = TextEditingController();
    followers = TextEditingController();
    agency = TextEditingController();
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
    stageName.dispose();
    city.dispose();
    website.dispose();
    bio.dispose();
    instagram.dispose();
    tiktok.dispose();
    followers.dispose();
    agency.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ActorTwoColumn(
      left: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Build the public model profile directors and brands see. Photos, CV and social links help you get matched to the right campaigns.',
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
          ActorCollapsibleSection(
            title: 'Photos & CV',
            subtitle: 'Headshot, cover image and resume',
            icon: Icons.photo_camera_outlined,
            initiallyExpanded: true,
            child: Column(
              children: [
                _avatarField(),
                const SizedBox(height: 14),
                _coverField(),
                const SizedBox(height: 14),
                _resumeField(),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ActorCollapsibleSection(
            title: 'Identity',
            subtitle: 'Name, city, website and bio',
            icon: Icons.badge_outlined,
            initiallyExpanded: true,
            child: Column(
              children: [
                CoreTextField(
                  controller: stageName,
                  label: 'Stage name',
                  icon: Icons.theater_comedy_outlined,
                  errorText: _fieldError(stageName),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
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
                  label: 'Portfolio website',
                  icon: Icons.language_outlined,
                  keyboardType: TextInputType.url,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                CoreTextField(
                  controller: bio,
                  label: 'Bio',
                  icon: Icons.history_edu_outlined,
                  maxLines: 3,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ActorCollapsibleSection(
            title: 'Social & Representation',
            subtitle: 'Instagram, TikTok, followers, agency',
            icon: Icons.apartment_outlined,
            tone: ActorTone.purple,
            child: Column(
              children: [
                Row(
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
                const SizedBox(height: 10),
                CoreTextField(
                  controller: followers,
                  label: 'Followers',
                  icon: Icons.people_alt_outlined,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                CoreTextField(
                  controller: agency,
                  label: 'Agency affiliation',
                  icon: Icons.apartment_outlined,
                  onChanged: (_) => setState(() {}),
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
        stageName: stageName.text,
        city: city.text,
        instagram: instagram.text,
        tiktok: tiktok.text,
        followers: followers.text,
        bio: bio.text,
        agency: agency.text,
        completeness: _formCompleteness(),
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
                'Shown to directors and brands on your listing.',
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

  Widget _resumeField() {
    final colors = context.appColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: uploadingResume ? null : _pickResume,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: colors.softSurface,
              border: Border.all(color: colors.border),
            ),
            child: Center(
              child: uploadingResume
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      resumeUrl == null
                          ? Icons.upload_file_outlined
                          : Icons.picture_as_pdf_outlined,
                      color: colors.goldDark,
                      size: 26,
                    ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resumeUrl == null ? 'Add CV / resume (PDF)' : 'CV / resume',
                style: AppTextStyles.cardLabel.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                resumeFileName ?? 'Shown to directors and brands.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              if (resumeUrl != null) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => openUrlInNewTab(resumeUrl!),
                  child: Text(
                    'View uploaded file',
                    style: AppTextStyles.caption.copyWith(
                      color: colors.infoBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              if (resumeError != null) ...[
                const SizedBox(height: 3),
                Text(
                  resumeError!,
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
        const SizedBox(height: 2),
        Text(
          'Use a wide image that represents your look.',
          style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
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
      final talent = await auth.talentProfile();
      if (!mounted) return;
      setState(() {
        supportedCities = cities;
        avatarUrl = profile.avatarFile?.publicUrl;
        coverUrl = profile.coverFile?.publicUrl;
        resumeUrl = talent.resumeFile?.publicUrl;
        resumeFileName = talent.resumeFile?.originalName;
        if ((talent.screenName ?? '').trim().isNotEmpty) {
          stageName.text = talent.screenName!.trim();
        }
        if ((profile.city?.name ?? '').trim().isNotEmpty) {
          city.text = profile.city!.name;
        }
        website.text = profile.websiteUrl ?? '';
        bio.text = profile.bio ?? '';
        instagram.text = talent.socialLinks['instagram']?.toString() ?? '';
        tiktok.text = talent.socialLinks['tiktok']?.toString() ?? '';
        followers.text = talent.socialLinks['followers']?.toString() ?? '';
        agency.text =
            talent.representation['agency_name']?.toString() ?? '';
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
      actorSnack(context, 'Sign in to upload a profile photo');
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
      actorSnack(context, 'Profile photo updated');
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
      actorSnack(context, 'Sign in to upload a profile cover');
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
      actorSnack(context, 'Profile cover updated');
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

  Future<void> _pickResume() async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null || !auth.isAuthenticated) {
      actorSnack(context, 'Sign in to upload a CV / resume');
      return;
    }
    if (stageName.text.trim().isEmpty) {
      actorSnack(context, 'Add your stage name before uploading a CV / resume');
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    final item = result?.files.single;
    final bytes = item?.bytes;
    if (item == null || bytes == null) return;
    setState(() {
      uploadingResume = true;
      resumeError = null;
    });
    try {
      final uploaded = await auth.uploadFile(
        purpose: 'profile_media',
        file: PickedFileData(
          name: item.name,
          mimeType: 'application/pdf',
          bytes: bytes,
        ),
      );
      final updated = await auth.updateTalentProfile(
        screenName: stageName.text.trim(),
        resumeFileId: uploaded.publicId,
        representation: _representationForBackend(),
        socialLinks: _socialLinksForBackend(),
      );
      if (!mounted) return;
      setState(() {
        resumeUrl = updated.resumeFile?.publicUrl;
        resumeFileName = updated.resumeFile?.originalName;
      });
      actorSnack(context, 'CV / resume updated');
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() => resumeError = _apiErrorMessage(exception));
    } catch (_) {
      if (!mounted) return;
      setState(
          () => resumeError = 'Could not upload the CV / resume. Try again.');
    } finally {
      if (mounted) setState(() => uploadingResume = false);
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
    if (stageName.text.trim().isEmpty || city.text.trim().isEmpty) {
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
      actorSnack(context, 'Sign in to save your profile');
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
      );
      await auth.updateTalentProfile(
        screenName: stageName.text.trim(),
        representation: _representationForBackend(),
        socialLinks: _socialLinksForBackend(),
      );
      if (!mounted) return;
      setState(() => remoteStatus = 'Backend profile saved');
      actorSnack(context, 'Model profile saved');
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

  int _formCompleteness() {
    final fields = [stageName, city, website, bio, instagram, agency];
    final completed =
        fields.where((field) => field.text.trim().isNotEmpty).length;
    return ((completed / fields.length) * 100).round();
  }

  Map<String, dynamic> _representationForBackend() {
    return {
      if (agency.text.trim().isNotEmpty) 'agency_name': agency.text.trim(),
    };
  }

  Map<String, dynamic> _socialLinksForBackend() {
    return {
      if (instagram.text.trim().isNotEmpty) 'instagram': instagram.text.trim(),
      if (tiktok.text.trim().isNotEmpty) 'tiktok': tiktok.text.trim(),
      if (followers.text.trim().isNotEmpty) 'followers': followers.text.trim(),
    };
  }
}

class _ProfileSummary extends StatelessWidget {
  final String? avatarUrl;
  final String stageName;
  final String city;
  final String instagram;
  final String tiktok;
  final String followers;
  final String bio;
  final String agency;
  final int completeness;

  const _ProfileSummary({
    this.avatarUrl,
    required this.stageName,
    required this.city,
    required this.instagram,
    required this.tiktok,
    required this.followers,
    required this.bio,
    required this.agency,
    required this.completeness,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ActorSectionCard(
      title: 'Director & Brand-facing Profile',
      icon: Icons.visibility_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ActorMediaFrame(
            imageUrl: avatarUrl ?? '',
            title: 'Public headshot',
            badge: 'Draft',
            fallbackIcon: Icons.person_outline_rounded,
            aspectRatio: 4 / 5,
          ),
          const SizedBox(height: 12),
          Text(
            stageName.isEmpty ? 'Stage name' : stageName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.sectionHeading.copyWith(
              color: colors.textPrimary,
              fontSize: 18,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            city.isEmpty ? 'City not set' : city,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          ActorProgressMeter(value: completeness),
          ActorInfoRow(
            icon: Icons.alternate_email_rounded,
            label: 'Instagram',
            value: instagram.isEmpty
                ? 'Not connected'
                : '$instagram • ${followers.isEmpty ? 'followers not set' : followers}',
          ),
          ActorInfoRow(
            icon: Icons.music_note_rounded,
            label: 'TikTok',
            value: tiktok.isEmpty ? 'Not connected' : tiktok,
          ),
          ActorInfoRow(
            icon: Icons.history_edu_outlined,
            label: 'Bio',
            value: bio.isEmpty ? 'Not set' : bio,
          ),
          ActorInfoRow(
            icon: Icons.apartment_outlined,
            label: 'Agency',
            value: agency.isEmpty ? 'Independent' : agency,
          ),
        ],
      ),
    );
  }
}
