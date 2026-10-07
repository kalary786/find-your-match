import 'package:find_your_match/core/api/api_config.dart';

enum LegalDocument {
  terms,
  privacy,
  guidelines;

  static LegalDocument? fromSlug(String? slug) {
    return switch (slug) {
      'terms' => LegalDocument.terms,
      'privacy' => LegalDocument.privacy,
      'guidelines' => LegalDocument.guidelines,
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
    };
  }

  String get publicPath {
    return switch (this) {
      LegalDocument.terms => '/terms.php',
      LegalDocument.privacy => '/privacy.php',
      LegalDocument.guidelines => '/guidelines.php',
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
          'You register with an email and a password. The same login works on another phone. You are responsible for keeping the password private.',
        ),
        LegalSection(
          'Your profile',
          'You choose the username, photo, city, bio, interests, and what you are looking for. The app does not verify identity, photos, or age beyond the date of birth you type.',
        ),
        LegalSection(
          'Matching and chat',
          'A like stays private until the other person likes you back. Text chat opens only after a mutual match. There is no promise that you will receive likes, matches, or replies.',
        ),
        LegalSection(
          'Safety',
          'You can block or report another person. An admin can block an account, delete a chat, or delete an account. Blocking signs that person out and hides them.',
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
          'Likes and passes, matches, chat messages, blocks, and reports. Online status and last active time are saved only if you turn them on. Both are off until you do.',
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
          'Be 18 or older. Do not say you are under 18, and do not ask for or share sexual content involving anyone under 18.',
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
    };
  }
}
