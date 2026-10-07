import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/routing/session_redirect.dart';
import 'package:find_your_match/core/session/session_controller.dart';
import 'package:find_your_match/core/widgets/error_state.dart';
import 'package:find_your_match/features/chat/chat_room_page.dart';
import 'package:find_your_match/features/chat/chats_page.dart';
import 'package:find_your_match/features/discover/discover_page.dart';
import 'package:find_your_match/features/legal/legal_copy.dart';
import 'package:find_your_match/features/legal/legal_page.dart';
import 'package:find_your_match/features/discover/user_details_page.dart';
import 'package:find_your_match/features/matches/matches_page.dart';
import 'package:find_your_match/features/onboarding/account_notice_page.dart';
import 'package:find_your_match/features/onboarding/create_profile_page.dart';
import 'package:find_your_match/features/onboarding/how_it_works_page.dart';
import 'package:find_your_match/features/onboarding/welcome_page.dart';
import 'package:find_your_match/features/profile/edit_profile_page.dart';
import 'package:find_your_match/features/profile/profile_page.dart';
import 'package:find_your_match/features/safety/blocked_users_page.dart';
import 'package:find_your_match/features/safety/delete_account_page.dart';
import 'package:find_your_match/features/safety/report_user_page.dart';
import 'package:find_your_match/features/search/search_filters_page.dart';
import 'package:find_your_match/features/search/search_page.dart';
import 'package:find_your_match/features/settings/settings_page.dart';
import 'package:find_your_match/features/setup/session_error_page.dart';
import 'package:find_your_match/features/setup/setup_page.dart';
import 'package:find_your_match/features/setup/splash_page.dart';
import 'package:find_your_match/features/shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  ref.listen(sessionControllerProvider, (previous, next) => refresh.ping());

  final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: AppRoutes.splash,
    overridePlatformDefaultLocation: true,
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      return redirectForSession(session, state.matchedLocation);
    },
    errorBuilder: (context, state) {
      return Scaffold(
        body: ErrorState(
          title: 'Page not available',
          message: 'That screen is not part of this build.',
          onRetry: () => context.go(AppRoutes.discover),
        ),
      );
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.setup,
        builder: (context, state) => const SetupPage(),
      ),
      GoRoute(
        path: AppRoutes.error,
        builder: (context, state) => const SessionErrorPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const WelcomePage(),
        routes: [
          GoRoute(
            path: 'how-it-works',
            builder: (context, state) => const HowItWorksPage(),
          ),
          GoRoute(
            path: 'account',
            builder: (context, state) => const AccountNoticePage(),
          ),
          GoRoute(
            path: 'create-profile',
            builder: (context, state) => const CreateProfilePage(),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.discover,
                builder: (context, state) => const DiscoverPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                builder: (context, state) => const SearchPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.matches,
                builder: (context, state) => const MatchesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.chats,
                builder: (context, state) => const ChatsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/people/:id',
        parentNavigatorKey: rootKey,
        builder: (context, state) {
          return UserDetailsPage(userId: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/conversation/:id',
        parentNavigatorKey: rootKey,
        builder: (context, state) {
          return ChatRoomPage(userId: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/report/:id',
        parentNavigatorKey: rootKey,
        builder: (context, state) {
          return ReportUserPage(userId: state.pathParameters['id']!);
        },
      ),
      GoRoute(
        path: '/legal/:doc',
        parentNavigatorKey: rootKey,
        builder: (context, state) {
          return LegalPage(
            document: LegalDocument.fromSlug(state.pathParameters['doc']),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.filters,
        parentNavigatorKey: rootKey,
        builder: (context, state) => const SearchFiltersPage(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        parentNavigatorKey: rootKey,
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        parentNavigatorKey: rootKey,
        builder: (context, state) => const SettingsPage(),
        routes: [
          GoRoute(
            path: 'blocked',
            builder: (context, state) => const BlockedUsersPage(),
          ),
          GoRoute(
            path: 'delete-account',
            builder: (context, state) => const DeleteAccountPage(),
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

class _RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}
