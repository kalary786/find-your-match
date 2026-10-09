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
        $action = (string) ($_POST['action'] ?? 'create');
        $adId = (int) ($_POST['ad_id'] ?? 0);
        if ($action === 'delete') {
            $path = db()->prepare('SELECT image_path FROM ads WHERE id = ?');
            $path->execute([$adId]);
            unlink_public((string) ($path->fetchColumn() ?: ''));
            $delete = db()->prepare('DELETE FROM ads WHERE id = ?');
            $delete->execute([$adId]);
            log_moderation((int) $admin['id'], 'ad-delete', null, 'ad ' . $adId);
            $notice = 'Ad removed.';
        } elseif ($action === 'toggle') {
            $toggle = db()->prepare('UPDATE ads SET active = IF(active = 1, 0, 1) WHERE id = ?');
            $toggle->execute([$adId]);
            log_moderation((int) $admin['id'], 'ad-toggle', null, 'ad ' . $adId);
            $notice = 'Ad updated.';
        } else {
            $title = trim((string) ($_POST['title'] ?? ''));
            $link = trim((string) ($_POST['link_url'] ?? ''));
            $placement = (string) ($_POST['placement'] ?? '');
            if ($title === '' || strlen($title) > 80) {
                $error = 'Enter a title up to 80 characters.';
            } elseif (!in_array($placement, AD_PLACEMENTS, true)) {
                $error = 'Choose Discover, Search, or Matches.';
            } elseif (empty($_FILES['image']['tmp_name'])) {
                $error = 'Upload an ad image.';
            } else {
                try {
                    $link = optional_link($link);
                    if ($link === '') {
                        throw new RuntimeException('Enter a full http or https link.');
                    }
                    $image = store_image($_FILES['image'], 'ads');
                    $insert = db()->prepare(
                        'INSERT INTO ads (title, image_path, link_url, placement, active, created_at)
                         VALUES (?, ?, ?, ?, 1, ?)'
                    );
                    $insert->execute([$title, $image, $link, $placement, now()]);
                    log_moderation((int) $admin['id'], 'ad-create', null, 'ad ' . (int) db()->lastInsertId());
                    $notice = 'Ad is on.';
                } catch (RuntimeException $exception) {
                    $error = $exception->getMessage();
                }
            }
        }
    }
}

$rows = db()->query('SELECT * FROM ads ORDER BY id DESC LIMIT 100')->fetchAll();
$body = '<h1>Ads</h1><p>Ads can appear on Discover, Search, and Matches. Chat, reports, and account deletion stay clear.</p>';
if ($notice) {
    $body .= '<p class="ok">' . h($notice) . '</p>';
}
if ($error) {
    $body .= '<p class="error">' . h($error) . '</p>';
}
$body .= '<form method="post" enctype="multipart/form-data" class="narrow">' . csrf_field() . '
  <input type="hidden" name="action" value="create">
  <label>Title <input name="title" maxlength="80" required></label>
  <label>Link <input name="link_url" type="url" placeholder="https://" required></label>
  <label>Placement <select name="placement">
    <option value="discover">Discover</option>
    <option value="search">Search</option>
    <option value="matches">Matches</option>
  </select></label>
  <label>Image <input type="file" name="image" accept="image/jpeg,image/png,image/webp" required></label>
  <button type="submit">Add ad</button>
</form>';
$body .= '<table><thead><tr><th>Ad</th><th>Placement</th><th>Status</th><th></th></tr></thead><tbody>';
foreach ($rows as $row) {
    $id = (int) $row['id'];
    $status = (int) $row['active'] === 1 ? 'On' : 'Off';
    $image = media_url((string) $row['image_path']);
    $body .= '<tr><td>';
    if ($image) {
        $body .= '<img class="thumb" src="' . h($image) . '" alt=""> ';
    }
    $body .= h((string) $row['title']) . '<br><a href="' . h((string) $row['link_url']) . '">'
        . h((string) $row['link_url']) . '</a></td><td>' . h((string) $row['placement'])
        . '</td><td>' . h($status) . '</td><td class="actions">
        <form method="post">' . csrf_field() . '<input type="hidden" name="action" value="toggle">
        <input type="hidden" name="ad_id" value="' . $id . '"><button type="submit">'
        . ((int) $row['active'] === 1 ? 'Turn off' : 'Turn on') . '</button></form>
        <form method="post" onsubmit="return confirm(\'Remove this ad?\')">' . csrf_field()
        . '<input type="hidden" name="action" value="delete"><input type="hidden" name="ad_id" value="' . $id . '">
        <button class="danger" type="submit">Delete</button></form></td></tr>';
}
$body .= '</tbody></table>';
layout('Ads', $body, $admin);
