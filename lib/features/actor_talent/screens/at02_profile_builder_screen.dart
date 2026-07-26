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
import '../models/actor_talent_models.dart';
import '../routes/actor_talent_routes.dart';
import '../widgets/actor_talent_components.dart';

/// AT-02 Profile Builder
class AT02ProfileBuilderScreen extends StatefulWidget {
  const AT02ProfileBuilderScreen({super.key});

  @override
  State<AT02ProfileBuilderScreen> createState() =>
      _AT02ProfileBuilderScreenState();
}

class _AT02ProfileBuilderScreenState extends State<AT02ProfileBuilderScreen> {
  late final TextEditingController stageName;
  late final TextEditingController realName;
  late final TextEditingController city;
  late final TextEditingController languages;
  late final TextEditingController skills;
  late final TextEditingController accents;
  late final TextEditingController specialAbilities;
  late final TextEditingController credits;
  late final TextEditingController training;
  late final TextEditingController instagram;
  late final TextEditingController tiktok;
  late final TextEditingController followers;
  late final TextEditingController website;
  late final TextEditingController workHistory;
  late final TextEditingController ageRange;
  late final TextEditingController height;
  late final TextEditingController genderIdentity;
  late final TextEditingController experienceYears;
  late final TextEditingController unionNote;
  late final TextEditingController agency;
  late final TextEditingController eyeColor;
  late final TextEditingController hairColor;
  String? error;
  String? remoteStatus;
  bool loadingRemote = false;
  bool savingRemote = false;
  bool publishingListing = false;
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
    realName = TextEditingController();
    city = TextEditingController();
    languages = TextEditingController();
    skills = TextEditingController();
    accents = TextEditingController();
    specialAbilities = TextEditingController();
    credits = TextEditingController();
    training = TextEditingController();
    instagram = TextEditingController();
    tiktok = TextEditingController();
    followers = TextEditingController();
    website = TextEditingController();
    workHistory = TextEditingController();
    ageRange = TextEditingController();
    height = TextEditingController();
    genderIdentity = TextEditingController();
    experienceYears = TextEditingController();
    unionNote = TextEditingController();
    agency = TextEditingController();
    eyeColor = TextEditingController();
    hairColor = TextEditingController();
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
    realName.dispose();
    city.dispose();
    languages.dispose();
    skills.dispose();
    accents.dispose();
    specialAbilities.dispose();
    credits.dispose();
    training.dispose();
    instagram.dispose();
    tiktok.dispose();
    followers.dispose();
    website.dispose();
    workHistory.dispose();
    ageRange.dispose();
    height.dispose();
    genderIdentity.dispose();
    experienceYears.dispose();
    unionNote.dispose();
    agency.dispose();
    eyeColor.dispose();
    hairColor.dispose();
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
                  'Build the public casting profile directors use for search, shortlisting and booking decisions. Edit one section at a time — everything saves together.',
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
            subtitle: 'Name, city and website',
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
                  controller: realName,
                  label: 'Account name',
                  icon: Icons.person_outline_rounded,
                  enabled: AuthScope.maybeOf(context)?.isAuthenticated != true,
                  errorText: _fieldError(realName),
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
              ],
            ),
          ),
          const SizedBox(height: 10),
          ActorCollapsibleSection(
            title: 'Bio & Experience',
            subtitle: 'Languages, skills, credits, training',
            icon: Icons.history_edu_outlined,
            tone: ActorTone.blue,
            child: Column(
              children: [
                CoreTextField(
                  controller: workHistory,
                  label: 'Biography and acting experience',
                  icon: Icons.history_edu_outlined,
                  maxLines: 3,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                CoreTextField(
                  controller: languages,
                  label: 'Languages',
                  icon: Icons.translate_rounded,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                CoreTextField(
                  controller: skills,
                  label: 'Acting skills',
                  icon: Icons.local_offer_outlined,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                CoreTextField(
                  controller: credits,
                  label: 'Acting credits (one per line)',
                  icon: Icons.workspace_premium_outlined,
                  maxLines: 3,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                CoreTextField(
                  controller: training,
                  label: 'Education, workshops and training (one per line)',
                  icon: Icons.school_outlined,
                  maxLines: 3,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ActorCollapsibleSection(
            title: 'Physical & Voice',
            subtitle: 'Look, accents, playable age',
            icon: Icons.face_retouching_natural_outlined,
            tone: ActorTone.green,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CoreTextField(
                        controller: ageRange,
                        label: 'Playable age',
                        icon: Icons.face_retouching_natural_outlined,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CoreTextField(
                        controller: height,
                        label: 'Height',
                        icon: Icons.height_outlined,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: CoreTextField(
                        controller: eyeColor,
                        label: 'Eye colour',
                        icon: Icons.visibility_outlined,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CoreTextField(
                        controller: hairColor,
                        label: 'Hair colour',
                        icon: Icons.face_retouching_natural_outlined,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: CoreTextField(
                        controller: accents,
                        label: 'Accents',
                        icon: Icons.record_voice_over_outlined,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CoreTextField(
                        controller: specialAbilities,
                        label: 'Special abilities',
                        icon: Icons.sports_martial_arts_outlined,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: CoreTextField(
                        controller: genderIdentity,
                        label: 'Gender identity',
                        icon: Icons.diversity_1_outlined,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CoreTextField(
                        controller: experienceYears,
                        label: 'Experience (years)',
                        icon: Icons.work_history_outlined,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                CoreTextField(
                  controller: unionNote,
                  label: 'Union / professional membership',
                  icon: Icons.verified_user_outlined,
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
          const SizedBox(height: 8),
          CoreSecondaryButton(
            icon: Icons.travel_explore_outlined,
            label: publishingListing
                ? 'Publishing listing…'
                : 'Publish marketplace listing',
            compact: true,
            onTap: savingRemote || publishingListing
                ? null
                : _publishMarketplaceListing,
          ),
        ],
      ),
      right: _ProfileSummary(
        avatarUrl: avatarUrl,
        stageName: stageName.text,
        city: city.text,
        languages: languages.text,
        instagram: instagram.text,
        tiktok: tiktok.text,
        followers: followers.text,
        workHistory: workHistory.text,
        ageRange: ageRange.text,
        height: height.text,
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
                'Shown to directors on your listing and candidate cards.',
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
                resumeFileName ??
                    'Shown to directors on your stakeholder profile.',
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
          'Use a wide image that represents your casting identity.',
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
    _clearFormValues(auth);
    setState(() {
      loadingRemote = true;
      remoteStatus = 'Loading saved CineConnect profile…';
    });
    try {
      final cities = await auth.cities();
      final profile = await auth.myProfile();
      final talent = await auth.talentProfile();
      if (!mounted) return;
      final loadedLanguages = talent.languages
          .map((item) => item.language)
          .where((item) => item.trim().isNotEmpty)
          .join(', ');
      setState(() {
        supportedCities = cities;
        avatarUrl = profile.avatarFile?.publicUrl;
        coverUrl = profile.coverFile?.publicUrl;
        resumeUrl = talent.resumeFile?.publicUrl;
        resumeFileName = talent.resumeFile?.originalName;
        if ((auth.user?.displayName ?? '').trim().isNotEmpty) {
          realName.text = auth.user!.displayName.trim();
        }
        if ((talent.screenName ?? '').trim().isNotEmpty) {
          stageName.text = talent.screenName!.trim();
        }
        if ((profile.city?.name ?? '').trim().isNotEmpty) {
          city.text = profile.city!.name;
        }
        website.text = profile.websiteUrl ?? '';
        if (loadedLanguages.isNotEmpty) {
          languages.text = loadedLanguages;
        }
        if ((talent.ageRange ?? '').trim().isNotEmpty) {
          ageRange.text = talent.ageRange!.trim();
        }
        if (talent.heightCm != null) {
          height.text = '${talent.heightCm} cm';
        }
        if ((talent.genderIdentity ?? '').trim().isNotEmpty) {
          genderIdentity.text = talent.genderIdentity!.trim();
        }
        if (talent.experienceYears != null) {
          experienceYears.text = '${talent.experienceYears}';
        }
        if ((talent.unionNote ?? '').trim().isNotEmpty) {
          unionNote.text = talent.unionNote!.trim();
        }
        final parsedSkills = _bioValue(profile.bio, 'Skills');
        skills.text =
            talent.skills.isNotEmpty ? talent.skills.join(', ') : parsedSkills;
        accents.text = talent.accents.join(', ');
        specialAbilities.text = talent.specialAbilities.join(', ');
        credits.text = _entryTitles(talent.credits).join('\n');
        training.text = _entryTitles(talent.training).join('\n');
        workHistory.text = _hasStructuredBio(profile.bio)
            ? _bioValue(profile.bio, 'Work history')
            : profile.bio ?? '';
        instagram.text = talent.socialLinks['instagram']?.toString() ??
            _bioValue(profile.bio, 'Instagram');
        tiktok.text = talent.socialLinks['tiktok']?.toString() ?? '';
        followers.text = talent.socialLinks['followers']?.toString() ??
            _bioValue(profile.bio, 'Followers');
        agency.text = talent.representation['agency_name']?.toString() ??
            _bioValue(profile.bio, 'Agency');
        eyeColor.text = talent.physicalDetails['eye_color']?.toString() ?? '';
        hairColor.text = talent.physicalDetails['hair_color']?.toString() ?? '';
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
      // Uploading a new photo saves it as part of the profile right away
      // (same fields _submit() sends) rather than leaving it staged until
      // the next full "Save profile" tap.
      final matchedCity = _matchedCity();
      final profile = await auth.updateMyProfile(
        bio: _bioForBackend(),
        cityId: matchedCity?.publicId,
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
        bio: _bioForBackend(),
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
        languages: _languagesForBackend(),
        ageRange: ageRange.text.trim(),
        genderIdentity: genderIdentity.text.trim(),
        heightCm: _heightCmForBackend(),
        unionNote: unionNote.text.trim(),
        experienceYears: int.tryParse(experienceYears.text.trim()),
        resumeFileId: uploaded.publicId,
        skills: _commaValues(skills.text),
        accents: _commaValues(accents.text),
        specialAbilities: _commaValues(specialAbilities.text),
        physicalDetails: _physicalDetailsForBackend(),
        credits: _lineEntries(credits.text),
        training: _lineEntries(training.text),
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
    if (stageName.text.trim().isEmpty ||
        realName.text.trim().isEmpty ||
        city.text.trim().isEmpty) {
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
        bio: _bioForBackend(),
        cityId: matchedCity?.publicId,
        visibility: 'public',
        websiteUrl: website.text.trim(),
      );
      await auth.updateTalentProfile(
        screenName: stageName.text.trim(),
        languages: _languagesForBackend(),
        ageRange: ageRange.text.trim(),
        genderIdentity: genderIdentity.text.trim(),
        heightCm: _heightCmForBackend(),
        unionNote: unionNote.text.trim(),
        experienceYears: int.tryParse(experienceYears.text.trim()),
        skills: _commaValues(skills.text),
        accents: _commaValues(accents.text),
        specialAbilities: _commaValues(specialAbilities.text),
        physicalDetails: _physicalDetailsForBackend(),
        credits: _lineEntries(credits.text),
        training: _lineEntries(training.text),
        representation: _representationForBackend(),
        socialLinks: _socialLinksForBackend(),
      );
      if (!mounted) return;
      setState(() => remoteStatus = 'Backend profile saved');
      actorSnack(context, 'Casting profile saved');
      Navigator.pushNamed(context, ActorTalentRoutes.portfolio);
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

  Future<void> _publishMarketplaceListing() async {
    if (stageName.text.trim().isEmpty || city.text.trim().isEmpty) {
      setState(() => error = 'Required');
      return;
    }
    final auth = AuthScope.maybeOf(context);
    if (auth == null || !auth.isAuthenticated) {
      actorSnack(context, 'Sign in to publish a marketplace listing');
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
    setState(() {
      error = null;
      publishingListing = true;
      remoteStatus = 'Publishing your public marketplace listing…';
    });
    try {
      await auth.updateMyProfile(
        bio: _bioForBackend(),
        cityId: matchedCity?.publicId,
        visibility: 'public',
        websiteUrl: website.text.trim(),
      );
      await auth.updateTalentProfile(
        screenName: stageName.text.trim(),
        languages: _languagesForBackend(),
        ageRange: ageRange.text.trim(),
        genderIdentity: genderIdentity.text.trim(),
        heightCm: _heightCmForBackend(),
        unionNote: unionNote.text.trim(),
        experienceYears: int.tryParse(experienceYears.text.trim()),
        skills: _commaValues(skills.text),
        accents: _commaValues(accents.text),
        specialAbilities: _commaValues(specialAbilities.text),
        physicalDetails: _physicalDetailsForBackend(),
        credits: _lineEntries(credits.text),
        training: _lineEntries(training.text),
        representation: _representationForBackend(),
        socialLinks: _socialLinksForBackend(),
      );
      final listing = await auth.publishMarketplaceListing(
        title: '${stageName.text.trim()} — Actor',
        summary: _listingSummary(),
        cityId: matchedCity?.publicId,
      );
      if (!mounted) return;
      setState(() => remoteStatus = 'Published listing ${listing.publicId}');
      actorSnack(context, 'Marketplace listing published');
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() {
        error = exception.message;
        remoteStatus = exception.code == 'marketplace.kyc_required'
            ? 'Approved Actor / Talent KYC is required before public listing.'
            : 'Listing was not published. Check the details and try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        error = 'Could not reach backend';
        remoteStatus = 'Listing was not published. Try again when online.';
      });
    } finally {
      if (mounted) {
        setState(() => publishingListing = false);
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

  List<TalentLanguage> _languagesForBackend() {
    return languages.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .map((item) => TalentLanguage(language: item))
        .toList();
  }

  void _clearFormValues(AuthController auth) {
    stageName.clear();
    realName.text = auth.user?.displayName ?? '';
    city.clear();
    languages.clear();
    skills.clear();
    accents.clear();
    specialAbilities.clear();
    credits.clear();
    training.clear();
    instagram.clear();
    tiktok.clear();
    followers.clear();
    website.clear();
    workHistory.clear();
    ageRange.clear();
    height.clear();
    genderIdentity.clear();
    experienceYears.clear();
    unionNote.clear();
    agency.clear();
    eyeColor.clear();
    hairColor.clear();
  }

  String _bioValue(String? bio, String label) {
    final prefix = '$label:';
    for (final line in (bio ?? '').split('\n')) {
      if (line.toLowerCase().startsWith(prefix.toLowerCase())) {
        return line.substring(prefix.length).trim();
      }
    }
    return '';
  }

  bool _hasStructuredBio(String? bio) {
    return RegExp(
      r'^(Skills|Credits|Work history|Playable age|Height|Instagram|Followers|Membership|Agency):',
      caseSensitive: false,
      multiLine: true,
    ).hasMatch(bio ?? '');
  }

  int? _heightCmForBackend() {
    final value = height.text.trim().toLowerCase();
    final direct = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    if (value.contains('cm')) return direct;
    final match = RegExp(r"(\d+)\s*(?:ft|')\s*(\d+)?").firstMatch(value);
    if (match != null) {
      final feet = int.tryParse(match.group(1) ?? '') ?? 0;
      final inches = int.tryParse(match.group(2) ?? '') ?? 0;
      return ((feet * 12 + inches) * 2.54).round();
    }
    return direct != null && direct >= 100 && direct <= 250 ? direct : null;
  }

  String _bioForBackend() {
    return workHistory.text.trim();
  }

  String _listingSummary() {
    final parts = <String>[
      if (skills.text.trim().isNotEmpty) skills.text.trim(),
      if (credits.text.trim().isNotEmpty) credits.text.trim(),
      if (workHistory.text.trim().isNotEmpty) workHistory.text.trim(),
      if (languages.text.trim().isNotEmpty)
        'Languages: ${languages.text.trim()}',
      if (instagram.text.trim().isNotEmpty) 'Social: ${instagram.text.trim()}',
    ];
    final summary = parts.join('\n');
    if (summary.trim().length >= 10) return summary;
    return 'Available actor/talent profile for CineConnect productions.';
  }

  int _formCompleteness() {
    final fields = [
      stageName,
      city,
      languages,
      skills,
      accents,
      specialAbilities,
      credits,
      training,
      workHistory,
      ageRange,
      height,
      instagram,
      agency,
    ];
    final completed =
        fields.where((field) => field.text.trim().isNotEmpty).length;
    return ((completed / fields.length) * 100).round();
  }

  List<String> _commaValues(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _lineEntries(String value) {
    return value
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .map((item) => <String, dynamic>{'title': item})
        .toList();
  }

  List<String> _entryTitles(List<Map<String, dynamic>> entries) {
    return entries
        .map((item) => item['title']?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Map<String, dynamic> _physicalDetailsForBackend() {
    return {
      if (eyeColor.text.trim().isNotEmpty) 'eye_color': eyeColor.text.trim(),
      if (hairColor.text.trim().isNotEmpty) 'hair_color': hairColor.text.trim(),
    };
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
  final String languages;
  final String instagram;
  final String tiktok;
  final String followers;
  final String workHistory;
  final String ageRange;
  final String height;
  final String agency;
  final int completeness;
  const _ProfileSummary({
    this.avatarUrl,
    required this.stageName,
    required this.city,
    required this.languages,
    required this.instagram,
    required this.tiktok,
    required this.followers,
    required this.workHistory,
    required this.ageRange,
    required this.height,
    required this.agency,
    required this.completeness,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ActorSectionCard(
      title: 'Director-facing Profile',
      icon: Icons.visibility_outlined,
      actionText: 'Open view',
      onActionTap: () => showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ActorSectionCard(
                  title: 'As seen by directors',
                  icon: Icons.visibility_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ActorMediaFrame(
                        imageUrl: avatarUrl ?? '',
                        title: stageName.isEmpty ? 'Stage name' : stageName,
                        badge: 'Draft',
                        fallbackIcon: Icons.person_outline_rounded,
                        aspectRatio: 4 / 5,
                      ),
                      const SizedBox(height: 10),
                      ActorInfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'City',
                        value: city.isEmpty ? 'City' : city,
                      ),
                      ActorInfoRow(
                        icon: Icons.translate_rounded,
                        label: 'Languages',
                        value: languages.isEmpty ? 'Languages' : languages,
                      ),
                      ActorInfoRow(
                        icon: Icons.face_retouching_natural_outlined,
                        label: 'Playable age',
                        value: ageRange.isEmpty ? 'Not set' : ageRange,
                      ),
                      ActorInfoRow(
                        icon: Icons.height_outlined,
                        label: 'Height',
                        value: height.isEmpty ? 'Not set' : height,
                      ),
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
                        label: 'Work history',
                        value: workHistory.isEmpty ? 'Not set' : workHistory,
                      ),
                      ActorInfoRow(
                        icon: Icons.apartment_outlined,
                        label: 'Agency',
                        value: agency.isEmpty ? 'Independent' : agency,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                CoreSecondaryButton(
                  icon: Icons.close_rounded,
                  label: 'Close',
                  compact: true,
                  onTap: () => Navigator.pop(dialogContext),
                ),
              ],
            ),
          ),
        ),
      ),
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
            '$city - $languages',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          ActorProgressMeter(value: completeness),
          ActorInfoRow(
            icon: Icons.face_retouching_natural_outlined,
            label: 'Playable age',
            value: ageRange.isEmpty ? 'Not set' : ageRange,
          ),
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
            label: 'Work history',
            value: workHistory.isEmpty ? 'Not set' : workHistory,
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
