import 'package:flutter/material.dart';

import '../../auth/auth_controller.dart';
import '../../auth/auth_models.dart';
import '../../auth/role_mapper.dart';
import '../../theme/app_color_scheme.dart';
import '../../theme/app_text_styles.dart';
import '../core_routes.dart';
import '../mock_data/shared_mock_data.dart';
import '../models/shared_models.dart';
import '../widgets/core_widgets.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  CineRole? _selectedPrimaryRole;
  late Future<List<CineRole>> _rolesFuture;

  @override
  void initState() {
    super.initState();
    _rolesFuture = _loadRoles();
  }

  Future<List<CineRole>> _loadRoles() async {
    try {
      final roles = await AuthScope.of(context).roles();
      return roles.map(_roleFromApi).toList();
    } catch (_) {
      return SharedMockData.roles;
    }
  }

  CineRole _roleFromApi(AuthRole role) {
    final fallback = SharedMockData.roles.where(
      (item) => item.name == role.name,
    );
    return CineRole(
      icon: RoleMapper.iconForCode(role.code),
      name: role.name,
      description: fallback.isEmpty
          ? 'Create a verified CineConnect profile for this role.'
          : fallback.first.description,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CoreScreenScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CoreAppHeader(
            title: 'Choose Your Primary Role',
            subtitle:
                'You can add more roles later from your profile switcher.',
            icon: Icons.diversity_3_outlined,
            showBack: false,
          ),
          const SizedBox(height: 24),
          FutureBuilder<List<CineRole>>(
            future: _rolesFuture,
            builder: (context, snapshot) {
              final roles = snapshot.data ?? SharedMockData.roles;
              return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final columns = width >= 900
                      ? 3
                      : width >= 620
                          ? 2
                          : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: roles.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: columns == 1 ? 3.45 : 2.18,
                    ),
                    itemBuilder: (context, index) {
                      final role = roles[index];
                      return RoleCard(
                        role: role,
                        selected: _selectedPrimaryRole?.name == role.name,
                        onTap: () =>
                            setState(() => _selectedPrimaryRole = role),
                      );
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),
          CorePrimaryButton(
            icon: Icons.arrow_forward_rounded,
            label: 'Continue',
            onTap: _selectedPrimaryRole == null
                ? null
                : () => Navigator.pushNamed(
                      context,
                      CoreRoutes.signup,
                      arguments: _selectedPrimaryRole!.name,
                    ),
          ),
          const SizedBox(height: 12),
          CoreSecondaryButton(
            icon: Icons.login_rounded,
            label: 'Already have an account',
            onTap: () => Navigator.pushNamed(context, CoreRoutes.login),
          ),
        ],
      ),
    );
  }
}

class RoleCard extends StatelessWidget {
  final CineRole role;
  final bool selected;
  final VoidCallback onTap;

  const RoleCard({
    super.key,
    required this.role,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: CoreGlassCard(
        selected: selected,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: selected
                    ? colors.goldGradient
                    : colors.inactiveChipGradient,
                border: Border.all(
                  color: selected ? colors.goldLight : colors.border,
                ),
              ),
              child: Icon(
                role.icon,
                color: selected ? colors.onGold : colors.goldDark,
                size: 23,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    role.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(
                      color: colors.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    role.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: colors.textSecondary,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? colors.goldMid : colors.iconMuted,
            ),
          ],
        ),
      ),
    );
  }
}
