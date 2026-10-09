import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('two likes create one match and a repeat does not create another', () {
    final book = MatchBook();
    expect(book.like(1, 2), isFalse);
    expect(book.like(2, 1), isTrue);
    expect(book.matches, ['1:2']);
    expect(book.like(1, 2), isTrue);
    expect(book.matches, ['1:2']);
    expect(book.swipes['1:2'], isTrue);
    expect(book.swipes['2:1'], isTrue);
  });

  test('the second like still matches when the first like arrived later', () {
    final book = MatchBook();
    expect(book.like(2, 1), isFalse);
    expect(book.like(1, 2), isTrue);
    expect(book.matches, ['1:2']);
  });

  test('a pass cannot erase a match, and unmatch removes both swipes', () {
    final book = MatchBook();
    book.like(1, 2);
    book.like(2, 1);
    expect(() => book.pass(1, 2), throwsStateError);
    expect(book.matches, ['1:2']);
    book.unmatch(1, 2);
    expect(book.matches, isEmpty);
    expect(book.swipes, isEmpty);
    expect(book.blocks, isEmpty);
  });

  test('a block closes chat and unblock does not restore an unmatched pair', () {
    final book = MatchBook();
    book.like(1, 2);
    book.like(2, 1);
    book.send(1, 2, 'hello', DateTime(2026, 10, 9, 12));
    book.block(2, 1);
    expect(book.matches, ['1:2']);
    expect(book.canMessage(1, 2), isFalse);
    expect(
      () => book.send(1, 2, 'again', DateTime(2026, 10, 9, 12, 1)),
      throwsStateError,
    );
    book.unblock(2, 1);
    expect(book.canMessage(1, 2), isTrue);
    book.unmatch(1, 2);
    book.unblock(2, 1);
    expect(book.matches, isEmpty);
    expect(book.canMessage(1, 2), isFalse);
  });

  test('the daily cap uses one server day and resets on the next day', () {
    final book = MatchBook();
    book.like(1, 2);
    book.like(2, 1);
    final day = DateTime(2026, 10, 9);
    for (var i = 0; i < 100; i++) {
      book.send(1, 2, 'm', day.add(Duration(minutes: i)));
    }
    expect(
      () => book.send(1, 2, 'over', day.add(const Duration(hours: 20))),
      throwsStateError,
    );
    book.send(1, 2, 'next', DateTime(2026, 10, 10, 0, 1));
    expect(book.messages.length, 101);
  });

  test('message length stops at 1000 characters', () {
    final book = MatchBook();
    book.like(1, 2);
    book.like(2, 1);
    book.send(1, 2, 'a' * 1000, DateTime(2026, 10, 9, 12));
    expect(
      () => book.send(1, 2, 'a' * 1001, DateTime(2026, 10, 9, 12, 1)),
      throwsStateError,
    );
    expect(() => book.send(1, 2, '   ', DateTime(2026, 10, 9, 12, 2)), throwsStateError);
  });

  test('the server schema and endpoints keep the match and chat limits', () {
    final schema = _serverFile('schema.sql');
    final api = _serverFile('api/index.php');
    expect(schema, contains('UNIQUE KEY swipe_pair'));
    expect(schema, contains('UNIQUE KEY match_pair'));
    expect(schema, contains('match_id INT UNSIGNED NOT NULL UNIQUE'));
    expect(schema, contains('body VARCHAR(1000)'));
    expect(schema, contains('UNIQUE KEY block_pair'));
    expect(
      schema,
      contains(
        'CONSTRAINT fk_conversations_match FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE',
      ),
    );
    expect(
      schema,
      contains(
        'CONSTRAINT fk_messages_conversation FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE',
      ),
    );

    final discover = _function(api, 'list_discover');
    expect(discover, contains('p.user_id <> ?'));
    expect(discover, contains('p.hidden = 0'));
    expect(discover, contains('u.blocked = 0'));
    expect(discover, contains('FROM swipes'));
    expect(discover, contains('FROM blocks'));
    expect(discover, contains('LIMIT 30'));

    final search = _function(api, 'list_search');
    expect(search.indexOf('JSON_CONTAINS'), lessThan(search.indexOf('LIMIT 50')));
    expect(search, isNot(contains('array_intersect')));
    expect(search, contains('p.user_id <> ?'));
    expect(search, contains('p.hidden = 0'));
    expect(search, contains('FROM blocks'));

    final swipe = _function(api, 'swipe');
    expect(swipe, contains('fym-pair-'));
    expect(swipe, contains('INSERT IGNORE INTO matches'));
    expect(swipe, contains('ON DUPLICATE KEY UPDATE liked = VALUES(liked)'));
    expect(swipe, contains('beginTransaction'));

    final unmatch = _function(api, 'unmatch_user');
    expect(unmatch, contains('DELETE FROM matches'));
    expect(unmatch, contains('DELETE FROM swipes'));
    expect(unmatch, contains('from_user_id = ? AND to_user_id = ?'));
    expect(unmatch, contains('beginTransaction'));
    expect(unmatch, isNot(contains('DELETE FROM blocks')));

    final messages = _function(api, 'list_messages');
    expect(messages.indexOf('require_visible_peer'), lessThan(messages.indexOf('SELECT id')));
    expect(messages, contains('AND id < ?'));
    expect(messages, contains('LIMIT 50'));
    expect(messages, isNot(contains('LIMIT 200')));

    final send = _function(api, 'send_message');
    expect(send.indexOf('require_visible_peer'), lessThan(send.indexOf('INSERT INTO messages')));
    expect(send, contains('message_text'));
    expect(send, contains('server_day_bounds'));
    expect(send, contains('created_at >= ? AND created_at < ?'));
    expect(send, contains('>= 100'));
    expect(send, contains('fym-msg-'));

    final unblock = _function(api, 'unblock_user');
    expect(unblock, contains('DELETE FROM blocks'));
    expect(unblock, isNot(contains('INSERT INTO matches')));
    expect(
      _function(_serverFile('lib/bootstrap.php'), 'require_visible_peer'),
      contains('blocked_either'),
    );
  });
}

class MatchBook {
  final swipes = <String, bool>{};
  final matches = <String>[];
  final blocks = <String>{};
  final messages = <_Note>[];

  bool like(int from, int to) {
    if (from == to || _blocked(from, to)) {
      throw StateError('unavailable');
    }
    swipes['$from:$to'] = true;
    final pair = _pair(from, to);
    if (swipes['$to:$from'] == true && !matches.contains(pair)) {
      matches.add(pair);
    }
    return matches.contains(pair);
  }

  void pass(int from, int to) {
    if (matches.contains(_pair(from, to))) {
      throw StateError('unmatch');
    }
    swipes['$from:$to'] = false;
  }

  void unmatch(int a, int b) {
    final pair = _pair(a, b);
    matches.remove(pair);
    swipes.remove('$a:$b');
    swipes.remove('$b:$a');
    messages.removeWhere((note) => note.pair == pair);
  }

  void block(int from, int to) {
    blocks.add('$from:$to');
  }

  void unblock(int from, int to) {
    blocks.remove('$from:$to');
  }

  bool canMessage(int from, int to) {
    return matches.contains(_pair(from, to)) && !_blocked(from, to);
  }

  void send(int from, int to, String text, DateTime at) {
    if (!canMessage(from, to)) throw StateError('closed');
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length > 1000) throw StateError('length');
    final start = DateTime(at.year, at.month, at.day);
    final end = start.add(const Duration(days: 1));
    final sentToday = messages
        .where(
          (note) =>
              note.sender == from && !note.at.isBefore(start) && note.at.isBefore(end),
        )
        .length;
    if (sentToday >= 100) throw StateError('limit');
    messages.add(_Note(_pair(from, to), from, at));
  }

  bool _blocked(int a, int b) => blocks.contains('$a:$b') || blocks.contains('$b:$a');

  String _pair(int a, int b) {
    final low = a < b ? a : b;
    final high = a < b ? b : a;
    return '$low:$high';
  }
}

class _Note {
  _Note(this.pair, this.sender, this.at);

  final String pair;
  final int sender;
  final DateTime at;
}

String _serverFile(String name) {
  final direct = File('server/$name');
  final nested = File('../server/$name');
  final file = direct.existsSync() ? direct : nested;
  return file.readAsStringSync();
}

String _function(String source, String name) {
  final start = source.indexOf('function $name');
  expect(start, greaterThanOrEqualTo(0), reason: 'missing $name');
  final next = source.indexOf('\nfunction ', start + 10);
  return source.substring(start, next < 0 ? source.length : next);
}
