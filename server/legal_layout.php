<?php

declare(strict_types=1);

function render_public_page(string $title, string $bodyHtml): void
{
    $safeTitle = htmlspecialchars($title, ENT_QUOTES, 'UTF-8');
    echo '<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">';
    echo '<meta name="viewport" content="width=device-width, initial-scale=1">';
    echo '<title>' . $safeTitle . ' · Find Your Match</title>';
    echo '<link rel="stylesheet" href="legal.css">';
    echo '</head><body><header><strong>Find Your Match</strong><nav>';
    echo '<a href="terms.php">Terms</a>';
    echo '<a href="privacy.php">Privacy</a>';
    echo '<a href="guidelines.php">Guidelines</a>';
    echo '<a href="delete-account.php">Delete account</a>';
    echo '</nav></header><main><h1>' . $safeTitle . '</h1>';
    echo $bodyHtml;
    echo '<p class="note">These pages describe how this app stores accounts, profiles, and chats. They are not a sign-off that the app meets every store policy.</p>';
    echo '</main></body></html>';
}
