<?php

declare(strict_types=1);

require __DIR__ . '/_init.php';

$admin = require_admin();
$notice = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!csrf_ok()) {
        $notice = 'The form expired. Try again.';
    } else {
        $userId = (int) ($_POST['user_id'] ?? 0);
        $action = (string) ($_POST['action'] ?? '');
        if ($userId > 0 && $action === 'block') {
            $statement = db()->prepare(
                'UPDATE users SET blocked = 1, token_hash = NULL, token_expires_at = NULL WHERE id = ?'
            );
            $statement->execute([$userId]);
            log_moderation((int) $admin['id'], 'user-block', $userId);
            $notice = 'User blocked. They can no longer sign in.';
        } elseif ($userId > 0 && $action === 'unblock') {
            $statement = db()->prepare('UPDATE users SET blocked = 0 WHERE id = ?');
            $statement->execute([$userId]);
            log_moderation((int) $admin['id'], 'user-unblock', $userId);
            $notice = 'User unblocked.';
        } elseif ($userId > 0 && $action === 'delete') {
            log_moderation((int) $admin['id'], 'user-delete', $userId);
            delete_user_account($userId);
            $notice = 'User deleted, including profile, photos, likes, and chats.';
        }
    }
}

$rows = db()->query(
    'SELECT u.id, u.email, u.blocked, u.created_at, p.username, p.age, p.city, p.hidden
     FROM users u
     LEFT JOIN profiles p ON p.user_id = u.id
     ORDER BY u.id DESC
     LIMIT 200'
)->fetchAll();

$body = '<h1>Users</h1>';
if ($notice) {
    $body .= '<p class="ok">' . h($notice) . '</p>';
}
$body .= '<table><thead><tr><th>Email</th><th>Username</th><th>Age</th><th>City</th><th>Status</th><th></th></tr></thead><tbody>';
foreach ($rows as $row) {
    $status = (int) $row['blocked'] === 1 ? 'Blocked' : ((int) ($row['hidden'] ?? 0) === 1 ? 'Hidden' : 'Active');
    $id = (int) $row['id'];
    $body .= '<tr><td>' . h((string) $row['email']) . '</td><td>' . h((string) ($row['username'] ?? '—'))
        . '</td><td>' . h((string) ($row['age'] ?? '—')) . '</td><td>' . h((string) ($row['city'] ?? '—'))
        . '</td><td>' . h($status) . '</td><td class="actions">';
    if ((int) $row['blocked'] === 1) {
        $body .= action_form($id, 'unblock', 'Unblock');
    } else {
        $body .= action_form($id, 'block', 'Block');
    }
    $body .= action_form($id, 'delete', 'Delete', true);
    $body .= '</td></tr>';
}
$body .= '</tbody></table>';
layout('Users', $body, $admin);

function action_form(int $userId, string $action, string $label, bool $danger = false): string
{
    $confirm = $danger ? ' onsubmit="return confirm(\'Delete this user and their chats?\')"' : '';
    $class = $danger ? ' class="danger"' : '';
    return '<form method="post"' . $confirm . '>' . csrf_field()
        . '<input type="hidden" name="user_id" value="' . $userId . '">'
        . '<input type="hidden" name="action" value="' . h($action) . '">'
        . '<button type="submit"' . $class . '>' . h($label) . '</button></form>';
}
