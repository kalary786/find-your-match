import 'package:find_your_match/core/theme/app_tokens.dart';
import 'package:find_your_match/core/widgets/primary_button.dart';
import 'package:find_your_match/features/preview/preview_models.dart';
import 'package:find_your_match/features/profile/account_failure.dart';
import 'package:find_your_match/features/social/social_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ReportUserPage extends ConsumerStatefulWidget {
  const ReportUserPage({required this.userId, super.key});

  final String userId;

  @override
  ConsumerState<ReportUserPage> createState() => _ReportUserPageState();
}

class _ReportUserPageState extends ConsumerState<ReportUserPage> {
  String? _reason;
  final _note = TextEditingController();
  var _sent = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final person = ref.watch(socialControllerProvider).personById(widget.userId);
    return Scaffold(
      appBar: AppBar(title: const Text('Report')),
      body: person == null
          ? const Center(child: Text('That profile is not available.'))
          : _sent
          ? Padding(
              padding: const EdgeInsets.all(AppTokens.space24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: AppTokens.space16),
                  Text(
                    'Report sent',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space8),
                  Text(
                    'An admin can review this report and block or delete the account.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: AppTokens.space24),
                  PrimaryButton(
                    label: 'Done',
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.space20,
                AppTokens.space8,
                AppTokens.space20,
                AppTokens.space24,
              ),
              children: [
                Text(
                  'Report ${person.displayName}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTokens.space8),
                Text(
                  'Choose a reason. The report is stored on your website for an admin to review.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppTokens.space16),
                RadioGroup<String>(
                  groupValue: _reason,
                  onChanged: (value) => setState(() => _reason = value),
                  child: Column(
                    children: [
                      for (final reason in ProfileOptions.reportReasons)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppTokens.space8,
                          ),
                          child: Material(
                            color: _reason == reason
                                ? theme.colorScheme.primaryContainer
                                    .withValues(alpha: 0.55)
                                : theme.colorScheme.surfaceContainerLowest,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppTokens.lg,
                              side: BorderSide(
                                color: _reason == reason
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outlineVariant,
                                width: _reason == reason ? 1.5 : 1,
                              ),
                            ),
                            child: RadioListTile<String>(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppTokens.space8,
                              ),
                              value: reason,
                              title: Text(
                                reason,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: _reason == reason
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.space8),
                Material(
                  color: theme.colorScheme.surfaceContainerLowest,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppTokens.lg,
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTokens.space4),
                    child: TextField(
                      controller: _note,
                      minLines: 3,
                      maxLines: 5,
                      maxLength: 300,
                      decoration: const InputDecoration(
                        labelText: 'Details (optional)',
                        alignLabelWithHint: true,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.space16),
                PrimaryButton(
                  label: 'Submit report',
                  onPressed: _reason == null
                      ? null
                      : () async {
                          final reason = _reason;
                          if (reason == null) return;
                          try {
                            await ref
                                .read(socialControllerProvider.notifier)
                                .report(
                                  userId: person.id,
                                  reason: reason,
                                  details: _note.text.trim(),
                                );
                            if (mounted) setState(() => _sent = true);
                          } on AccountFailure catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.message)),
                            );
                          }
                        },
                ),
              ],
            ),
    );
  }
}
