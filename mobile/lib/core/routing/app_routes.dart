abstract final class AppRoutes {
  static const splash = '/splash';
  static const setup = '/setup';
  static const error = '/error';
  static const onboarding = '/onboarding';
  static const howItWorks = '/onboarding/how-it-works';
  static const account = '/onboarding/account';
  static const createProfile = '/onboarding/create-profile';
  static const discover = '/discover';
  static const search = '/search';
  static const matches = '/matches';
  static const chats = '/chats';
  static const profile = '/profile';
  static const filters = '/filters';
  static const editProfile = '/edit-profile';
  static const settings = '/settings';
  static const blocked = '/settings/blocked';
  static const deleteAccount = '/settings/delete-account';

  static String person(String id) => '/people/$id';
  static String conversation(String id) => '/conversation/$id';
  static String report(String id) => '/report/$id';
}
