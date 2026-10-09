<?php

declare(strict_types=1);

require __DIR__ . '/_init.php';

$admin = require_admin();
$notice = null;
$error = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!csrf_ok()) {
        $error = 'The form expired. Try again.';
    } else {
        $reportId = (int) ($_POST['report_id'] ?? 0);
        $action = (string) ($_POST['action'] ?? '');
        $reported = db()->prepare('SELECT reported_id FROM reports WHERE id = ? LIMIT 1');
        $reported->execute([$reportId]);
        $reportRow = $reported->fetch();
        $userId = $reportRow ? (int) $reportRow['reported_id'] : 0;
        if ($reportId <= 0 || !$reportRow) {
            $error = 'That report is not available.';
        } elseif ($action === 'resolve') {
            $statement = db()->prepare('UPDATE reports SET resolved = 1 WHERE id = ?');
            $statement->execute([$reportId]);
            log_moderation((int) $admin['id'], 'report-resolve', $userId > 0 ? $userId : null, 'report ' . $reportId);
            $notice = 'Report marked reviewed.';
        } elseif ($userId <= 0) {
            $error = 'That reported account is already gone.';
        } elseif ($action === 'block') {
            $statement = db()->prepare(
                'UPDATE users SET blocked = 1, token_hash = NULL, token_expires_at = NULL WHERE id = ?'
            );
            $statement->execute([$userId]);
            $mark = db()->prepare('UPDATE reports SET resolved = 1 WHERE id = ?');
            $mark->execute([$reportId]);
            log_moderation((int) $admin['id'], 'user-block', $userId, 'report ' . $reportId);
            $notice = 'User blocked.';
        } elseif ($action === 'delete') {
            try {
                delete_user_account($userId);
                log_moderation((int) $admin['id'], 'user-delete', $userId, 'report ' . $reportId);
                $notice = 'User deleted.';
            } catch (Throwable $exception) {
                $error = 'The user could not be deleted.';
            }
        } else {
            $error = 'That action is not available.';
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
$body .= status_html($notice, $error);
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
        $body .= report_form($id, 'resolve', 'Reviewed');
        $body .= report_form($id, 'block', 'Block', 'Block this user? They will be signed out.');
        $body .= report_form($id, 'delete', 'Delete user', 'Delete this user?');
    }
    $body .= '</td></tr>';
}
$body .= '</tbody></table>';
layout('Reports', $body, $admin);

function report_form(int $reportId, string $action, string $label, string $confirmMessage = ''): string
{
    $class = $action === 'delete' ? ' class="danger"' : '';
    $confirm = $confirmMessage === ''
        ? ''
        : ' onsubmit="return confirm(\'' . h($confirmMessage) . '\')"';
    return '<form method="post"' . $confirm . '>' . csrf_field()
        . '<input type="hidden" name="report_id" value="' . $reportId . '">'
        . '<input type="hidden" name="action" value="' . h($action) . '">'
        . '<button type="submit"' . $class . '>' . h($label) . '</button></form>';
}
