import 'package:find_your_match/core/widgets/primary_button.dart';
import 'package:find_your_match/features/preview/preview_models.dart';
import 'package:find_your_match/features/preview/preview_store.dart';
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
    final person = ref.watch(previewControllerProvider).personById(widget.userId);
    return Scaffold(
      appBar: AppBar(title: const Text('Report')),
      body: person == null
          ? const Center(child: Text('That sample profile is not available.'))
          : _sent
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Report saved on this device',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nothing was sent to a moderator. A later build will store reports for review.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Done',
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Text(
                  'Report ${person.displayName}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a reason. This preview keeps the report on this phone only.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                RadioGroup<String>(
                  groupValue: _reason,
                  onChanged: (value) => setState(() => _reason = value),
                  child: Column(
                    children: [
                      for (final reason in ProfileOptions.reportReasons)
                        RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          value: reason,
                          title: Text(reason),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _note,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 300,
                  decoration: const InputDecoration(
                    labelText: 'Details (optional)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Submit report',
                  onPressed: _reason == null
                      ? null
                      : () {
                          ref
                              .read(previewControllerProvider.notifier)
                              .report(person.id);
                          setState(() => _sent = true);
                        },
                ),
              ],
            ),
    );
  }
}
