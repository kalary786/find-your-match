import 'package:find_your_match/core/api/match_api.dart';
import 'package:find_your_match/core/session/session_controller.dart';
import 'package:find_your_match/features/preview/preview_models.dart';
import 'package:find_your_match/features/profile/account_failure.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// When set, widget tests render this directory and skip network loads.
final socialSeedProvider = Provider<SocialState?>((ref) => null);

class SocialState {
  const SocialState({
    this.discover = const [],
    this.searchResults = const [],
    this.matches = const [],
    this.chats = const [],
    this.messages = const {},
    this.blocked = const [],
    this.query = '',
    this.filter = const SearchFilter(),
    this.showOnline = false,
    this.showLastActive = false,
    this.ads = const {},
    this.loading = false,
    this.error,
    this.loaded = false,
  });

  final List<Person> discover;
  final List<Person> searchResults;
  final List<Person> matches;
  final List<ChatThread> chats;
  final Map<String, List<ChatMessage>> messages;
  final List<Person> blocked;
  final String query;
  final SearchFilter filter;
  final bool showOnline;
  final bool showLastActive;
  final Map<String, HostedAd?> ads;
  final bool loading;
  final String? error;
  final bool loaded;

  Person? personById(String id) {
    for (final person in [
      ...discover,
      ...searchResults,
      ...matches,
      ...blocked,
      ...chats.map((chat) => chat.person),
    ]) {
      if (person.id == id) return person;
    }
    return null;
  }

  bool isMatched(String id) => matches.any((person) => person.id == id);

  SocialState copyWith({
    List<Person>? discover,
    List<Person>? searchResults,
    List<Person>? matches,
    List<ChatThread>? chats,
    Map<String, List<ChatMessage>>? messages,
    List<Person>? blocked,
    String? query,
    SearchFilter? filter,
    bool? showOnline,
    bool? showLastActive,
    Map<String, HostedAd?>? ads,
    bool? loading,
    String? error,
    bool clearError = false,
    bool? loaded,
  }) {
    return SocialState(
      discover: discover ?? this.discover,
      searchResults: searchResults ?? this.searchResults,
      matches: matches ?? this.matches,
      chats: chats ?? this.chats,
      messages: messages ?? this.messages,
      blocked: blocked ?? this.blocked,
      query: query ?? this.query,
      filter: filter ?? this.filter,
      showOnline: showOnline ?? this.showOnline,
      showLastActive: showLastActive ?? this.showLastActive,
      ads: ads ?? this.ads,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      loaded: loaded ?? this.loaded,
    );
  }
}

class SocialController extends Notifier<SocialState> {
  var _loading = false;

  @override
  SocialState build() {
    return ref.watch(socialSeedProvider) ?? const SocialState();
  }

  Future<void> ensureLoaded() async {
    if (_loading || state.loaded || ref.read(socialSeedProvider) != null) {
      return;
    }
    _loading = true;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final api = ref.read(matchApiProvider);
      final me = await api.restore();
      final discover = await api.discover();
      final matches = await api.matches();
      final chats = await api.chats();
      final blocked = await api.blocked();
      final discoverAd = await api.ad('discover');
      final searchAd = await api.ad('search');
      final matchesAd = await api.ad('matches');
      state = state.copyWith(
        discover: discover,
        matches: matches,
        chats: chats,
        blocked: blocked,
        showOnline: me?.showOnline ?? state.showOnline,
        showLastActive: me?.showLastActive ?? state.showLastActive,
        ads: {
          'discover': discoverAd,
          'search': searchAd,
          'matches': matchesAd,
        },
        loading: false,
        loaded: true,
        clearError: true,
      );
    } on AccountFailure catch (error) {
      state = state.copyWith(loading: false, error: error.message);
    } finally {
      _loading = false;
    }
  }

  Future<bool> like(String userId) async {
    final matched = await ref.read(matchApiProvider).like(userId);
    state = state.copyWith(
      discover: [
        for (final person in state.discover)
          if (person.id != userId) person,
      ],
    );
    if (matched) {
      state = state.copyWith(matches: await ref.read(matchApiProvider).matches());
      state = state.copyWith(chats: await ref.read(matchApiProvider).chats());
    }
    return matched;
  }

  Future<void> pass(String userId) async {
    await ref.read(matchApiProvider).pass(userId);
    state = state.copyWith(
      discover: [
        for (final person in state.discover)
          if (person.id != userId) person,
      ],
    );
  }

  Future<void> search(String query) async {
    state = state.copyWith(query: query);
    final results = await ref.read(matchApiProvider).search(
      query: query,
      filter: state.filter,
    );
    state = state.copyWith(searchResults: results, query: query);
  }

  Future<void> setFilter(SearchFilter filter) async {
    state = state.copyWith(filter: filter);
    final results = await ref.read(matchApiProvider).search(
      query: state.query,
      filter: filter,
    );
    state = state.copyWith(searchResults: results, filter: filter);
  }

  Future<void> openChat(String userId) async {
    if (state.messages.containsKey(userId)) return;
    final messages = await ref.read(matchApiProvider).messages(userId);
    state = state.copyWith(messages: {...state.messages, userId: messages});
  }

  Future<void> sendMessage(String userId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final message = await ref.read(matchApiProvider).sendMessage(
      userId: userId,
      text: trimmed,
    );
    final existing = state.messages[userId] ?? const <ChatMessage>[];
    state = state.copyWith(
      messages: {
        ...state.messages,
        userId: [...existing, message],
      },
    );
  }

  Future<void> block(String userId) async {
    await ref.read(matchApiProvider).block(userId);
    state = state.copyWith(
      discover: [
        for (final person in state.discover)
          if (person.id != userId) person,
      ],
      searchResults: [
        for (final person in state.searchResults)
          if (person.id != userId) person,
      ],
      matches: [
        for (final person in state.matches)
          if (person.id != userId) person,
      ],
      chats: [
        for (final chat in state.chats)
          if (chat.person.id != userId) chat,
      ],
      blocked: await ref.read(matchApiProvider).blocked(),
    );
  }

  Future<void> unblock(String userId) async {
    await ref.read(matchApiProvider).unblock(userId);
    state = state.copyWith(
      blocked: [
        for (final person in state.blocked)
          if (person.id != userId) person,
      ],
    );
  }

  Future<void> report({
    required String userId,
    required String reason,
    required String details,
  }) {
    return ref.read(matchApiProvider).report(
      userId: userId,
      reason: reason,
      details: details,
    );
  }

  Future<void> setShowOnline(bool value) async {
    await ref.read(matchApiProvider).setPrivacy(
      showOnline: value,
      showLastActive: state.showLastActive,
    );
    state = state.copyWith(showOnline: value);
  }

  Future<void> setShowLastActive(bool value) async {
    await ref.read(matchApiProvider).setPrivacy(
      showOnline: state.showOnline,
      showLastActive: value,
    );
    state = state.copyWith(showLastActive: value);
  }
}

final socialControllerProvider =
    NotifierProvider<SocialController, SocialState>(SocialController.new);
