import 'package:find_your_match/core/theme/app_tokens.dart';
import 'package:find_your_match/core/widgets/gradient_button.dart';
import 'package:find_your_match/features/preview/preview_models.dart';
import 'package:find_your_match/features/social/social_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SearchFiltersPage extends ConsumerStatefulWidget {
  const SearchFiltersPage({super.key});

  @override
  ConsumerState<SearchFiltersPage> createState() => _SearchFiltersPageState();
}

class _SearchFiltersPageState extends ConsumerState<SearchFiltersPage> {
  late RangeValues _ages;
  String? _gender;
  late Set<String> _interests;
  late Set<String> _preferences;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(socialControllerProvider).filter;
    _ages = RangeValues(filter.minAge.toDouble(), filter.maxAge.toDouble());
    _gender = filter.gender;
    _interests = {...filter.interests};
    _preferences = {...filter.preferences};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Search filters')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.space20,
                AppTokens.space8,
                AppTokens.space20,
                AppTokens.space20,
              ),
              children: [
                Text(
                  'Filters apply to the sample list only.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppTokens.space16),
                _FilterSection(
                  title: 'Age range',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_ages.start.round()}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${_ages.end.round()}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      RangeSlider(
                        min: 18,
                        max: 70,
                        divisions: 52,
                        values: _ages,
                        labels: RangeLabels(
                          '${_ages.start.round()}',
                          '${_ages.end.round()}',
                        ),
                        onChanged: (values) => setState(() => _ages = values),
                      ),
                      Center(
                        child: Text(
                          '${_ages.start.round()} – ${_ages.end.round()} years',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.space16),
                _FilterSection(
                  title: 'Gender',
                  child: Wrap(
                    spacing: AppTokens.space8,
                    runSpacing: AppTokens.space8,
                    children: [
                      ChoiceChip(
                        label: const Text('Any'),
                        selected: _gender == null,
                        onSelected: (_) => setState(() => _gender = null),
                      ),
                      for (final gender in ProfileOptions.genders)
                        ChoiceChip(
                          label: Text(gender),
                          selected: _gender == gender,
                          onSelected: (_) => setState(() => _gender = gender),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.space16),
                _FilterSection(
                  title: 'Interests',
                  child: Wrap(
                    spacing: AppTokens.space8,
                    runSpacing: AppTokens.space8,
                    children: [
                      for (final interest in ProfileOptions.interests)
                        FilterChip(
                          label: Text(interest),
                          selected: _interests.contains(interest),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _interests.add(interest);
                              } else {
                                _interests.remove(interest);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.space16),
                _FilterSection(
                  title: 'Relationship preferences',
                  child: Wrap(
                    spacing: AppTokens.space8,
                    runSpacing: AppTokens.space8,
                    children: [
                      for (final preference in ProfileOptions.preferences)
                        FilterChip(
                          label: Text(preference),
                          selected: _preferences.contains(preference),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _preferences.add(preference);
                              } else {
                                _preferences.remove(preference);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(
                AppTokens.space20,
                AppTokens.space12,
                AppTokens.space20,
                AppTokens.space16,
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _ages = const RangeValues(18, 45);
                        _gender = null;
                        _interests = {};
                        _preferences = {};
                      });
                    },
                    child: const Text('Reset'),
                  ),
                  const SizedBox(width: AppTokens.space12),
                  Expanded(
                    child: GradientButton(
                      label: 'Apply',
                      onPressed: () async {
                        await ref
                            .read(socialControllerProvider.notifier)
                            .setFilter(
                              SearchFilter(
                                minAge: _ages.start.round(),
                                maxAge: _ages.end.round(),
                                gender: _gender,
                                interests: _interests,
                                preferences: _preferences,
                              ),
                            );
                        if (context.mounted) context.pop();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppTokens.space4,
            bottom: AppTokens.space8,
          ),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Material(
          color: theme.colorScheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: AppTokens.lg,
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.space16),
            child: child,
          ),
        ),
      ],
    );
  }
}
