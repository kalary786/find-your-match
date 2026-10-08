<?php

declare(strict_types=1);

require __DIR__ . '/legal_layout.php';

render_public_page('Terms', <<<'HTML'
<p>Find Your Match is an 18+ dating and social matching app. The profile, likes, matches, and chats are stored on this website.</p>
<h2>Age</h2>
<p>You must be 18 or older. A date of birth under 18 is rejected. Do not use the app if you are under 18, and do not talk to anyone you know is under 18.</p>
<h2>Your account</h2>
<p>You register with an email and a password. You can change the password in Settings. The same login works on another phone. You are responsible for keeping the password private.</p>
<h2>Your profile</h2>
<p>You choose the username, photo, city, bio, interests, and what you are looking for. The app does not verify identity, photos, or age beyond the date of birth you type.</p>
<h2>Matching and chat</h2>
<p>A like stays private until the other person likes you back. Text chat opens only after a mutual match. Unmatching removes that match and its chat for both people. There is no promise that you will receive likes, matches, or replies.</p>
<h2>Safety</h2>
<p>You can unmatch, block, or report another person. An admin can block an account, delete a chat, or delete an account. An admin block signs that person out and hides them.</p>
<h2>Ending use</h2>
<p>You can hide your profile, sign out, or delete the account. Deletion removes the profile, photo, likes, matches, and chats. The email can be used later to register a new account.</p>
HTML);
