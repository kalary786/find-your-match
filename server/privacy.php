<?php

declare(strict_types=1);

require __DIR__ . '/legal_layout.php';

render_public_page('Privacy', <<<'HTML'
<p>This page says what Find Your Match stores on this website, and who can see it.</p>
<h2>Account</h2>
<p>Email and a password hash. The app keeps a sign-in token on that phone. The admin password is never stored in the app.</p>
<h2>Profile</h2>
<p>Username, date of birth, age, gender, city, bio, interests, preferences, and photo. Age is calculated on the server from the date of birth.</p>
<h2>Activity</h2>
<p>Likes and passes, matches, chat messages, blocks, and reports. If you turn them on, online status and last active time are saved too. Both are off until you turn them on.</p>
<h2>Who can see it</h2>
<p>Other people can see a profile that is not hidden, except people you blocked and people who blocked you. Chat is only between a matched pair. An admin can open users, chats, reports, and ads from the admin panel.</p>
<h2>Ads</h2>
<p>Ads are images uploaded in the admin panel for Discover, Search, and Matches. This build does not use an advertising network, and it does not send your profile to one.</p>
<h2>Deletion</h2>
<p>Delete the account in the app under Settings, or on the <a href="delete-account.php">delete account</a> page with the same email and password. That removes the profile, photo, likes, matches, and chats from this website.</p>
HTML);
