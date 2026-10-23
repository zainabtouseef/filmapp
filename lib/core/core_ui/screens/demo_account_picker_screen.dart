import 'package:flutter/material.dart';

import '../../auth/auth_controller.dart';
import '../../auth/demo_account_models.dart';
import '../../auth/role_mapper.dart';
import '../../network/api_exception.dart';
import '../../network/fresh_workspace.dart';
import '../../theme/app_color_scheme.dart';

/// Unlisted demo entry point. The capability comes from the shared URL only.
class DemoAccountPickerScreen extends StatefulWidget {
  final String accessKey;

  const DemoAccountPickerScreen({super.key, required this.accessKey});

  @override
  State<DemoAccountPickerScreen> createState() =>
      _DemoAccountPickerScreenState();
}

class _DemoAccountPickerScreenState extends State<DemoAccountPickerScreen> {
  final _search = TextEditingController();
  Future<DemoAccountDirectory>? _directory;
  String _category = 'all';
  String? _signingIn;
  String? _loginError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.accessKey.isNotEmpty) {
      _directory ??= AuthScope.of(context).demoAccounts(widget.accessKey);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _login(DemoAccount account, String roleCode) async {
    if (_signingIn != null) return;
    setState(() {
      _signingIn = '${account.publicId}:$roleCode';
      _loginError = null;
    });
    try {
      final auth = AuthScope.of(context);
      final persisted = await auth.demoLogin(
        accessKey: widget.accessKey,
        userId: account.publicId,
        roleCode: roleCode,
      );
      if (!mounted) return;
      if (persisted && openFreshWorkspace(auth.initialAuthenticatedRoute)) {
        return;
      }
      Navigator.of(context).pushNamedAndRemoveUntil(
        auth.initialAuthenticatedRoute,
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _signingIn = null;
        _loginError = error is ApiException
            ? error.message
            : 'We could not open this account. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.movie_filter_outlined,
                            color: colors.goldMid),
                        const SizedBox(width: 10),
                        Text('CineConnect',
                            style: Theme.of(context).textTheme.titleLarge),
                      ]),
                      Chip(
                        avatar: Icon(Icons.explore_outlined,
                            size: 18, color: colors.goldMid),
                        label: const Text('Demo access'),
                        backgroundColor: colors.goldTint,
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  Text('Choose an account',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 10),
                  Text(
                    'Explore CineConnect as a director, actor, or another role. '
                    'Choose an account to open its workspace.',
                    style: TextStyle(color: colors.textSecondary, height: 1.6),
                  ),
                  const SizedBox(height: 28),
                  if (widget.accessKey.isEmpty)
                    _message(
                      'Open your demo access link to choose an account.',
                      icon: Icons.link,
                    )
                  else
                    FutureBuilder<DemoAccountDirectory>(
                      future: _directory,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Padding(
                            padding: EdgeInsets.all(48),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (snapshot.hasError) {
                          final error = snapshot.error;
                          return _message(
                            error is ApiException
                                ? error.message
                                : 'Accounts could not be loaded. Please try again.',
                            icon: Icons.info_outline,
                            retry: true,
                          );
                        }
                        return _accounts(snapshot.requireData);
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _message(String text, {required IconData icon, bool retry = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: context.appColors.goldMid),
        const SizedBox(height: 12),
        Text(text),
        if (retry) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => setState(() {
              _directory = AuthScope.of(context).demoAccounts(widget.accessKey);
            }),
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ]),
    );
  }

  Widget _accounts(DemoAccountDirectory directory) {
    final query = _search.text.trim().toLowerCase();
    final categories = directory.categories
        .where((category) => _category == 'all' || category.code == _category)
        .map((category) => DemoAccountCategory(
              code: category.code,
              name: category.name,
              accounts: category.accounts
                  .where((account) => '${account.displayName} ${account.email}'
                      .toLowerCase()
                      .contains(query))
                  .toList(),
            ))
        .where((category) => category.accounts.isNotEmpty)
        .toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${directory.totalAccounts} accounts · '
          '${directory.categories.length} categories'),
      const SizedBox(height: 18),
      TextField(
        controller: _search,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: 'Search accounts',
          hintText: 'Name or email address',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _search.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: () => setState(_search.clear),
                  icon: const Icon(Icons.close),
                ),
          border: const OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 18),
      Wrap(spacing: 8, runSpacing: 8, children: [
        ChoiceChip(
          label: const Text('All roles'),
          selected: _category == 'all',
          onSelected: (_) => setState(() => _category = 'all'),
        ),
        for (final category in directory.categories)
          ChoiceChip(
            label: Text(
                '${RoleMapper.displayLabelForName(category.name)} (${category.accounts.length})'),
            selected: _category == category.code,
            onSelected: (_) => setState(() => _category = category.code),
          ),
      ]),
      if (_loginError != null) ...[
        const SizedBox(height: 20),
        Semantics(
          liveRegion: true,
          child: Text(_loginError!,
              style: TextStyle(color: context.appColors.danger)),
        ),
      ],
      const SizedBox(height: 28),
      if (categories.isEmpty)
        _message('No accounts match your search.', icon: Icons.search_off),
      for (final category in categories) ...[
        Text('${RoleMapper.displayLabelForName(category.name)} · ${category.accounts.length}',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1000
              ? 3
              : constraints.maxWidth >= 620
                  ? 2
                  : 1;
          final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
          return Wrap(spacing: 16, runSpacing: 16, children: [
            for (final account in category.accounts)
              SizedBox(
                width: width,
                child: _accountCard(account, category),
              ),
          ]);
        }),
        const SizedBox(height: 32),
      ],
    ]);
  }

  Widget _accountCard(DemoAccount account, DemoAccountCategory category) {
    final colors = context.appColors;
    final opening = _signingIn == '${account.publicId}:${category.code}';
    return Container(
      key: ValueKey('account:${category.code}:${account.publicId}'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: opening ? colors.goldMid : colors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            backgroundColor: colors.goldTint,
            foregroundColor: colors.goldMid,
            child: Text(account.displayName.trim().isEmpty
                ? '?'
                : account.displayName.trim().characters.first.toUpperCase()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(account.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium),
          ),
        ]),
        const SizedBox(height: 14),
        Text(account.email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.textSecondary)),
        const SizedBox(height: 6),
        Text(
            account.canLogin
                ? category.name
                : 'Unavailable · ${account.status}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.textTertiary, fontSize: 12)),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: account.canLogin && _signingIn == null
                ? () => _login(account, category.code)
                : null,
            icon: opening
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward, size: 18),
            label: Text(opening ? 'Opening…' : 'Open workspace'),
          ),
        ),
      ]),
    );
  }
}
