# Setup

This guide is what you need before the app can talk to live services. It is not a compliance sign-off. Re-check the linked Play policies in Play Console before you submit an app.

The Flutter UI can be run before any Firebase project exists. AdMob and the admin panel are later phases. Sample people in the app are layout data only.

## Firebase

1. Create a Firebase project and upgrade it to the Blaze plan before you deploy Cloud Functions, Cloud Storage, or scheduled jobs. Auth and Firestore can be tried on the Spark plan, but the planned backend needs Blaze.
2. Register an Android app with package name `com.findyourmatch.app`.
3. Download `google-services.json` and place it at `mobile/android/app/google-services.json`. Do not commit that file.
4. In the Firebase console, enable:
   - Authentication → Anonymous
   - Cloud Firestore
   - Storage (when photo upload is added)
   - Cloud Messaging
   - Analytics
5. Install the FlutterFire CLI and run it from `mobile/` so the Android app id matches this project. Then set `FirebaseAppConfig.isConfigured` to `true` in `mobile/lib/core/firebase/firebase_app_config.dart` and restart.
6. Deploy the rules in `firebase/` before any client write is allowed. Those rules currently deny every read and write on purpose. Do not open them to all signed-in users.
7. Keep the Firebase Admin SDK, service account JSON, and admin passwords off the phone and out of git.

Anonymous sign-in has no email and no password. The session stays on that install. A later phase will show a one-time recovery code and store only a hash of it. If the phone session and the code are both lost, the account cannot be restored.

The current UI runs without Firebase. Sample profiles, likes, and messages stay in memory and are labeled as sample data. They are not written to Firestore.

When `FirebaseAppConfig.isConfigured` is turned on, startup will use anonymous sign-in and read `users/{uid}/public/profile` again. That read is not used while the flag is false. Nothing in the UI writes a profile document yet.

## AdMob

Not wired in this phase.

When ads are added:

- Use Google’s test app id and test ad unit ids in development.
- Put production ids in environment configuration only after test ads are confirmed on a device.
- Ask for consent with Google’s User Messaging Platform before requesting ads.
- Keep ads off onboarding, chat, report, block, verification, legal pages, and account deletion.
- Do not commit a live ad unit as if it were a test id.

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

Legal pages inside the app are not written yet. Do not ship until Terms, Privacy, and Community Guidelines exist and you have had them reviewed for the places you distribute the app.
