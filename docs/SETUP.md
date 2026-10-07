# Setup

This guide is what you need before the app can talk to your website. It is not a compliance sign-off. Re-check the linked Play policies in Play Console before you submit an app.

The Flutter UI can be opened before the site is uploaded. It stays on the setup screen until `ApiConfig.baseUrl` is set.

## Your hosting

The site in `server/` is PHP 8 and MySQL. Upload that folder to shared hosting or any host that runs PHP and MySQL. Do not commit `server/config.php`.

1. Create an empty MySQL database.
2. Copy `server/config.example.php` to `server/config.php`.
3. Fill in the database name, user, password, and `base_url`. `base_url` is the public address of the `server` folder with no trailing slash, for example `https://example.com/server`.
4. Open `https://example.com/server/install.php` once and create the admin email and password.
5. Delete `install.php` from the server after that account exists.
6. Sign in at `https://example.com/server/admin/`.
7. In `mobile/lib/core/api/api_config.dart`, set `baseUrl` to the same `base_url`, then rebuild the app.

The admin password stays on the website. The Android app only stores the signed-in user's token on that phone.

People register with email and password inside the app. The same login works on another phone. Age is calculated on the server from `YYYY-MM-DD`. Usernames are unique. Photos are stored under `server/uploads/`.

From the admin panel you can:

- Block a user, which signs them out and hides them
- Unblock a user
- Delete a user, including the profile, photo, likes, and chats
- Open or delete a chat
- Review reports, then block or delete the reported user
- Add an ad image and link for Discover, Search, or Matches, and turn it on or off

Chat, report, and account deletion do not show ads.

## AdMob

Not wired. Ads in the app are the images you upload in the admin panel.

## Play Console

Create the app with package name `com.findyourmatch.app` when you are ready to publish. Before production, complete the current Play Console forms yourself:

- Target audience 18 and over. Do not target children.
- Use Play’s control that blocks minors. Dating is the core of this app, so a typed date of birth is only an extra check.
- Content rating, including user-generated content.
- Child safety standards declaration for social and dating apps.
- Data safety, a public privacy policy URL, and an account-deletion URL.
- Store listing that does not claim identity verification or policy compliance you have not verified.

Policy pages to re-read at submission time:

- https://support.google.com/googleplay/android-developer/answer/17190352
- https://support.google.com/googleplay/android-developer/answer/9876937
- https://support.google.com/googleplay/android-developer/answer/10144311
- https://support.google.com/googleplay/android-developer/answer/13327111
- https://support.google.com/googleplay/android-developer/answer/16838200

Terms, Privacy, and Community Guidelines are in the app under Settings, and on the website:

- `https://bngames.shop/server/terms.php`
- `https://bngames.shop/server/privacy.php`
- `https://bngames.shop/server/guidelines.php`
- `https://bngames.shop/server/delete-account.php`

Upload the new files in `server/` before those addresses will open. Have the pages reviewed before you submit the app. They describe how this build works. They are not a compliance sign-off.
