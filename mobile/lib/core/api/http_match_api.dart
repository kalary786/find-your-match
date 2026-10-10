import 'dart:async';
import 'dart:convert';

import 'package:find_your_match/core/api/match_api.dart';
import 'package:find_your_match/features/ads/network_ad_settings.dart';
import 'package:find_your_match/core/api/token_store.dart';
import 'package:find_your_match/features/preview/preview_models.dart';
import 'package:find_your_match/features/profile/account_failure.dart';
import 'package:find_your_match/features/profile/profile_draft.dart';
import 'package:find_your_match/features/profile/profile_record.dart';
import 'package:find_your_match/features/profile/saved_account.dart';
import 'package:http/http.dart' as http;

class HttpMatchApi implements MatchApi {
  HttpMatchApi({
    required this.baseUrl,
    required this.tokens,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final TokenStore tokens;
  final http.Client _client;

  @override
  Future<MeResult?> restore() async {
    final token = await tokens.read();
    if (token == null || token.isEmpty) return null;
    final response = await _send('me');
    if (response.statusCode == 401) {
      await tokens.write(null);
      return null;
    }
    final body = _body(response);
    final profile = _profileMap(body['profile']);
    return MeResult(
      userId: body['userId']?.toString() ?? '',
      hasProfile: body['hasProfile'] == true && profile != null,
      account: profile == null ? null : _account(body['userId'], profile),
      showOnline: profile?['showOnline'] == true,
      showLastActive: profile?['showLastActive'] == true,
    );
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
  }) {
    return _auth('register', email: email, password: password);
  }

  @override
  Future<AuthSession> login({required String email, required String password}) {
    return _auth('login', email: email, password: password);
  }

  @override
  Future<void> logout() async {
    try {
      await _send('logout', method: 'POST');
    } on AccountFailure {
      // The local token is cleared either way.
    }
    await tokens.write(null);
  }

  @override
  Future<ProfileSave> createProfile(ProfileDraft draft) async {
    final body = _body(await _profile('createProfile', draft));
    final profile = _profileMap(body['profile']);
    if (profile == null) {
      throw const AccountFailure(
        AccountFailureKind.unknown,
        'The profile could not be saved. Try again.',
      );
    }
    return ProfileSave(
      alreadyExisted: body['alreadyExisted'] == true,
      account: _account(profile['id'], profile),
    );
  }

  @override
  Future<SavedAccount> updateProfile(ProfileDraft draft) async {
    final body = _body(await _profile('updateProfile', draft));
    final profile = _profileMap(body['profile']);
    if (profile == null) {
      throw const AccountFailure(
        AccountFailureKind.unknown,
        'The profile could not be saved. Try again.',
      );
    }
    return _account(profile['id'], profile);
  }

  @override
  Future<SavedAccount> setHidden(bool hidden) async {
    final body = _body(
      await _send('setHidden', method: 'POST', json: {'hidden': hidden}),
    );
    final profile = _profileMap(body['profile']);
    if (profile == null) {
      throw const AccountFailure(
        AccountFailureKind.unknown,
        'The profile could not be saved. Try again.',
      );
    }
    return _account(profile['id'], profile);
  }

  @override
  Future<void> setPrivacy({
    required bool showOnline,
    required bool showLastActive,
  }) async {
    _body(
      await _send(
        'setPrivacy',
        method: 'POST',
        json: {'showOnline': showOnline, 'showLastActive': showLastActive},
      ),
    );
  }

  @override
  Future<void> deleteAccount({required String password}) async {
    _body(
      await _send(
        'deleteAccount',
        method: 'POST',
        json: {'password': password},
      ),
    );
    await tokens.write(null);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String password,
  }) async {
    final body = _body(
      await _send(
        'changePassword',
        method: 'POST',
        json: {'currentPassword': currentPassword, 'password': password},
      ),
    );
    final token = body['token']?.toString() ?? '';
    if (token.isNotEmpty) {
      await tokens.write(token);
    }
  }

  @override
  Future<List<Person>> discover() async {
    final body = _body(await _send('discover'));
    return _people(body['people']);
  }

  @override
  Future<List<Person>> search({
    required String query,
    required SearchFilter filter,
  }) async {
    final body = _body(
      await _send(
        'search',
        method: 'POST',
        json: {
          'query': query,
          'minAge': filter.minAge,
          'maxAge': filter.maxAge,
          'gender': filter.gender,
          'interests': filter.interests.toList(),
          'preferences': filter.preferences.toList(),
        },
      ),
    );
    return _people(body['people']);
  }

  @override
  Future<bool> like(String userId) async {
    final body = _body(
      await _send('like', method: 'POST', json: {'userId': userId}),
    );
    return body['matched'] == true;
  }

  @override
  Future<void> pass(String userId) async {
    _body(await _send('pass', method: 'POST', json: {'userId': userId}));
  }

  @override
  Future<void> unmatch(String userId) async {
    _body(await _send('unmatch', method: 'POST', json: {'userId': userId}));
  }

  @override
  Future<List<Person>> matches() async {
    final body = _body(await _send('matches'));
    return _people(body['people']);
  }

  @override
  Future<List<ChatThread>> chats() async {
    final body = _body(await _send('chats'));
    final value = body['chats'];
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (stringKeyMap(item).isNotEmpty)
          ChatThread(
            person: personFromServer(
              uid: stringKeyMap(item)['id']?.toString() ?? '',
              profile: stringKeyMap(item),
              birthDate: null,
              photoUrl: stringKeyMap(item)['photoUrl']?.toString(),
            ),
            lastMessage: stringKeyMap(item)['lastMessage']?.toString() ?? '',
          ),
    ];
  }

  @override
  Future<List<ChatMessage>> messages(String userId, {String? before}) async {
    final body = _body(
      await _send(
        'messages',
        query: {
          'userId': userId,
          if (before != null && before.isNotEmpty) 'before': before,
        },
      ),
    );
    return _messages(body['messages']);
  }

  @override
  Future<ChatMessage> sendMessage({
    required String userId,
    required String text,
  }) async {
    final body = _body(
      await _send(
        'send',
        method: 'POST',
        json: {'userId': userId, 'text': text},
      ),
    );
    final message = stringKeyMap(body['message']);
    return ChatMessage(
      id: message['id']?.toString() ?? '',
      fromMe: message['fromMe'] == true,
      text: message['text']?.toString() ?? '',
      timeLabel: message['timeLabel']?.toString() ?? '',
    );
  }

  @override
  Future<void> block(String userId) async {
    _body(await _send('block', method: 'POST', json: {'userId': userId}));
  }

  @override
  Future<void> unblock(String userId) async {
    _body(await _send('unblock', method: 'POST', json: {'userId': userId}));
  }

  @override
  Future<List<Person>> blocked() async {
    final body = _body(await _send('blocked'));
    return _people(body['people']);
  }

  @override
  Future<void> report({
    required String userId,
    required String reason,
    required String details,
  }) async {
    _body(
      await _send(
        'report',
        method: 'POST',
        json: {'userId': userId, 'reason': reason, 'details': details},
      ),
    );
  }

  @override
  Future<List<AppNotice>> notices() async {
    final body = _body(await _send('notices'));
    final value = body['notices'];
    if (value is! List) return const [];
    return [
      for (final item in value)
        AppNotice(
          id: stringKeyMap(item)['id']?.toString() ?? '',
          title: stringKeyMap(item)['title']?.toString() ?? '',
          body: stringKeyMap(item)['body']?.toString() ?? '',
          linkUrl: stringKeyMap(item)['linkUrl']?.toString() ?? '',
          timeLabel: stringKeyMap(item)['timeLabel']?.toString() ?? '',
          read: stringKeyMap(item)['read'] == true,
        ),
    ];
  }

  @override
  Future<void> readNotice(String id) async {
    _body(await _send('readNotice', method: 'POST', json: {'id': id}));
  }

  @override
  Future<NetworkAdSettings> networkAds() async {
    final body = _body(await _send('networkAds'));
    return NetworkAdSettings.fromJson(body);
  }

  @override
  Future<HostedAd?> ad(String placement) async {
    final body = _body(await _send('ads', query: {'placement': placement}));
    final ad = stringKeyMap(body['ad']);
    if (ad.isEmpty) return null;
    return HostedAd(
      id: ad['id']?.toString() ?? '',
      title: ad['title']?.toString() ?? '',
      imageUrl: ad['imageUrl']?.toString() ?? '',
      linkUrl: ad['linkUrl']?.toString() ?? '',
      placement: ad['placement']?.toString() ?? placement,
    );
  }

  Future<AuthSession> _auth(
    String action, {
    required String email,
    required String password,
  }) async {
    final response = await _send(
      action,
      method: 'POST',
      json: {'email': email, 'password': password},
      withAuth: false,
    );
    final body = _body(response);
    final token = body['token']?.toString() ?? '';
    await tokens.write(token);
    final profile = _profileMap(body['profile']);
    return AuthSession(
      token: token,
      userId: body['userId']?.toString() ?? '',
      hasProfile: body['hasProfile'] == true && profile != null,
      account: profile == null ? null : _account(body['userId'], profile),
    );
  }

  Future<http.Response> _profile(String action, ProfileDraft draft) async {
    final request = http.MultipartRequest('POST', _uri(action));
    request.headers.addAll(await _headers(json: false));
    final data = draft.toCallableData();
    request.fields['username'] = data['username'].toString();
    request.fields['birthDate'] = data['birthDate'].toString();
    request.fields['gender'] = data['gender'].toString();
    request.fields['city'] = data['city'].toString();
    request.fields['bio'] = data['bio'].toString();
    request.fields['interests'] = jsonEncode(data['interests']);
    request.fields['preferences'] = jsonEncode(data['relationshipPreferences']);
    final photo = draft.photo;
    if (photo != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          photo.bytes,
          filename: 'avatar.jpg',
        ),
      );
    }
    try {
      final streamed = await _client.send(request);
      return http.Response.fromStream(streamed);
    } on http.ClientException {
      throw const AccountFailure(
        AccountFailureKind.offline,
        'You appear to be offline. Nothing was saved. Connect and try again.',
      );
    }
  }

  Future<http.Response> _send(
    String action, {
    String method = 'GET',
    Map<String, Object?>? json,
    Map<String, String>? query,
    bool withAuth = true,
  }) async {
    try {
      final headers = await _headers(json: json != null, withAuth: withAuth);
      final uri = _uri(action, query);
      if (method == 'POST') {
        return await _client
            .post(
              uri,
              headers: headers,
              body: json == null ? null : jsonEncode(json),
            )
            .timeout(const Duration(seconds: 20));
      }
      return await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const AccountFailure(
        AccountFailureKind.offline,
        'The website did not answer. Check the database in config.php, then try again.',
      );
    } on http.ClientException {
      throw const AccountFailure(
        AccountFailureKind.offline,
        'You appear to be offline. Nothing was saved. Connect and try again.',
      );
    }
  }

  Future<Map<String, String>> _headers({
    required bool json,
    bool withAuth = true,
  }) async {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (withAuth) {
      final token = await tokens.read();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        headers['X-Auth-Token'] = token;
      }
    }
    return headers;
  }

  Uri _uri(String action, [Map<String, String>? query]) {
    final root = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse(
      '$root/api/index.php',
    ).replace(queryParameters: {'action': action, ...?query});
  }

  Map<String, dynamic> _body(http.Response response) {
    Map<String, dynamic> decoded;
    try {
      decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : stringKeyMap(jsonDecode(response.body));
    } on FormatException {
      throw const AccountFailure(
        AccountFailureKind.unknown,
        'The website sent an unexpected reply. Try again.',
      );
    }
    if (response.statusCode >= 400) {
      throw AccountFailure.fromCode(
        decoded['error']?.toString() ?? 'unknown',
        decoded['message']?.toString(),
      );
    }
    return decoded;
  }

  Map<String, dynamic>? _profileMap(Object? value) {
    final map = stringKeyMap(value);
    if (map.isEmpty) return null;
    return map;
  }

  SavedAccount _account(Object? userId, Map<String, dynamic> profile) {
    return SavedAccount(
      person: personFromServer(
        uid: profile['id']?.toString() ?? userId?.toString() ?? '',
        profile: profile,
        birthDate: parseBirthDate(profile['birthDate']),
        photoUrl: profile['photoUrl']?.toString(),
      ),
      hidden: profile['hidden'] == true,
    );
  }

  List<Person> _people(Object? value) {
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (stringKeyMap(item).isNotEmpty)
          personFromServer(
            uid: stringKeyMap(item)['id']?.toString() ?? '',
            profile: stringKeyMap(item),
            birthDate: null,
            photoUrl: stringKeyMap(item)['photoUrl']?.toString(),
          ),
    ];
  }

  List<ChatMessage> _messages(Object? value) {
    if (value is! List) return const [];
    return [
      for (final item in value)
        ChatMessage(
          id: stringKeyMap(item)['id']?.toString() ?? '',
          fromMe: stringKeyMap(item)['fromMe'] == true,
          text: stringKeyMap(item)['text']?.toString() ?? '',
          timeLabel: stringKeyMap(item)['timeLabel']?.toString() ?? '',
        ),
    ];
  }
}
