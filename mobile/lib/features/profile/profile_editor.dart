import 'dart:typed_data';

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
  late final TextEditingController _city;
  late final TextEditingController _bio;
  int? _day;
  int? _month;
  int? _year;
  String? _gender;
  bool _hasPhoto = false;
  ProfilePhoto? _photo;
  final _interests = <String>{};
  final _preferences = <String>{};
  String? _error;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _username = TextEditingController(text: initial?.username ?? '');
    _city = TextEditingController(text: initial?.city ?? '');
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
    _city.dispose();
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
    final error = validateProfile(
      username: _username.text,
      birthDate: birth,
      gender: _gender,
      city: _city.text,
      bio: _bio.text,
      hasPhoto: _photoReady,
      interests: _interests,
      preferences: _preferences,
      takenUsernames: widget.takenUsernames,
    );
    if (error != null || birth == null) {
      setState(() => _error = error ?? 'Enter a real date of birth.');
      return;
    }
    final draft = ProfileDraft(
      username: _username.text.trim().toLowerCase(),
      birthDate: birth,
      gender: _gender!,
      city: _city.text.trim(),
      bio: _bio.text.trim(),
      interests: _interests.toList(),
      preferences: _preferences.toList(),
      hasPhoto: true,
      photo: _photo,
    );
    setState(() {
      _saving = true;
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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                if (widget.stepLabel != null)
                  Text(
                    widget.stepLabel!,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Adults 18 and older only. Required fields, a unique username, and age are checked again on your website before the profile is saved.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                _PhotoWell(
                  hasPhoto: _photoReady,
                  initials: _username.text.isEmpty
                      ? '?'
                      : _username.text[0].toUpperCase(),
                  bytes: _photo?.bytes,
                  remotePhoto: widget.choosePhoto != null,
                  onPressed: _saving ? null : _pickPhoto,
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('username-field'),
                  controller: _username,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    helperText: '3–20 lowercase letters, numbers, or _',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Text('Date of birth', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'Day',
                        value: _day,
                        items: [for (var day = 1; day <= 31; day++) day],
                        onChanged: (value) => setState(() => _day = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DateField(
                        label: 'Month',
                        value: _month,
                        items: [for (var month = 1; month <= 12; month++) month],
                        onChanged: (value) => setState(() => _month = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _DateField(
                        label: 'Year',
                        value: _year,
                        items: [
                          for (var year = now.year; year >= 1940; year--) year,
                        ],
                        onChanged: (value) => setState(() => _year = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('city-field'),
                  controller: _city,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'City'),
                ),
                const SizedBox(height: 16),
                Text('Gender', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final gender in ProfileOptions.genders)
                      ChoiceChip(
                        label: Text(gender),
                        selected: _gender == gender,
                        onSelected: (_) => setState(() => _gender = gender),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('bio-field'),
                  controller: _bio,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 300,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
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
                if (_error != null) ...[
                  const SizedBox(height: 16),
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
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: PrimaryButton(
              key: const Key('save-profile'),
              label: _saving ? 'Saving…' : widget.submitLabel,
              onPressed: _saving ? null : () => _save(),
            ),
          ),
        ],
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
    final label = remotePhoto
        ? (hasPhoto ? 'Change photo' : 'Choose photo')
        : (hasPhoto ? 'Preview photo added' : 'Add preview photo');
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage: bytes == null ? null : MemoryImage(bytes!),
          child: bytes != null
              ? null
              : Text(
                  hasPhoto ? initials : '+',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton(
            onPressed: remotePhoto ? onPressed : (hasPhoto ? null : onPressed),
            child: Text(label),
          ),
        ),
      ],
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
      decoration: InputDecoration(labelText: label),
      items: [
        for (final item in items)
          DropdownMenuItem(value: item, child: Text('$item')),
      ],
      onChanged: onChanged,
    );
  }
}
