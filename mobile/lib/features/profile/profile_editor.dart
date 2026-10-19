import 'dart:typed_data';

import 'package:find_your_match/core/theme/app_tokens.dart';
import 'package:find_your_match/core/widgets/primary_button.dart';
import 'package:find_your_match/features/preview/preview_models.dart';
import 'package:find_your_match/features/preview/profile_rules.dart';
import 'package:find_your_match/features/profile/account_failure.dart';
import 'package:find_your_match/features/profile/profile_draft.dart';
import 'package:flutter/material.dart';

class ProfileEditor extends StatefulWidget {
  const ProfileEditor({
    required this.title,
    required this.submitLabel,
    required this.takenUsernames,
    required this.onSubmit,
    this.initial,
    this.stepLabel,
    this.onBack,
    this.choosePhoto,
    this.photoFileRequired = false,
    this.keepExistingPhoto = false,
    super.key,
  });

  final String title;
  final String submitLabel;
  final Set<String> takenUsernames;
  final Person? initial;
  final String? stepLabel;
  final VoidCallback? onBack;
  final Future<ProfilePhoto?> Function()? choosePhoto;
  final bool photoFileRequired;
  final bool keepExistingPhoto;
  final Future<void> Function(ProfileDraft draft) onSubmit;

  @override
  State<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  late final TextEditingController _username;
  late final TextEditingController _country;
  late final TextEditingController _bio;
  int? _day;
  int? _month;
  int? _year;
  String? _gender;
  bool _hasPhoto = false;
  ProfilePhoto? _photo;
  final _interests = <String>{};
  final _preferences = <String>{};
  ProfileFieldErrors _fieldErrors = const ProfileFieldErrors();
  String? _error;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _username = TextEditingController(text: initial?.username ?? '');
    _country = TextEditingController(text: initial?.city ?? '');
    _bio = TextEditingController(text: initial?.bio ?? '');
    _gender = initial?.gender;
    _hasPhoto = initial?.hasPhoto ?? false;
    _interests.addAll(initial?.interests ?? const []);
    _preferences.addAll(initial?.preferences ?? const []);
    final birth = initial?.birthDate;
    if (birth != null) {
      _day = birth.day;
      _month = birth.month;
      _year = birth.year;
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _country.dispose();
    _bio.dispose();
    super.dispose();
  }

  bool get _photoReady {
    if (_photo != null) return true;
    if (widget.photoFileRequired) {
      return widget.keepExistingPhoto && _hasPhoto;
    }
    return _hasPhoto;
  }

  Future<void> _pickPhoto() async {
    final choose = widget.choosePhoto;
    if (choose == null) {
      setState(() => _hasPhoto = true);
      return;
    }
    try {
      final photo = await choose();
      if (!mounted || photo == null) return;
      setState(() {
        _photo = photo;
        _hasPhoto = true;
        _error = null;
      });
    } on AccountFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final birth = exactDate(_year, _month, _day);
    final fieldErrors = validateProfileFields(
      username: _username.text,
      birthDate: birth,
      country: _country.text,
      takenUsernames: widget.takenUsernames,
    );
    if (fieldErrors.hasAny) {
      setState(() {
        _fieldErrors = fieldErrors;
        _error = null;
      });
      return;
    }
    final draft = ProfileDraft(
      username: _username.text.trim().toLowerCase(),
      birthDate: birth!,
      gender: _gender ?? '',
      city: _country.text.trim(),
      bio: _bio.text.trim(),
      interests: _interests.toList(),
      preferences: _preferences.toList(),
      hasPhoto: _photoReady,
      photo: _photo,
    );
    setState(() {
      _saving = true;
      _fieldErrors = const ProfileFieldErrors();
      _error = null;
    });
    try {
      await widget.onSubmit(draft);
    } on AccountFailure catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not save your profile. Try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: widget.onBack == null
            ? null
            : IconButton(
                tooltip: 'Back',
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
              ),
      ),
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
                if (widget.stepLabel != null)
                  Text(
                    widget.stepLabel!,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: AppTokens.space8),
                Text(
                  'Adults 18 and older only. Username, country, and date of birth are required. Photo, bio, gender, interests, and preferences are optional.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppTokens.space12),
                Text(
                  'Date of birth *',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTokens.space16),
                Center(
                  child: _PhotoWell(
                    hasPhoto: _photoReady,
                    initials: _username.text.isEmpty
                        ? '?'
                        : _username.text[0].toUpperCase(),
                    bytes: _photo?.bytes,
                    remotePhoto: widget.choosePhoto != null,
                    onPressed: _saving ? null : _pickPhoto,
                  ),
                ),
                const SizedBox(height: AppTokens.space8),
                Text(
                  'Photo (optional)',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppTokens.space20),
                _EditorCard(
                  child: Column(
                    children: [
                      TextField(
                        key: const Key('username-field'),
                        controller: _username,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Username *',
                          helperText: '3–20 lowercase letters, numbers, or _',
                          errorText: _fieldErrors.username,
                          border: InputBorder.none,
                        ),
                        onChanged: (_) => setState(() {
                          _fieldErrors = ProfileFieldErrors(
                            username: null,
                            birthDate: _fieldErrors.birthDate,
                            country: _fieldErrors.country,
                          );
                        }),
                      ),
                      Divider(height: 1, color: theme.colorScheme.outlineVariant),
                      TextField(
                        key: const Key('city-field'),
                        controller: _country,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Country *',
                          errorText: _fieldErrors.country,
                          border: InputBorder.none,
                        ),
                        onChanged: (_) => setState(() {
                          _fieldErrors = ProfileFieldErrors(
                            username: _fieldErrors.username,
                            birthDate: _fieldErrors.birthDate,
                            country: null,
                          );
                        }),
                      ),
                      Divider(height: 1, color: theme.colorScheme.outlineVariant),
                      TextField(
                        key: const Key('bio-field'),
                        controller: _bio,
                        minLines: 3,
                        maxLines: 5,
                        maxLength: 300,
                        decoration: const InputDecoration(
                          labelText: 'Bio (optional)',
                          alignLabelWithHint: true,
                          border: InputBorder.none,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.space16),
                _EditorCard(
                  title: 'Birth date *',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _DateField(
                              label: 'Day',
                              value: _day,
                              items: [for (var day = 1; day <= 31; day++) day],
                              onChanged: (value) => setState(() {
                                _day = value;
                                _fieldErrors = ProfileFieldErrors(
                                  username: _fieldErrors.username,
                                  birthDate: null,
                                  country: _fieldErrors.country,
                                );
                              }),
                            ),
                          ),
                          const SizedBox(width: AppTokens.space8),
                          Expanded(
                            child: _DateField(
                              label: 'Month',
                              value: _month,
                              items: [
                                for (var month = 1; month <= 12; month++) month,
                              ],
                              onChanged: (value) => setState(() {
                                _month = value;
                                _fieldErrors = ProfileFieldErrors(
                                  username: _fieldErrors.username,
                                  birthDate: null,
                                  country: _fieldErrors.country,
                                );
                              }),
                            ),
                          ),
                          const SizedBox(width: AppTokens.space8),
                          Expanded(
                            flex: 2,
                            child: _DateField(
                              label: 'Year',
                              value: _year,
                              items: [
                                for (var year = now.year; year >= 1940; year--)
                                  year,
                              ],
                              onChanged: (value) => setState(() {
                                _year = value;
                                _fieldErrors = ProfileFieldErrors(
                                  username: _fieldErrors.username,
                                  birthDate: null,
                                  country: _fieldErrors.country,
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                      if (_fieldErrors.birthDate != null) ...[
                        const SizedBox(height: AppTokens.space8),
                        Text(
                          _fieldErrors.birthDate!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.space16),
                _EditorCard(
                  title: 'Gender (optional)',
                  child: Wrap(
                    spacing: AppTokens.space8,
                    runSpacing: AppTokens.space8,
                    children: [
                      for (final gender in ProfileOptions.genders)
                        ChoiceChip(
                          label: Text(gender),
                          selected: _gender == gender,
                          onSelected: (_) => setState(() {
                            _gender = _gender == gender ? null : gender;
                          }),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.space16),
                _EditorCard(
                  title: 'Interests (optional · ${_interests.length})',
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
                _EditorCard(
                  title:
                      'Relationship preferences (optional · ${_preferences.length})',
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
                if (_error != null) ...[
                  const SizedBox(height: AppTokens.space16),
                  Text(
                    _error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Material(
            elevation: 8,
            shadowColor: Colors.black26,
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(
                AppTokens.space20,
                AppTokens.space8,
                AppTokens.space20,
                AppTokens.space16,
              ),
              child: PrimaryButton(
                key: const Key('save-profile'),
                label: _saving ? 'Saving…' : widget.submitLabel,
                loading: _saving,
                onPressed: _saving ? null : () => _save(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorCard extends StatelessWidget {
  const _EditorCard({required this.child, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: AppTokens.lg,
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppTokens.space12),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class _PhotoWell extends StatelessWidget {
  const _PhotoWell({
    required this.hasPhoto,
    required this.initials,
    required this.remotePhoto,
    required this.onPressed,
    this.bytes,
  });

  final bool hasPhoto;
  final String initials;
  final bool remotePhoto;
  final VoidCallback? onPressed;
  final Uint8List? bytes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: AppTokens.xl,
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: remotePhoto ? onPressed : (hasPhoto ? null : onPressed),
        child: SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (bytes != null)
                Image.memory(bytes!, fit: BoxFit.cover)
              else
                ColoredBox(
                  color: theme.colorScheme.primaryContainer,
                  child: Center(
                    child: Text(
                      hasPhoto ? initials : '+',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: AppTokens.space8,
                bottom: AppTokens.space8,
                child: Material(
                  color: theme.colorScheme.primary,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.photo_camera_outlined,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final int? value;
  final List<int> items;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      isExpanded: true,
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: InputBorder.none,
        isDense: true,
      ),
      items: [
        for (final item in items)
          DropdownMenuItem(value: item, child: Text('$item')),
      ],
      onChanged: onChanged,
    );
  }
}
