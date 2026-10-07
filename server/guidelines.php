<?php

declare(strict_types=1);

require __DIR__ . '/legal_layout.php';

render_public_page('Community guidelines', <<<'HTML'
<p>Find Your Match is only for adults. These are the rules for profiles, photos, and chat.</p>
<ul>
<li>Be 18 or older. Do not say you are under 18, and do not ask for or share sexual content involving anyone under 18.</li>
<li>Do not harass, threaten, or post hate.</li>
<li>Do not spam, scam, or pretend to be someone else.</li>
<li>Post photos you have a right to share.</li>
<li>Use block and report when someone breaks these rules. Reports go to the admin panel.</li>
</ul>
<p>An admin may remove a chat, block the account, or delete it. A block hides that person and signs them out.</p>
HTML);
