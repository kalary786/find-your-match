<?php

declare(strict_types=1);

require __DIR__ . '/lib/bootstrap.php';
require __DIR__ . '/legal_layout.php';

$error = '';
$done = false;

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'POST') {
    $email = strtolower(trim((string) ($_POST['email'] ?? '')));
    $password = (string) ($_POST['password'] ?? '');
    $confirmed = isset($_POST['confirm']);
    $emailKey = 'email:' . $email;
    $ipKey = 'ip:' . client_ip();
    if (!$confirmed) {
        $error = 'Confirm that you want to permanently delete the account.';
    } elseif (!filter_var($email, FILTER_VALIDATE_EMAIL) || $password === '') {
        $error = 'Enter the email and password for the account.';
    } elseif (
        rate_limit_blocked('delete-web', $emailKey, 8, 900)
        || rate_limit_blocked('delete-web', $ipKey, 20, 900)
    ) {
        $error = 'Too many attempts. Try again later.';
    } else {
        try {
            $statement = db()->prepare(
                'SELECT id, password_hash FROM users WHERE email = ? LIMIT 1'
            );
            $statement->execute([$email]);
            $user = $statement->fetch();
            if (!$user || !password_verify($password, (string) $user['password_hash'])) {
                rate_limit_record('delete-web', $emailKey);
                rate_limit_record('delete-web', $ipKey);
                $error = 'Email or password is incorrect.';
            } else {
                rate_limit_clear('delete-web', $emailKey);
                delete_user_account((int) $user['id']);
                $done = true;
            }
        } catch (PDOException) {
            $error = 'The account could not be deleted. Try again in a moment.';
        }
    }
}

if ($done) {
    $body = '<p>The account is deleted. The profile, photo, likes, matches, and chats are gone from this website. The email can be used later to register a new account.</p>';
} else {
    $message = $error === '' ? '' : '<p class="error">' . htmlspecialchars($error, ENT_QUOTES, 'UTF-8') . '</p>';
    $body = <<<HTML
<p>This deletes the Find Your Match account stored on this website. You can do the same inside the app from Profile, Settings, Delete account.</p>
<p>Deletion removes the profile, photo, likes, matches, and chats. Hiding a profile is not deletion.</p>
{$message}
<form method="post">
  <label>Email <input name="email" type="email" autocomplete="username" required></label>
  <label>Password <input name="password" type="password" autocomplete="current-password" required></label>
  <label><input name="confirm" type="checkbox"> I understand this permanently deletes the account.</label>
  <button type="submit">Delete account</button>
</form>
HTML;
}

render_public_page('Delete account', $body);
