import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../auth/auth_controller.dart';
import '../../auth/auth_models.dart';
import '../../auth/role_mapper.dart';
import '../../network/api_exception.dart';
import '../../theme/app_color_scheme.dart';
import '../../theme/app_text_styles.dart';
import '../../uploads/upload_repository.dart';
import '../core_routes.dart';
import '../widgets/core_widgets.dart';

/// Full-page chooser: selecting a role opens only its ordinary portal.
class ProfileRoleSwitcherScreen extends StatefulWidget {
  const ProfileRoleSwitcherScreen({super.key});

  static void showRoleSwitcherSheet(BuildContext context) =>
      Navigator.pushNamed(context, CoreRoutes.profileRoles);

  @override
  State<ProfileRoleSwitcherScreen> createState() =>
      _ProfileRoleSwitcherScreenState();
}

class _ProfileRoleSwitcherScreenState extends State<ProfileRoleSwitcherScreen> {
  bool _managing = false;
  bool _requested = false;
  String? _busyRole;
  String? _error;
  String? _directorLabel;
  String? _avatarUrl;
  Map<String, String> _covers = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requested) {
      _requested = true;
      _loadCovers();
    }
  }

  Future<void> _loadCovers() async {
    final auth = AuthScope.of(context);
    try {
      final response = await auth.apiClient.get('/me/role-covers');
      final covers = (response['data'] as Map<String, dynamic>)['covers']
              as Map<String, dynamic>? ??
          const {};
      try {
        _avatarUrl = (await auth.myProfile()).avatarFile?.publicUrl;
      } catch (_) {
        // A photo is optional; the role icon remains the fallback.
      }
      if (auth.user?.hasRole('director_producer') ?? false) {
        try {
          final data = await auth.apiClient
              .get('/professional-profiles/director_producer');
          final fields =
              (data['data'] as Map<String, dynamic>)['fields'] as Map?;
          final focus = (fields?['focus'] ?? '').toString().toLowerCase();
          if (focus.contains('director') && !focus.contains('producer')) {
            _directorLabel = 'Director';
          } else if (focus.contains('producer') &&
              !focus.contains('director')) {
            _directorLabel = 'Producer';
          }
        } catch (_) {/* An unfinished role profile still opens normally. */}
      }
      if (!mounted) return;
      setState(() => _covers = {
            for (final entry in covers.entries)
              if (entry.value is Map &&
                  (entry.value as Map)['public_url'] is String)
                entry.key: (entry.value as Map)['public_url'] as String,
          });
    } catch (_) {
      if (mounted) setState(() => _error = 'Cover photos could not load.');
    }
  }

  Future<void> _open(AuthRole role) async {
    final route = RoleMapper.portalRouteForCode(role.code);
    if (route == null || _busyRole != null) return;
    setState(() => _busyRole = role.code);
    try {
      final auth = AuthScope.of(context);
      if (auth.user?.primaryRole?.code != role.code) {
        await auth.setPrimaryRole(role.code);
      }
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not open this profile. Retry.');
      }
    } finally {
      if (mounted) setState(() => _busyRole = null);
    }
  }

  Future<void> _editCover(AuthRole role) async {
    if (_busyRole != null) return;
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    final file = picked?.files.single;
    if (file?.bytes == null) return;
    if (!mounted) return;
    setState(() => _busyRole = role.code);
    try {
      final auth = AuthScope.of(context);
      final uploaded = await auth.uploadFile(
        purpose: 'profile_media',
        file: PickedFileData(
          name: file!.name,
          mimeType: switch (file.extension?.toLowerCase()) {
            'png' => 'image/png',
            'webp' => 'image/webp',
            _ => 'image/jpeg',
          },
          bytes: file.bytes!,
        ),
      );
      final response = await auth.apiClient.patch(
        '/me/role-covers/${role.code}',
        body: {'file_id': uploaded.publicId},
      );
      final cover = (response['data'] as Map<String, dynamic>)['cover'] as Map?;
      if (!mounted) return;
      setState(() {
        if (cover?['public_url'] is String) {
          _covers[role.code] = cover!['public_url'] as String;
        }
        _error = null;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Cover upload failed. Try again.');
    } finally {
      if (mounted) setState(() => _busyRole = null);
    }
  }

  Future<void> _addRole() async {
    final auth = AuthScope.of(context);
    try {
      final all = await auth.roles();
      final options = all
          .where((role) =>
              !auth.user!.hasRole(role.code) &&
              RoleMapper.portalRouteForCode(role.code) != null &&
              !const {
                'super_admin',
                'reviewer',
                'finance_admin',
                'support_agent'
              }.contains(role.code))
          .toList();
      if (!mounted) return;
      final selected = await showModalBottomSheet<AuthRole>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * .75,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              children: [
                Text('Add a role',
                    style: Theme.of(sheetContext).textTheme.titleLarge),
                const SizedBox(height: 8),
                for (final role in options)
                  ListTile(
                    minVerticalPadding: 12,
                    leading: Icon(RoleMapper.iconForCode(role.code)),
                    title: Text(RoleMapper.displayLabelForName(role.name)),
                    trailing: const Icon(Icons.add_rounded),
                    onTap: () => Navigator.pop(sheetContext, role),
                  ),
              ],
            ),
          ),
        ),
      );
      if (selected == null || !mounted) return;
      setState(() => _busyRole = selected.code);
      await auth.addRole(selected.code);
      if (mounted) setState(() => _error = null);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not add the role. Retry.');
    } finally {
      if (mounted) setState(() => _busyRole = null);
    }
  }

  Future<void> _signOut() async {
    await AuthScope.of(context).logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, CoreRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final user = AuthScope.of(context).user;
    final roles = (user?.roles ?? const <AuthRole>[])
        .where((role) =>
            role.status == 'active' &&
            RoleMapper.portalRouteForCode(role.code) != null)
        .toList();
    return CoreScreenScaffold(
      showBackdrop: false,
      showGlobalControls: false,
      scrollable: false,
      padding: EdgeInsets.zero,
      backgroundColor: colors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(children: [
              Row(children: [
                Text('CineConnect',
                    style: AppTextStyles.sectionTitle
                        .copyWith(color: colors.textPrimary, fontSize: 23)),
                const Spacer(),
                TextButton.icon(
                    onPressed: _signOut,
                    style: TextButton.styleFrom(
                        foregroundColor: colors.textPrimary),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign out')),
              ]),
              const SizedBox(height: 52),
              Text('Who is working today?',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.sectionTitle
                      .copyWith(color: colors.textPrimary, fontSize: 34)),
              const SizedBox(height: 8),
              Text('${user?.displayName ?? 'Your'} profiles',
                  style: AppTextStyles.bodyMuted
                      .copyWith(color: colors.textSecondary)),
              const SizedBox(height: 32),
              if (_error != null) ...[
                InlineNotice(message: _error!),
                const SizedBox(height: 16),
              ],
              LayoutBuilder(builder: (context, box) {
                final columns = box.maxWidth >= 900
                    ? 4
                    : box.maxWidth >= 600
                        ? 3
                        : 2;
                final cardWidth = (box.maxWidth - (columns - 1) * 18) / columns;
                final cardHeight = cardWidth / (box.maxWidth < 600 ? .83 : .86);
                return Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 18,
                  runSpacing: 24,
                  children: [
                    for (final role in roles)
                      SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                        child: _WorkspaceCard(
                          role: role,
                          label: role.code == 'director_producer'
                              ? (_directorLabel ?? 'Director / Producer')
                              : RoleMapper.displayLabelForName(role.name),
                          coverUrl: _covers[role.code] ?? _avatarUrl,
                          busy: _busyRole == role.code,
                          managing: _managing,
                          onTap: _managing
                              ? () => _editCover(role)
                              : () => _open(role),
                        ),
                      ),
                    if (_managing)
                      SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: _AddRoleCard(onTap: _addRole)),
                  ],
                );
              }),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: () => setState(() => _managing = !_managing),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.textPrimary,
                  minimumSize: const Size(164, 48),
                  side: BorderSide(color: colors.goldDark),
                ),
                icon:
                    Icon(_managing ? Icons.check_rounded : Icons.edit_outlined),
                label: Text(_managing ? 'Done' : 'Manage roles'),
              ),
              if (_managing) ...[
                const SizedBox(height: 10),
                Text('Tap a profile to change its cover photo.',
                    style: TextStyle(color: colors.textSecondary)),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

class _WorkspaceCard extends StatelessWidget {
  const _WorkspaceCard(
      {required this.role,
      required this.label,
      required this.coverUrl,
      required this.busy,
      required this.managing,
      required this.onTap});
  final AuthRole role;
  final String label;
  final String? coverUrl;
  final bool busy;
  final bool managing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      label: managing ? 'Edit $label cover photo' : 'Open $label profile',
      child: Material(
        color: colors.elevatedSurface,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: busy ? null : onTap,
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: colors.border)),
            child: Column(children: [
              Expanded(
                  child: Stack(fit: StackFit.expand, children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(21)),
                  child: coverUrl == null
                      ? DecoratedBox(
                          decoration:
                              BoxDecoration(gradient: colors.goldGradient),
                          child: Icon(RoleMapper.iconForCode(role.code),
                              size: 72, color: colors.onGold))
                      : Image.network(coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                              RoleMapper.iconForCode(role.code),
                              size: 64)),
                ),
                if (managing)
                  Positioned(
                      right: 10,
                      top: 10,
                      child: CircleAvatar(
                          backgroundColor: colors.elevatedSurface,
                          child: Icon(Icons.photo_camera_outlined,
                              color: colors.textPrimary))),
                if (busy) const Center(child: CircularProgressIndicator()),
              ])),
              Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                  child: Text(label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800))),
            ]),
          ),
        ),
      ),
    );
  }
}

class _AddRoleCard extends StatelessWidget {
  const _AddRoleCard({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
          side: BorderSide(color: colors.border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.add_circle_outline_rounded,
            size: 54, color: colors.goldDark),
        const SizedBox(height: 12),
        Text('Add a role', style: TextStyle(color: colors.textPrimary)),
      ]),
    );
  }
}
