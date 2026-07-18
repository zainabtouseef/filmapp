import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/profile/profile_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/actor_talent_demo_data.dart';
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
  late final TextEditingController credits;
  late final TextEditingController agency;
  String? error;
  String? remoteStatus;
  bool loadingRemote = false;
  bool savingRemote = false;
  bool publishingListing = false;
  bool attemptedRemoteLoad = false;
  List<ProfileCity> supportedCities = const [];

  @override
  void initState() {
    super.initState();
    final store = ActorTalentDemoStore.instance;
    stageName = TextEditingController(text: store.profileStageName);
    realName = TextEditingController(text: store.profileRealName);
    city = TextEditingController(text: store.profileCity);
    languages = TextEditingController(text: store.profileLanguages);
    skills = TextEditingController(text: store.profileSkills);
    credits = TextEditingController(text: store.profileCredits);
    agency = TextEditingController(text: store.agency);
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
    credits.dispose();
    agency.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ActorTalentDemoStore.instance,
      builder: (context, _) {
        return ActorTwoColumn(
          left: ActorSectionCard(
            title: 'Profile Form',
            icon: Icons.badge_outlined,
            child: Column(
              children: [
                const StepWizardIndicator(currentStep: 2, totalSteps: 4),
                if (loadingRemote) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(minHeight: 2),
                ],
                const SizedBox(height: 14),
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
                  label: 'Real name',
                  icon: Icons.person_outline_rounded,
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
                  controller: languages,
                  label: 'Languages',
                  icon: Icons.translate_rounded,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                CoreTextField(
                  controller: skills,
                  label: 'Skills tags',
                  icon: Icons.local_offer_outlined,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                CoreTextField(
                  controller: credits,
                  label: 'Training / credits',
                  icon: Icons.workspace_premium_outlined,
                  maxLines: 3,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                CoreTextField(
                  controller: agency,
                  label: 'Agency affiliation',
                  icon: Icons.apartment_outlined,
                  onChanged: (_) => setState(() {}),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CoreSecondaryButton(
                        icon: Icons.save_outlined,
                        label: 'Save draft',
                        compact: true,
                        onTap: savingRemote ? null : _saveDraft,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CorePrimaryButton(
                        icon: Icons.verified_outlined,
                        label: 'Submit review',
                        compact: true,
                        loading: savingRemote,
                        onTap: savingRemote ? null : _submit,
                      ),
                    ),
                  ],
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
          ),
          right: _ProfilePreview(
            stageName: stageName.text,
            city: city.text,
            languages: languages.text,
            agency: agency.text,
          ),
        );
      },
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
      final loadedLanguages = talent.languages
          .map((item) => item.language)
          .where((item) => item.trim().isNotEmpty)
          .join(', ');
      setState(() {
        supportedCities = cities;
        if ((talent.screenName ?? '').trim().isNotEmpty) {
          stageName.text = talent.screenName!.trim();
        }
        if ((profile.city?.name ?? '').trim().isNotEmpty) {
          city.text = profile.city!.name;
        }
        if (loadedLanguages.isNotEmpty) {
          languages.text = loadedLanguages;
        }
        if ((profile.bio ?? '').trim().isNotEmpty &&
            skills.text.trim().isEmpty) {
          skills.text = profile.bio!.trim();
        }
        remoteStatus = 'Synced with backend profile';
      });
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() {
        remoteStatus = 'Using local draft: ${exception.message}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        remoteStatus = 'Using local draft until backend is reachable';
      });
    } finally {
      if (mounted) {
        setState(() => loadingRemote = false);
      }
    }
  }

  void _saveDraft() {
    ActorTalentDemoStore.instance.saveProfileDraft(
      stageName: stageName.text.trim(),
      realName: realName.text.trim(),
      city: city.text.trim(),
      languages: languages.text.trim(),
      skills: skills.text.trim(),
      credits: credits.text.trim(),
      agencyName: agency.text.trim(),
    );
    actorSnack(context, 'Profile draft saved');
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
    ActorTalentDemoStore.instance.updateProfile(
      stageName: stageName.text.trim(),
      realName: realName.text.trim(),
      city: city.text.trim(),
      languages: languages.text.trim(),
      skills: skills.text.trim(),
      credits: credits.text.trim(),
      agencyName:
          agency.text.trim().isEmpty ? 'Independent' : agency.text.trim(),
    );
    final auth = AuthScope.maybeOf(context);
    if (auth == null || !auth.isAuthenticated) {
      setState(() => error = null);
      actorSnack(context, 'Profile sent to moderation');
      Navigator.pushNamed(context, ActorTalentRoutes.portfolio);
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
      );
      await auth.updateTalentProfile(
        screenName: stageName.text.trim(),
        languages: _languagesForBackend(),
      );
      if (!mounted) return;
      setState(() => remoteStatus = 'Backend profile saved');
      actorSnack(context, 'Profile saved and sent to moderation');
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
        remoteStatus = 'Your local draft is saved. Try again when online.';
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
      );
      await auth.updateTalentProfile(
        screenName: stageName.text.trim(),
        languages: _languagesForBackend(),
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

  String _bioForBackend() {
    final parts = <String>[
      if (skills.text.trim().isNotEmpty) 'Skills: ${skills.text.trim()}',
      if (credits.text.trim().isNotEmpty) 'Credits: ${credits.text.trim()}',
      if (agency.text.trim().isNotEmpty) 'Agency: ${agency.text.trim()}',
    ];
    return parts.join('\n');
  }

  String _listingSummary() {
    final parts = <String>[
      if (skills.text.trim().isNotEmpty) skills.text.trim(),
      if (credits.text.trim().isNotEmpty) credits.text.trim(),
      if (languages.text.trim().isNotEmpty)
        'Languages: ${languages.text.trim()}',
    ];
    final summary = parts.join('\n');
    if (summary.trim().length >= 10) return summary;
    return 'Available actor/talent profile for CineConnect productions.';
  }
}

class _ProfilePreview extends StatelessWidget {
  final String stageName;
  final String city;
  final String languages;
  final String agency;

  const _ProfilePreview({
    required this.stageName,
    required this.city,
    required this.languages,
    required this.agency,
  });

  @override
  Widget build(BuildContext context) {
    final store = ActorTalentDemoStore.instance;
    final colors = context.appColors;
    final verificationLabel =
        store.profileSubmittedForReview ? 'Re-review queued' : 'Verified';
    return ActorSectionCard(
      title: 'Director Preview',
      icon: Icons.visibility_outlined,
      actionText: 'DP view',
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
                        imageUrl: ActorTalentDemoData.profileImage,
                        title: stageName.isEmpty ? 'Stage name' : stageName,
                        badge: verificationLabel,
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
            imageUrl: ActorTalentDemoData.profileImage,
            title: 'Public headshot',
            badge: verificationLabel,
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
          ActorProgressMeter(value: store.profileCompleteness),
          const SizedBox(height: 10),
          ActorInfoRow(
            icon: Icons.verified_user_outlined,
            label: 'Verification',
            value: verificationLabel,
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
