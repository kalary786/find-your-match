<?php

declare(strict_types=1);

require dirname(__DIR__) . '/lib/bootstrap.php';

cors_headers();
if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$action = (string) ($_GET['action'] ?? '');

try {
    match ($action) {
        'register' => register_user(),
        'login' => login_user(),
        'logout' => logout_user(),
        'me' => show_me(),
        'createProfile' => save_profile(true),
        'updateProfile' => save_profile(false),
        'setHidden' => set_hidden(),
        'setPrivacy' => set_privacy(),
        'deleteAccount' => delete_account(),
        'changePassword' => change_password(),
        'discover' => list_discover(),
        'search' => list_search(),
        'like' => swipe(true),
        'pass' => swipe(false),
        'matches' => list_matches(),
        'chats' => list_chats(),
        'messages' => list_messages(),
        'send' => send_message(),
        'unmatch' => unmatch_user(),
        'block' => block_user(),
        'unblock' => unblock_user(),
        'blocked' => list_blocked(),
        'report' => report_user(),
        'ads' => list_ads(),
        'networkAds' => list_network_ads(),
        'notices' => list_notices(),
        'readNotice' => read_notice(),
        default => fail(404, 'not-found', 'That action is not available.'),
    };
} catch (PDOException $error) {
    fail(500, 'setup', 'The database could not complete that request. Check config.php, then open install.php once.');
} catch (RuntimeException $error) {
    fail(400, 'invalid-argument', $error->getMessage());
}

function register_user(): void
{
    $input = request_data();
    $email = normalize_email($input['email'] ?? '');
    $password = (string) ($input['password'] ?? '');
    if (strlen($password) < 8) {
        fail(400, 'invalid-argument', 'Use a password of at least 8 characters.');
    }
    $ipKey = 'ip:' . client_ip();
    if (rate_limit_blocked('register', $ipKey, 5, 3600)) {
        fail(429, 'resource-exhausted', 'Too many attempts. Try again later.');
    }
    rate_limit_record('register', $ipKey);
    $statement = db()->prepare('SELECT id, blocked FROM users WHERE email = ? LIMIT 1');
    $statement->execute([$email]);
    if ($statement->fetch()) {
        fail(409, 'already-exists', 'An account with that email already exists. Sign in instead.');
    }
    $insert = db()->prepare(
        'INSERT INTO users (email, password_hash, created_at) VALUES (?, ?, ?)'
    );
    $insert->execute([$email, password_hash($password, PASSWORD_DEFAULT), now()]);
    $userId = (int) db()->lastInsertId();
    json_out(auth_payload($userId, issue_token($userId)), 201);
}

function login_user(): void
{
    $input = request_data();
    $email = normalize_email($input['email'] ?? '');
    $password = (string) ($input['password'] ?? '');
    $emailKey = 'email:' . $email;
    $ipKey = 'ip:' . client_ip();
    if (rate_limit_blocked('login', $emailKey, 8, 900) || rate_limit_blocked('login', $ipKey, 30, 900)) {
        fail(429, 'resource-exhausted', 'Too many attempts. Try again later.');
    }
    $statement = db()->prepare('SELECT id, password_hash, blocked FROM users WHERE email = ? LIMIT 1');
    $statement->execute([$email]);
    $user = $statement->fetch();
    if (!$user || !password_verify($password, (string) $user['password_hash'])) {
        rate_limit_record('login', $emailKey);
        rate_limit_record('login', $ipKey);
        fail(401, 'unauthenticated', 'Email or password is incorrect.');
    }
    rate_limit_clear('login', $emailKey);
    if ((int) $user['blocked'] === 1) {
        fail(403, 'blocked', 'This account is blocked.');
    }
    $userId = (int) $user['id'];
    json_out(auth_payload($userId, issue_token($userId)));
}

function logout_user(): void
{
    $token = bearer_token();
    if ($token) {
        $statement = db()->prepare(
            'UPDATE users SET token_hash = NULL, token_expires_at = NULL WHERE token_hash = ?'
        );
        $statement->execute([hash('sha256', $token)]);
    }
    json_out(['ok' => true]);
}

function show_me(): void
{
    $user = current_user();
    $userId = (int) $user['id'];
    touch_active($userId);
    $profile = load_profile($userId);
    json_out([
        'userId' => (string) $userId,
        'email' => $user['email'],
        'hasProfile' => $profile !== null,
        'profile' => $profile ? person_payload($profile, true) : null,
    ]);
}

function save_profile(bool $creating): void
{
    $user = current_user();
    $userId = (int) $user['id'];
    $existing = load_profile($userId);
    if ($creating && $existing) {
        json_out([
            'alreadyExisted' => true,
            'profile' => person_payload($existing, true),
        ]);
    }
    if (!$creating && !$existing) {
        fail(400, 'failed-precondition', 'Create a profile before changing it.');
    }
    if ($existing && strtotime((string) $existing['updated_at']) > time() - 3) {
        fail(429, 'resource-exhausted', 'Please wait a few seconds before saving again.');
    }
    $fields = validate_profile_fields(
        request_data(),
        $creating,
        $existing !== null && !empty($existing['photo_path'])
    );
    $owner = db()->prepare('SELECT user_id FROM profiles WHERE username = ? AND user_id <> ? LIMIT 1');
    $owner->execute([$fields['username'], $userId]);
    if ($owner->fetch()) {
        fail(409, 'already-exists', 'That username is already taken.');
    }
    $photoPath = $existing['photo_path'] ?? null;
    if (!empty($_FILES['photo']['tmp_name'])) {
        $uploaded = store_image($_FILES['photo'], 'photos');
        unlink_public(is_string($photoPath) ? $photoPath : null);
        $photoPath = $uploaded;
    }
    if ($creating && ($photoPath === null || $photoPath === '')) {
        fail(400, 'invalid-argument', 'Add a photo to continue.');
    }
    $stamp = now();
    if ($creating) {
        $insert = db()->prepare(
            'INSERT INTO profiles
            (user_id, username, birth_date, age, gender, city, bio, interests, preferences, photo_path, hidden, last_active_at, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?)'
        );
        $insert->execute([
            $userId,
            $fields['username'],
            $fields['birthDate'],
            $fields['age'],
            $fields['gender'],
            $fields['city'],
            $fields['bio'],
            json_encode($fields['interests']),
            json_encode($fields['preferences']),
            $photoPath,
            $stamp,
            $stamp,
            $stamp,
        ]);
    } else {
        $update = db()->prepare(
            'UPDATE profiles SET username = ?, birth_date = ?, age = ?, gender = ?, city = ?, bio = ?,
            interests = ?, preferences = ?, photo_path = ?, updated_at = ?, last_active_at = ? WHERE user_id = ?'
        );
        $update->execute([
            $fields['username'],
            $fields['birthDate'],
            $fields['age'],
            $fields['gender'],
            $fields['city'],
            $fields['bio'],
            json_encode($fields['interests']),
            json_encode($fields['preferences']),
            $photoPath,
            $stamp,
            $stamp,
            $userId,
        ]);
    }
    $saved = load_profile($userId);
    json_out([
        'alreadyExisted' => false,
        'profile' => person_payload($saved ?: [], true),
    ]);
}

function set_hidden(): void
{
    $user = current_user();
    $profile = load_profile((int) $user['id']);
    if (!$profile) {
        fail(400, 'failed-precondition', 'Create a profile before changing it.');
    }
    $hidden = request_data()['hidden'] ?? false;
    $flag = filter_var($hidden, FILTER_VALIDATE_BOOLEAN) ? 1 : 0;
    $statement = db()->prepare('UPDATE profiles SET hidden = ?, updated_at = ? WHERE user_id = ?');
    $statement->execute([$flag, now(), (int) $user['id']]);
    $saved = load_profile((int) $user['id']);
    json_out(['profile' => person_payload($saved ?: [], true)]);
}

function set_privacy(): void
{
    $user = current_user();
    $profile = load_profile((int) $user['id']);
    if (!$profile) {
        fail(400, 'failed-precondition', 'Create a profile before changing it.');
    }
    $input = request_data();
    $online = filter_var($input['showOnline'] ?? false, FILTER_VALIDATE_BOOLEAN) ? 1 : 0;
    $active = filter_var($input['showLastActive'] ?? false, FILTER_VALIDATE_BOOLEAN) ? 1 : 0;
    $statement = db()->prepare(
        'UPDATE profiles SET show_online = ?, show_last_active = ? WHERE user_id = ?'
    );
    $statement->execute([$online, $active, (int) $user['id']]);
    json_out(['ok' => true, 'showOnline' => $online === 1, 'showLastActive' => $active === 1]);
}

function delete_account(): void
{
    $user = current_user();
    $userId = (int) $user['id'];
    $key = 'user:' . $userId;
    if (rate_limit_blocked('delete', $key, 8, 900)) {
        fail(429, 'resource-exhausted', 'Too many attempts. Try again later.');
    }
    $password = (string) (request_data()['password'] ?? '');
    $statement = db()->prepare('SELECT password_hash FROM users WHERE id = ? LIMIT 1');
    $statement->execute([$userId]);
    $hash = (string) $statement->fetchColumn();
    if ($hash === '' || !password_verify($password, $hash)) {
        rate_limit_record('delete', $key);
        fail(400, 'invalid-argument', 'The password is incorrect.');
    }
    rate_limit_clear('delete', $key);
    delete_user_account($userId);
    json_out(['ok' => true]);
}

function change_password(): void
{
    $user = current_user();
    $userId = (int) $user['id'];
    $key = 'user:' . $userId;
    if (rate_limit_blocked('password', $key, 5, 900)) {
        fail(429, 'resource-exhausted', 'Too many attempts. Try again later.');
    }
    $input = request_data();
    $current = (string) ($input['currentPassword'] ?? '');
    $next = (string) ($input['password'] ?? '');
    if (strlen($next) < 8) {
        fail(400, 'invalid-argument', 'Use a password of at least 8 characters.');
    }
    $statement = db()->prepare('SELECT password_hash FROM users WHERE id = ? LIMIT 1');
    $statement->execute([$userId]);
    $hash = (string) $statement->fetchColumn();
    if ($hash === '' || !password_verify($current, $hash)) {
        rate_limit_record('password', $key);
        fail(400, 'invalid-argument', 'The current password is incorrect.');
    }
    rate_limit_clear('password', $key);
    $pdo = db();
    $pdo->beginTransaction();
    try {
        $update = $pdo->prepare('UPDATE users SET password_hash = ? WHERE id = ?');
        $update->execute([password_hash($next, PASSWORD_DEFAULT), $userId]);
        $token = issue_token($userId);
        $pdo->commit();
    } catch (Throwable $error) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $error;
    }
    json_out(['ok' => true, 'token' => $token]);
}

function list_discover(): void
{
    $user = current_user();
    $userId = (int) $user['id'];
    touch_active($userId);
    $statement = db()->prepare(
        'SELECT p.* FROM profiles p
         JOIN users u ON u.id = p.user_id
         WHERE p.user_id <> ?
           AND p.hidden = 0
           AND u.blocked = 0
           AND NOT EXISTS (
             SELECT 1 FROM swipes s WHERE s.from_user_id = ? AND s.to_user_id = p.user_id
           )
           AND NOT EXISTS (
             SELECT 1 FROM blocks b
             WHERE (b.blocker_id = ? AND b.blocked_id = p.user_id)
                OR (b.blocker_id = p.user_id AND b.blocked_id = ?)
           )
         ORDER BY p.created_at DESC
         LIMIT 30'
    );
    $statement->execute([$userId, $userId, $userId, $userId]);
    json_out(['people' => array_map(fn ($row) => person_payload($row, false), $statement->fetchAll())]);
}

function list_search(): void
{
    $user = current_user();
    $userId = (int) $user['id'];
    $filters = validated_search_filters(request_data());
    $sql = 'SELECT p.* FROM profiles p
            JOIN users u ON u.id = p.user_id
            WHERE p.user_id <> ? AND p.hidden = 0 AND u.blocked = 0
              AND p.age BETWEEN ? AND ?
              AND NOT EXISTS (
                SELECT 1 FROM blocks b
                WHERE (b.blocker_id = ? AND b.blocked_id = p.user_id)
                   OR (b.blocker_id = p.user_id AND b.blocked_id = ?)
              )';
    $params = [$userId, $filters['minAge'], $filters['maxAge'], $userId, $userId];
    if ($filters['gender'] !== '') {
        $sql .= ' AND p.gender = ?';
        $params[] = $filters['gender'];
    }
    if ($filters['query'] !== '') {
        $sql .= ' AND (LOWER(p.username) LIKE ? ESCAPE \'\\\\\' OR LOWER(p.city) LIKE ? ESCAPE \'\\\\\')';
        $like = like_contains($filters['query']);
        $params[] = $like;
        $params[] = $like;
    }
    foreach (['interests' => 'p.interests', 'preferences' => 'p.preferences'] as $key => $column) {
        if ($filters[$key] === []) {
            continue;
        }
        $parts = [];
        foreach ($filters[$key] as $value) {
            $parts[] = 'JSON_CONTAINS(' . $column . ', JSON_QUOTE(?))';
            $params[] = $value;
        }
        $sql .= ' AND (' . implode(' OR ', $parts) . ')';
    }
    $sql .= ' ORDER BY p.created_at DESC LIMIT 50';
    $statement = db()->prepare($sql);
    $statement->execute($params);
    json_out(['people' => array_map(fn ($row) => person_payload($row, false), $statement->fetchAll())]);
}

function swipe(bool $liked): void
{
    $user = current_user();
    $userId = (int) $user['id'];
    $peerId = (int) (request_data()['userId'] ?? 0);
    require_visible_peer($userId, $peerId);
    $low = min($userId, $peerId);
    $high = max($userId, $peerId);
    $pdo = db();
    $lockName = 'fym-pair-' . $low . '-' . $high;
    $matched = false;
    $lock = $pdo->prepare('SELECT GET_LOCK(?, 3)');
    $lock->execute([$lockName]);
    if ((int) $lock->fetchColumn() !== 1) {
        fail(429, 'resource-exhausted', 'Please wait a moment and try again.');
    }
    try {
        $pdo->beginTransaction();
        try {
            if (!$liked) {
                $existing = $pdo->prepare(
                    'SELECT id FROM matches WHERE user_low = ? AND user_high = ? LIMIT 1'
                );
                $existing->execute([$low, $high]);
                if ($existing->fetchColumn()) {
                    throw new RuntimeException('Unmatch to end this match.');
                }
            }
            $statement = $pdo->prepare(
                'INSERT INTO swipes (from_user_id, to_user_id, liked, created_at)
                 VALUES (?, ?, ?, ?)
                 ON DUPLICATE KEY UPDATE liked = VALUES(liked)'
            );
            $statement->execute([$userId, $peerId, $liked ? 1 : 0, now()]);
            if ($liked) {
                $back = $pdo->prepare(
                    'SELECT 1 FROM swipes WHERE from_user_id = ? AND to_user_id = ? AND liked = 1 LIMIT 1'
                );
                $back->execute([$peerId, $userId]);
                if ($back->fetchColumn()) {
                    $match = $pdo->prepare(
                        'INSERT IGNORE INTO matches (user_low, user_high, created_at) VALUES (?, ?, ?)'
                    );
                    $match->execute([$low, $high, now()]);
                    $found = $pdo->prepare(
                        'SELECT id FROM matches WHERE user_low = ? AND user_high = ? LIMIT 1'
                    );
                    $found->execute([$low, $high]);
                    $matchId = (int) $found->fetchColumn();
                    if ($matchId > 0) {
                        $conversation = $pdo->prepare(
                            'INSERT IGNORE INTO conversations (match_id, user_low, user_high, created_at)
                             VALUES (?, ?, ?, ?)'
                        );
                        $conversation->execute([$matchId, $low, $high, now()]);
                        $matched = true;
                    }
                }
            }
            $pdo->commit();
        } catch (Throwable $error) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            throw $error;
        }
    } finally {
        $release = $pdo->prepare('SELECT RELEASE_LOCK(?)');
        $release->execute([$lockName]);
    }
    json_out(['matched' => $matched]);
}

function list_matches(): void
{
    $user = current_user();
    json_out(['people' => matched_rows((int) $user['id'])]);
}

function list_chats(): void
{
    $userId = (int) current_user()['id'];
    $statement = db()->prepare(
        'SELECT c.id AS conversation_id, p.*,
            (SELECT body FROM messages m WHERE m.conversation_id = c.id ORDER BY m.id DESC LIMIT 1) AS last_body
         FROM conversations c
         JOIN profiles p ON p.user_id = IF(c.user_low = ?, c.user_high, c.user_low)
         JOIN users u ON u.id = p.user_id
         WHERE (c.user_low = ? OR c.user_high = ?)
           AND u.blocked = 0
           AND NOT EXISTS (
             SELECT 1 FROM blocks b
             WHERE (b.blocker_id = ? AND b.blocked_id = p.user_id)
                OR (b.blocker_id = p.user_id AND b.blocked_id = ?)
           )
         ORDER BY (
           SELECT MAX(m.id) FROM messages m WHERE m.conversation_id = c.id
         ) DESC, c.id DESC'
    );
    $statement->execute([$userId, $userId, $userId, $userId, $userId]);
    $chats = [];
    foreach ($statement->fetchAll() as $row) {
        $person = person_payload($row, false);
        $person['lastMessage'] = (string) ($row['last_body'] ?? '');
        $chats[] = $person;
    }
    json_out(['chats' => $chats]);
}

function conversation_with(int $me, int $peerId): ?array
{
    $low = min($me, $peerId);
    $high = max($me, $peerId);
    $statement = db()->prepare(
        'SELECT * FROM conversations WHERE user_low = ? AND user_high = ? LIMIT 1'
    );
    $statement->execute([$low, $high]);
    $row = $statement->fetch();
    return $row ?: null;
}

function list_messages(): void
{
    $userId = (int) current_user()['id'];
    $peerId = (int) ($_GET['userId'] ?? request_data()['userId'] ?? 0);
    require_visible_peer($userId, $peerId, true);
    $conversation = conversation_with($userId, $peerId);
    if (!$conversation) {
        fail(404, 'not-found', 'Chat opens after a match.');
    }
    $conversationId = (int) $conversation['id'];
    $before = (int) ($_GET['before'] ?? 0);
    $sql = 'SELECT id, sender_id, body, created_at FROM messages WHERE conversation_id = ?';
    $params = [$conversationId];
    if ($before > 0) {
        $owns = db()->prepare(
            'SELECT 1 FROM messages WHERE id = ? AND conversation_id = ? LIMIT 1'
        );
        $owns->execute([$before, $conversationId]);
        if (!$owns->fetchColumn()) {
            fail(404, 'not-found', 'That message is not in this chat.');
        }
        $sql .= ' AND id < ?';
        $params[] = $before;
    }
    $sql .= ' ORDER BY id DESC LIMIT 50';
    $statement = db()->prepare($sql);
    $statement->execute($params);
    $messages = [];
    foreach (array_reverse($statement->fetchAll()) as $row) {
        $messages[] = message_payload($row, $userId);
    }
    json_out(['messages' => $messages]);
}

function send_message(): void
{
    $userId = (int) current_user()['id'];
    $input = request_data();
    $peerId = (int) ($input['userId'] ?? 0);
    $text = message_text((string) ($input['text'] ?? ''));
    require_visible_peer($userId, $peerId, true);
    $conversation = conversation_with($userId, $peerId);
    if (!$conversation) {
        fail(404, 'not-found', 'Chat opens after a match.');
    }
    $lockName = 'fym-msg-' . $userId;
    $lock = db()->prepare('SELECT GET_LOCK(?, 3)');
    $lock->execute([$lockName]);
    if ((int) $lock->fetchColumn() !== 1) {
        fail(429, 'resource-exhausted', 'Please wait a moment and try again.');
    }
    try {
        [$start, $end] = server_day_bounds();
        $count = db()->prepare(
            'SELECT COUNT(*) FROM messages WHERE sender_id = ? AND created_at >= ? AND created_at < ?'
        );
        $count->execute([$userId, $start, $end]);
        if ((int) $count->fetchColumn() >= 100) {
            fail(429, 'resource-exhausted', 'You can send 100 messages a day. Try again tomorrow.');
        }
        $stamp = now();
        $insert = db()->prepare(
            'INSERT INTO messages (conversation_id, sender_id, body, created_at) VALUES (?, ?, ?, ?)'
        );
        $insert->execute([(int) $conversation['id'], $userId, $text, $stamp]);
        $messageId = (string) db()->lastInsertId();
    } finally {
        $release = db()->prepare('SELECT RELEASE_LOCK(?)');
        $release->execute([$lockName]);
    }
    touch_active($userId);
    json_out([
        'message' => [
            'id' => $messageId,
            'fromMe' => true,
            'text' => $text,
            'timeLabel' => (new DateTimeImmutable($stamp))->format('g:i a'),
        ],
    ]);
}

function list_notices(): void
{
    $userId = (int) current_user()['id'];
    $statement = db()->prepare(
        'SELECT n.id, n.title, n.body, n.link_url, n.created_at,
                (r.user_id IS NOT NULL) AS seen
         FROM notices n
         LEFT JOIN notice_reads r ON r.notice_id = n.id AND r.user_id = ?
         WHERE n.user_id IS NULL OR n.user_id = ?
         ORDER BY n.id DESC
         LIMIT 50'
    );
    $statement->execute([$userId, $userId]);
    $notices = [];
    foreach ($statement->fetchAll() as $row) {
        $notices[] = [
            'id' => (string) $row['id'],
            'title' => $row['title'],
            'body' => $row['body'],
            'linkUrl' => $row['link_url'],
            'timeLabel' => (new DateTimeImmutable((string) $row['created_at']))->format('M j, g:i a'),
            'read' => (int) $row['seen'] === 1,
        ];
    }
    json_out(['notices' => $notices]);
}

function read_notice(): void
{
    $userId = (int) current_user()['id'];
    $noticeId = (int) (request_data()['id'] ?? 0);
    $owns = db()->prepare(
        'SELECT id FROM notices WHERE id = ? AND (user_id IS NULL OR user_id = ?) LIMIT 1'
    );
    $owns->execute([$noticeId, $userId]);
    if (!$owns->fetch()) {
        fail(404, 'not-found', 'That notice is not available.');
    }
    $insert = db()->prepare(
        'INSERT IGNORE INTO notice_reads (notice_id, user_id, read_at) VALUES (?, ?, ?)'
    );
    $insert->execute([$noticeId, $userId, now()]);
    json_out(['ok' => true]);
}

function unmatch_user(): void
{
    $userId = (int) current_user()['id'];
    $peerId = (int) (request_data()['userId'] ?? 0);
    if ($peerId <= 0 || $peerId === $userId) {
        fail(400, 'invalid-argument', 'That match cannot be removed.');
    }
    $low = min($userId, $peerId);
    $high = max($userId, $peerId);
    $match = db()->prepare('SELECT id FROM matches WHERE user_low = ? AND user_high = ? LIMIT 1');
    $match->execute([$low, $high]);
    $matchId = (int) $match->fetchColumn();
    if ($matchId <= 0) {
        fail(404, 'not-found', 'That match is already gone.');
    }
    // Blocks stay in place. Deleting the match cascades the conversation and its messages.
    $pdo = db();
    $pdo->beginTransaction();
    try {
        $delete = $pdo->prepare('DELETE FROM matches WHERE id = ?');
        $delete->execute([$matchId]);
        $swipes = $pdo->prepare(
            'DELETE FROM swipes
             WHERE (from_user_id = ? AND to_user_id = ?)
                OR (from_user_id = ? AND to_user_id = ?)'
        );
        $swipes->execute([$userId, $peerId, $peerId, $userId]);
        $pdo->commit();
    } catch (Throwable $error) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $error;
    }
    json_out(['ok' => true]);
}

function block_user(): void
{
    $userId = (int) current_user()['id'];
    $peerId = (int) (request_data()['userId'] ?? 0);
    if ($peerId <= 0 || $peerId === $userId) {
        fail(400, 'invalid-argument', 'That person cannot be blocked.');
    }
    $statement = db()->prepare(
        'INSERT IGNORE INTO blocks (blocker_id, blocked_id, created_at) VALUES (?, ?, ?)'
    );
    $statement->execute([$userId, $peerId, now()]);
    json_out(['ok' => true]);
}

function unblock_user(): void
{
    $userId = (int) current_user()['id'];
    $peerId = (int) (request_data()['userId'] ?? 0);
    $statement = db()->prepare('DELETE FROM blocks WHERE blocker_id = ? AND blocked_id = ?');
    $statement->execute([$userId, $peerId]);
    json_out(['ok' => true]);
}

function list_blocked(): void
{
    $userId = (int) current_user()['id'];
    $statement = db()->prepare(
        'SELECT p.* FROM blocks b
         JOIN profiles p ON p.user_id = b.blocked_id
         WHERE b.blocker_id = ?
         ORDER BY b.id DESC'
    );
    $statement->execute([$userId]);
    json_out(['people' => array_map(fn ($row) => person_payload($row, false), $statement->fetchAll())]);
}

function report_user(): void
{
    $userId = (int) current_user()['id'];
    $key = 'user:' . $userId;
    if (rate_limit_blocked('report', $key, 10, 3600)) {
        fail(429, 'resource-exhausted', 'Too many reports. Try again later.');
    }
    $input = request_data();
    $peerId = (int) ($input['userId'] ?? 0);
    $reason = (string) ($input['reason'] ?? '');
    if (!in_array($reason, REPORT_REASONS, true)) {
        fail(400, 'invalid-argument', 'Choose a report reason.');
    }
    if ($peerId <= 0 || $peerId === $userId) {
        fail(400, 'invalid-argument', 'That profile cannot be reported.');
    }
    $details = trim((string) ($input['details'] ?? ''));
    if ((function_exists('mb_strlen') ? mb_strlen($details) : strlen($details)) > 500) {
        fail(400, 'invalid-argument', 'Keep the note to 500 characters.');
    }
    rate_limit_record('report', $key);
    $statement = db()->prepare(
        'INSERT INTO reports (reporter_id, reported_id, reason, details, created_at) VALUES (?, ?, ?, ?, ?)'
    );
    $statement->execute([$userId, $peerId, $reason, $details, now()]);
    json_out(['ok' => true]);
}

function list_network_ads(): void
{
    current_user();
    json_out(network_ad_public(network_ad_row()));
}

function list_ads(): void
{
    current_user();
    $placement = (string) ($_GET['placement'] ?? '');
    if (!in_array($placement, AD_PLACEMENTS, true)) {
        fail(400, 'invalid-argument', 'That ad placement is not available.');
    }
    $statement = db()->prepare(
        'SELECT id, title, image_path, link_url, placement FROM ads
         WHERE active = 1 AND placement = ? ORDER BY id DESC LIMIT 1'
    );
    $statement->execute([$placement]);
    $row = $statement->fetch();
    json_out([
        'ad' => $row ? [
            'id' => (string) $row['id'],
            'title' => $row['title'],
            'imageUrl' => media_url($row['image_path']),
            'linkUrl' => $row['link_url'],
            'placement' => $row['placement'],
        ] : null,
    ]);
}

function matched_rows(int $userId): array
{
    $statement = db()->prepare(
        'SELECT p.* FROM matches m
         JOIN profiles p ON p.user_id = IF(m.user_low = ?, m.user_high, m.user_low)
         JOIN users u ON u.id = p.user_id
         WHERE (m.user_low = ? OR m.user_high = ?)
           AND u.blocked = 0
           AND NOT EXISTS (
             SELECT 1 FROM blocks b
             WHERE (b.blocker_id = ? AND b.blocked_id = p.user_id)
                OR (b.blocker_id = p.user_id AND b.blocked_id = ?)
           )
         ORDER BY m.id DESC'
    );
    $statement->execute([$userId, $userId, $userId, $userId, $userId]);
    return array_map(fn ($row) => person_payload($row, false), $statement->fetchAll());
}

function message_payload(array $row, int $userId): array
{
    return [
        'id' => (string) $row['id'],
        'fromMe' => (int) $row['sender_id'] === $userId,
        'text' => $row['body'],
        'timeLabel' => (new DateTimeImmutable((string) $row['created_at']))->format('g:i a'),
    ];
}

function normalize_email(mixed $value): string
{
    $email = strtolower(trim((string) $value));
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        fail(400, 'invalid-argument', 'Enter a valid email address.');
    }
    return $email;
}
