import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/session/session_controller.dart';
import 'package:find_your_match/core/theme/app_colors.dart';
import 'package:find_your_match/core/theme/app_tokens.dart';
import 'package:find_your_match/core/theme/theme_mode_controller.dart';
import 'package:find_your_match/core/widgets/settings_group.dart';
import 'package:find_your_match/features/ads/ads_service.dart';
import 'package:find_your_match/features/profile/account_failure.dart';
import 'package:find_your_match/features/social/social_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final social = ref.watch(socialControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space20,
          AppTokens.space8,
          AppTokens.space20,
          AppTokens.space24,
        ),
        children: [
          SettingsGroup(
            title: 'Appearance',
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.space16,
                  AppTokens.space12,
                  AppTokens.space16,
                  AppTokens.space16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ThemeModeTile(
                        label: 'System',
                        icon: Icons.brightness_auto_rounded,
                        selected: themeMode == ThemeMode.system,
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .update(ThemeMode.system),
                      ),
                    ),
                    const SizedBox(width: AppTokens.space8),
                    Expanded(
                      child: _ThemeModeTile(
                        label: 'Light',
                        icon: Icons.light_mode_outlined,
                        selected: themeMode == ThemeMode.light,
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .update(ThemeMode.light),
                      ),
                    ),
                    const SizedBox(width: AppTokens.space8),
                    Expanded(
                      child: _ThemeModeTile(
                        label: 'Dark',
                        icon: Icons.dark_mode_outlined,
                        selected: themeMode == ThemeMode.dark,
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .update(ThemeMode.dark),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space24),
          SettingsGroup(
            title: 'Privacy',
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space16,
                ),
                title: const Text('Show online status'),
                subtitle: const Text(
                  'Off until you turn it on. Saved on your account.',
                ),
                value: social.showOnline,
                onChanged: (value) => _privacy(context, ref, online: value),
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space16,
                ),
                title: const Text('Show last active'),
                subtitle: const Text(
                  'Off until you turn it on. Saved on your account.',
                ),
                value: social.showLastActive,
                onChanged: (value) => _privacy(context, ref, active: value),
              ),
              const _PrivacyOptionsTile(),
            ],
          ),
          const SizedBox(height: AppTokens.space24),
          SettingsGroup(
            title: 'Safety',
            children: [
              SettingsTile(
                key: const Key('blocked-users-tile'),
                leadingIcon: Icons.block,
                title: 'Blocked users',
                onTap: () => context.push(AppRoutes.blocked),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space24),
          SettingsGroup(
            title: 'Account',
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.space16,
                  AppTokens.space12,
                  AppTokens.space16,
                  AppTokens.space4,
                ),
                child: Text(
                  'This account uses the email and password stored on your website. An admin can block the account or delete chats from the admin panel.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              SettingsTile(
                key: const Key('change-password-tile'),
                leadingIcon: Icons.password_outlined,
                title: 'Change password',
                trailing: const SizedBox.shrink(),
                onTap: () => _changePassword(context, ref),
              ),
              SettingsTile(
                key: const Key('sign-out-tile'),
                leadingIcon: Icons.logout,
                title: 'Sign out',
                trailing: const SizedBox.shrink(),
                onTap: () => _signOut(context, ref),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space24),
          SettingsGroup(
            title: 'Legal',
            children: [
              SettingsTile(
                leadingIcon: Icons.description_outlined,
                title: 'Terms',
                onTap: () => context.push(AppRoutes.terms),
              ),
              SettingsTile(
                leadingIcon: Icons.privacy_tip_outlined,
                title: 'Privacy',
                onTap: () => context.push(AppRoutes.privacy),
              ),
              SettingsTile(
                leadingIcon: Icons.groups_outlined,
                title: 'Community guidelines',
                onTap: () => context.push(AppRoutes.guidelines),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space24),
          SettingsGroup(
            title: 'Danger zone',
            children: [
              ListTile(
                key: const Key('delete-account-tile'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space16,
                  vertical: AppTokens.space4,
                ),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.14),
                    borderRadius: AppTokens.sm,
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Delete account',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.error,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.error.withValues(alpha: 0.7),
                ),
                onTap: () => context.push(AppRoutes.deleteAccount),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _ChangePasswordDialog(
        onSubmit: (currentPassword, password) {
          return ref
              .read(matchApiProvider)
              .changePassword(
                currentPassword: currentPassword,
                password: password,
              );
        },
      ),
    );
    if (saved != true || !context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Password updated.')));
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sign out'),
          content: const Text(
            'Sign out of this phone? Your profile stays on the website.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(sessionControllerProvider.notifier).signOut();
  }

  Future<void> _privacy(
    BuildContext context,
    WidgetRef ref, {
    bool? online,
    bool? active,
  }) async {
    try {
      final social = ref.read(socialControllerProvider.notifier);
      if (online != null) {
        await social.setShowOnline(online);
      } else if (active != null) {
        await social.setShowLastActive(active);
      }
    } on AccountFailure catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? AppColors.coral.withValues(alpha: 0.12)
          : theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: AppTokens.md,
        side: BorderSide(
          color: selected
              ? AppColors.coral
              : theme.colorScheme.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppTokens.space16,
            horizontal: AppTokens.space8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? AppColors.coral : theme.colorScheme.onSurface,
              ),
              const SizedBox(height: AppTokens.space8),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected
                      ? AppColors.coral
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({required this.onSubmit});

  final Future<void> Function(String currentPassword, String password) onSubmit;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  var _saving = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _ready =>
      _current.text.isNotEmpty &&
      _next.text.length >= 8 &&
      _next.text == _confirm.text;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_current.text, _next.text);
      if (mounted) Navigator.pop(context, true);
    } on AccountFailure catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('current-password'),
            controller: _current,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Current password'),
            onChanged: (_) => setState(() {}),
          ),
          TextField(
            key: const Key('new-password'),
            controller: _next,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New password'),
            onChanged: (_) => setState(() {}),
          ),
          TextField(
            key: const Key('confirm-password'),
            controller: _confirm,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirm new password',
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          key: const Key('save-password'),
          onPressed: !_ready || _saving ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _PrivacyOptionsTile extends ConsumerStatefulWidget {
  const _PrivacyOptionsTile();

  @override
  ConsumerState<_PrivacyOptionsTile> createState() =>
      _PrivacyOptionsTileState();
}

class _PrivacyOptionsTileState extends ConsumerState<_PrivacyOptionsTile> {
  var _required = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final needed =
          await ref.read(adsServiceProvider).privacyOptionsRequired();
      if (mounted) setState(() => _required = needed);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_required) return const SizedBox.shrink();
    return SettingsTile(
      leadingIcon: Icons.privacy_tip_outlined,
      title: 'Privacy options',
      subtitle: 'Manage ad consent choices',
      onTap: () => ref.read(adsServiceProvider).showPrivacyOptions(),
    );
  }
}
