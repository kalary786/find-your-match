import 'package:find_your_match/core/api/api_config.dart';

enum LegalDocument {
  terms,
  privacy,
  guidelines,
  childSafety;

  static LegalDocument? fromSlug(String? slug) {
    return switch (slug) {
      'terms' => LegalDocument.terms,
      'privacy' => LegalDocument.privacy,
      'guidelines' => LegalDocument.guidelines,
      'child-safety' => LegalDocument.childSafety,
      _ => null,
    };
  }
}

class LegalSection {
  const LegalSection(this.heading, this.body);

  final String heading;
  final String body;
}

extension LegalDocumentText on LegalDocument {
  String get title {
    return switch (this) {
      LegalDocument.terms => 'Terms',
      LegalDocument.privacy => 'Privacy',
      LegalDocument.guidelines => 'Community guidelines',
      LegalDocument.childSafety => 'Child safety standards',
    };
  }

  String get publicPath {
    return switch (this) {
      LegalDocument.terms => '/terms.php',
      LegalDocument.privacy => '/privacy.php',
      LegalDocument.guidelines => '/guidelines.php',
      LegalDocument.childSafety => '/child-safety.php',
    };
  }

  String? get publicUrl {
    final root = ApiConfig.baseUrl.trim();
    if (root.isEmpty) return null;
    final base = root.endsWith('/') ? root.substring(0, root.length - 1) : root;
    return '$base$publicPath';
  }

  List<LegalSection> get sections {
    return switch (this) {
      LegalDocument.terms => const [
        LegalSection(
          'Age',
          'Find Your Match is for people 18 or older. A date of birth under 18 is rejected. Do not use the app if you are under 18, and do not talk to anyone you know is under 18.',
        ),
        LegalSection(
          'Your account',
          'You register with an email and a password. You can change the password in Settings. The same login works on another phone. You are responsible for keeping the password private.',
        ),
        LegalSection(
          'Your profile',
          'You choose the username, photo, city, bio, interests, and what you are looking for. The app does not verify identity, photos, or age beyond the date of birth you type.',
        ),
        LegalSection(
          'Matching and chat',
          'A like stays private until the other person likes you back. Text chat opens only after a mutual match. Unmatching removes that match and its chat for both people. There is no promise that you will receive likes, matches, or replies.',
        ),
        LegalSection(
          'Safety',
          'You can unmatch, block, or report another person. An admin can block an account, delete a chat, or delete an account. An admin block signs that person out and hides them. Child sexual abuse and exploitation (CSAE) is prohibited. The child safety standards say what is banned, how to report it, and what happens after a report.',
        ),
        LegalSection(
          'Ending use',
          'You can hide your profile, sign out, or delete the account. Deletion removes the profile, photo, likes, matches, and chats. The email can be used later to register a new account.',
        ),
      ],
      LegalDocument.privacy => const [
        LegalSection(
          'Account',
          'The website stores your email and a password hash. The app keeps a sign-in token on that phone. The admin password is never stored in the app.',
        ),
        LegalSection(
          'Profile',
          'Username, date of birth, age, gender, city, bio, interests, preferences, and photo. Age is calculated on the server from the date of birth.',
        ),
        LegalSection(
          'Activity',
          'Likes and passes, matches, chat messages, blocks, and reports. Unmatching removes that match and its chat. Online status and last active time are saved only if you turn them on. Both are off until you do.',
        ),
        LegalSection(
          'Who can see it',
          'Other people can see a profile that is not hidden, except people you blocked and people who blocked you. Chat is only between a matched pair. An admin can open users, chats, reports, and ads.',
        ),
        LegalSection(
          'Ads',
          'Ads are images uploaded in the admin panel for Discover, Search, and Matches. This build does not use an advertising network, and it does not send your profile to one.',
        ),
        LegalSection(
          'Deletion',
          'Delete the account in Settings, or on the public delete-account page with the same email and password. That removes the profile, photo, likes, matches, and chats.',
        ),
      ],
      LegalDocument.guidelines => const [
        LegalSection(
          'Adults only',
          'Be 18 or older. Do not say you are under 18, and do not ask for or share sexual content involving anyone under 18. The child safety standards prohibit child sexual abuse and exploitation (CSAE).',
        ),
        LegalSection(
          'How to treat people',
          'Do not harass, threaten, or post hate. Do not spam, scam, or pretend to be someone else. Post photos you have a right to share.',
        ),
        LegalSection(
          'Reports',
          'Use block and report when someone breaks these rules. Reports go to the admin panel. An admin may remove a chat, block the account, or delete it.',
        ),
      ],
      LegalDocument.childSafety => const [
        LegalSection(
          'Published standards',
          'Find Your Match prohibits child sexual abuse and exploitation (CSAE). These standards apply to the Find Your Match app and the website that stores accounts, profiles, and chats.',
        ),
        LegalSection(
          'What is prohibited',
          'Do not create, upload, request, or share child sexual abuse material (CSAM), sexual content involving anyone under 18, grooming, or a profile that presents someone as under 18.',
        ),
        LegalSection(
          'Adults only',
          'Find Your Match is an 18+ app and is not directed at children. A date of birth under 18 is rejected. Age comes from the date of birth you type. The app does not check an identity document. An account we learn is under 18 is deleted.',
        ),
        LegalSection(
          'How to report',
          'Open the person’s profile, or the menu in a chat, and tap Report. Choose Child safety, Inappropriate photo, or Other. You can also block that person. Do not copy or forward the content.',
        ),
        LegalSection(
          'What we do after we know',
          'When we obtain actual knowledge of CSAM or other CSAE, we remove the content, block or delete the account, and can delete the chat. Confirmed CSAM is reported to the National Center for Missing and Exploited Children (NCMEC) or the relevant regional authority.',
        ),
        LegalSection(
          'Child safety contact',
          'Google Play can write to the child safety point of contact named for Find Your Match in Play Console. People using the app should use Report. Do not send images of a child to that contact.',
        ),
      ],
    };
  }
}
