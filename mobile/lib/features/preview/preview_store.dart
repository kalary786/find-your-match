import 'package:find_your_match/features/preview/mock_people.dart';
import 'package:find_your_match/features/preview/preview_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PreviewState {
  const PreviewState({
    required this.self,
    required this.hidden,
    required this.showOnline,
    required this.showLastActive,
    required this.likedIds,
    required this.passedIds,
    required this.blockedIds,
    required this.reportedIds,
    required this.query,
    required this.filter,
    required this.messages,
  });

  factory PreviewState.initial() {
    return PreviewState(
      self: null,
      hidden: false,
      showOnline: false,
      showLastActive: false,
      likedIds: {...MockPeople.presetLikedIds},
      passedIds: const {},
      blockedIds: const {},
      reportedIds: const {},
      query: '',
      filter: const SearchFilter(),
      messages: MockPeople.initialMessages(),
    );
  }

  final Person? self;
  final bool hidden;
  final bool showOnline;
  final bool showLastActive;
  final Set<String> likedIds;
  final Set<String> passedIds;
  final Set<String> blockedIds;
  final Set<String> reportedIds;
  final String query;
  final SearchFilter filter;
  final Map<String, List<PreviewMessage>> messages;

  Person get viewer => self ?? MockPeople.viewerStandIn;

  List<Person> get discoverQueue {
    return MockPeople.catalog.where((person) {
      if (blockedIds.contains(person.id)) return false;
      if (likedIds.contains(person.id)) return false;
      if (passedIds.contains(person.id)) return false;
      return true;
    }).toList();
  }

  List<Person> get matches {
    return MockPeople.catalog.where((person) {
      return person.likesYou &&
          likedIds.contains(person.id) &&
          !blockedIds.contains(person.id);
    }).toList();
  }

  List<Person> get searchResults {
    final needle = query.trim().toLowerCase();
    return MockPeople.catalog.where((person) {
      if (blockedIds.contains(person.id)) return false;
      if (person.age < filter.minAge || person.age > filter.maxAge) {
        return false;
      }
      final gender = filter.gender;
      if (gender != null && person.gender != gender) return false;
      if (filter.interests.isNotEmpty &&
          !person.interests.any(filter.interests.contains)) {
        return false;
      }
      if (filter.preferences.isNotEmpty &&
          !person.preferences.any(filter.preferences.contains)) {
        return false;
      }
      if (needle.isEmpty) return true;
      return person.username.toLowerCase().contains(needle) ||
          person.city.toLowerCase().contains(needle);
    }).toList();
  }

  List<Person> get blockedPeople {
    return MockPeople.catalog
        .where((person) => blockedIds.contains(person.id))
        .toList();
  }

  Person? personById(String id) {
    if (viewer.id == id) return viewer;
    for (final person in MockPeople.catalog) {
      if (person.id == id) return person;
    }
    return null;
  }

  bool isMatched(String id) {
    return matches.any((person) => person.id == id);
  }

  PreviewState copyWith({
    Person? self,
    bool clearSelf = false,
    bool? hidden,
    bool? showOnline,
    bool? showLastActive,
    Set<String>? likedIds,
    Set<String>? passedIds,
    Set<String>? blockedIds,
    Set<String>? reportedIds,
    String? query,
    SearchFilter? filter,
    Map<String, List<PreviewMessage>>? messages,
  }) {
    return PreviewState(
      self: clearSelf ? null : (self ?? this.self),
      hidden: hidden ?? this.hidden,
      showOnline: showOnline ?? this.showOnline,
      showLastActive: showLastActive ?? this.showLastActive,
      likedIds: likedIds ?? this.likedIds,
      passedIds: passedIds ?? this.passedIds,
      blockedIds: blockedIds ?? this.blockedIds,
      reportedIds: reportedIds ?? this.reportedIds,
      query: query ?? this.query,
      filter: filter ?? this.filter,
      messages: messages ?? this.messages,
    );
  }
}

class PreviewController extends Notifier<PreviewState> {
  @override
  PreviewState build() => PreviewState.initial();

  void saveSelf(Person person) {
    state = state.copyWith(self: person);
  }

  void clearSelf() {
    state = PreviewState.initial();
  }

  void setHidden(bool hidden) => state = state.copyWith(hidden: hidden);

  void setShowOnline(bool value) => state = state.copyWith(showOnline: value);

  void setShowLastActive(bool value) {
    state = state.copyWith(showLastActive: value);
  }

  void setQuery(String query) => state = state.copyWith(query: query);

  void setFilter(SearchFilter filter) => state = state.copyWith(filter: filter);

  /// True when the like is mutual inside this preview.
  bool like(String id) {
    if (state.blockedIds.contains(id)) return false;
    final liked = {...state.likedIds, id};
    final passed = {...state.passedIds}..remove(id);
    state = state.copyWith(likedIds: liked, passedIds: passed);
    final person = state.personById(id);
    return person?.likesYou ?? false;
  }

  void pass(String id) {
    final passed = {...state.passedIds, id};
    state = state.copyWith(passedIds: passed);
  }

  void resetDeck() {
    state = state.copyWith(
      likedIds: {...MockPeople.presetLikedIds},
      passedIds: {},
    );
  }

  void block(String id) {
    final blocked = {...state.blockedIds, id};
    final liked = {...state.likedIds}..remove(id);
    state = state.copyWith(blockedIds: blocked, likedIds: liked);
  }

  void unblock(String id) {
    final blocked = {...state.blockedIds}..remove(id);
    state = state.copyWith(blockedIds: blocked);
  }

  void report(String id) {
    final reported = {...state.reportedIds, id};
    state = state.copyWith(reportedIds: reported);
  }

  void sendMessage(String id, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.blockedIds.contains(id)) return;
    final next = {
      for (final entry in state.messages.entries)
        entry.key: List<PreviewMessage>.from(entry.value),
    };
    final thread = List<PreviewMessage>.from(next[id] ?? const <PreviewMessage>[]);
    thread.add(
      PreviewMessage(
        id: 'local-${thread.length + 1}',
        fromMe: true,
        text: trimmed,
        timeLabel: 'Now',
      ),
    );
    next[id] = thread;
    state = state.copyWith(messages: next);
  }
}

final previewControllerProvider =
    NotifierProvider<PreviewController, PreviewState>(PreviewController.new);
