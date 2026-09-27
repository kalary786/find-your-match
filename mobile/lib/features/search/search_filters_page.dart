import 'package:find_your_match/core/widgets/primary_button.dart';
import 'package:find_your_match/features/preview/preview_models.dart';
import 'package:find_your_match/features/preview/preview_store.dart';
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
    final filter = ref.read(previewControllerProvider).filter;
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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                Text(
                  'Filters apply to the sample list only.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Age ${_ages.start.round()}–${_ages.end.round()}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
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
                const SizedBox(height: 8),
                Text('Gender', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
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
                const SizedBox(height: 16),
                Text('Interests', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
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
                const SizedBox(height: 16),
                Text(
                  'Relationship preferences',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
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
              ],
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
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
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Apply',
                    onPressed: () {
                      ref.read(previewControllerProvider.notifier).setFilter(
                        SearchFilter(
                          minAge: _ages.start.round(),
                          maxAge: _ages.end.round(),
                          gender: _gender,
                          interests: _interests,
                          preferences: _preferences,
                        ),
                      );
                      context.pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
