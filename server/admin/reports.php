<?php

declare(strict_types=1);

require __DIR__ . '/_init.php';

$admin = require_admin();
$notice = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!csrf_ok()) {
        $notice = 'The form expired. Try again.';
    } else {
        $reportId = (int) ($_POST['report_id'] ?? 0);
        $userId = (int) ($_POST['user_id'] ?? 0);
        $action = (string) ($_POST['action'] ?? '');
        if ($action === 'resolve') {
            $statement = db()->prepare('UPDATE reports SET resolved = 1 WHERE id = ?');
            $statement->execute([$reportId]);
            $notice = 'Report marked reviewed.';
        } elseif ($action === 'block') {
            $statement = db()->prepare('UPDATE users SET blocked = 1, token_hash = NULL WHERE id = ?');
            $statement->execute([$userId]);
            $mark = db()->prepare('UPDATE reports SET resolved = 1 WHERE id = ?');
            $mark->execute([$reportId]);
            $notice = 'User blocked.';
        } elseif ($action === 'delete') {
            $profile = db()->prepare('SELECT photo_path FROM profiles WHERE user_id = ?');
            $profile->execute([$userId]);
            $path = $profile->fetchColumn();
            unlink_public(is_string($path) ? $path : null);
            $delete = db()->prepare('DELETE FROM users WHERE id = ?');
            $delete->execute([$userId]);
            $notice = 'User deleted.';
        }
    }
}

$rows = db()->query(
    'SELECT r.id, r.reason, r.details, r.created_at, r.resolved, r.reported_id,
        reporter.username AS reporter_name, reported.username AS reported_name, u.email AS reported_email
     FROM reports r
     LEFT JOIN profiles reporter ON reporter.user_id = r.reporter_id
     LEFT JOIN profiles reported ON reported.user_id = r.reported_id
     LEFT JOIN users u ON u.id = r.reported_id
     ORDER BY r.resolved ASC, r.id DESC
     LIMIT 200'
)->fetchAll();

$body = '<h1>Reports</h1>';
if ($notice) {
    $body .= '<p class="ok">' . h($notice) . '</p>';
}
$body .= '<table><thead><tr><th>When</th><th>Reported</th><th>By</th><th>Reason</th><th>Details</th><th></th></tr></thead><tbody>';
foreach ($rows as $row) {
    $id = (int) $row['id'];
    $userId = (int) $row['reported_id'];
    $state = (int) $row['resolved'] === 1 ? 'Reviewed' : 'Open';
    $body .= '<tr><td>' . h((string) $row['created_at']) . '<br>' . h($state) . '</td><td>'
        . h((string) ($row['reported_name'] ?? $row['reported_email'] ?? 'Removed'))
        . '</td><td>' . h((string) ($row['reporter_name'] ?? 'Removed'))
        . '</td><td>' . h((string) $row['reason']) . '</td><td>' . h((string) $row['details'])
        . '</td><td class="actions">';
    if ((int) $row['resolved'] === 0) {
        $body .= report_form($id, $userId, 'resolve', 'Reviewed');
        $body .= report_form($id, $userId, 'block', 'Block');
        $body .= report_form($id, $userId, 'delete', 'Delete user', true);
    }
    $body .= '</td></tr>';
}
$body .= '</tbody></table>';
layout('Reports', $body, $admin);

function report_form(int $reportId, int $userId, string $action, string $label, bool $danger = false): string
{
    $class = $danger ? ' class="danger"' : '';
    $confirm = $danger ? ' onsubmit="return confirm(\'Delete this user?\')"' : '';
    return '<form method="post"' . $confirm . '>' . csrf_field()
        . '<input type="hidden" name="report_id" value="' . $reportId . '">'
        . '<input type="hidden" name="user_id" value="' . $userId . '">'
        . '<input type="hidden" name="action" value="' . h($action) . '">'
        . '<button type="submit"' . $class . '>' . h($label) . '</button></form>';
}
