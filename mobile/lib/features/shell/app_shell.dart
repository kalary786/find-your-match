import 'dart:async';

import 'package:find_your_match/core/theme/app_colors.dart';
import 'package:find_your_match/features/ads/interstitial_manager.dart';
import 'package:find_your_match/features/ads/network_ad_controller.dart';
import 'package:find_your_match/features/ads/network_banner.dart';
import 'package:find_your_match/features/notices/notices_page.dart';
import 'package:find_your_match/features/social/social_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _select(WidgetRef ref, int index) {
    final previous = navigationShell.currentIndex;
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
    // Leaving Search with results is a natural interstitial break.
    if (previous == 1 && index != 1) {
      final hasResults =
          ref.read(socialControllerProvider).searchResults.isNotEmpty;
      if (hasResults) {
        unawaited(ref.read(interstitialManagerProvider).maybeShow());
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannerAtTop = ref
        .watch(networkAdControllerProvider)
        .settings
        .bannerAtTop;
    // Chats tab (index 3) stays ad-free — no shell banner there.
    final onChats = navigationShell.currentIndex == 3;
    final Widget banner = onChats
        ? const SizedBox.shrink()
        : const NetworkBanner(inChat: false);
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final unreadNotices = ref.watch(noticeControllerProvider).unread;
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => _select(ref, index),
              labelType: NavigationRailLabelType.all,
              destinations: [
                const NavigationRailDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore),
                  label: Text('Discover'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.search),
                  selectedIcon: Icon(Icons.search),
                  label: Text('Search'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.favorite_outline),
                  selectedIcon: Icon(Icons.favorite),
                  label: Text('Matches'),
                ),
                NavigationRailDestination(
                  icon: _BadgedIcon(
                    icon: Icons.chat_bubble_outline,
                    showBadge: unreadNotices > 0,
                  ),
                  selectedIcon: _BadgedIcon(
                    icon: Icons.chat_bubble,
                    showBadge: unreadNotices > 0,
                  ),
                  label: const Text('Chats'),
                ),
                NavigationRailDestination(
                  icon: _BadgedIcon(
                    icon: Icons.person_outline,
                    showBadge: unreadNotices > 0,
                  ),
                  selectedIcon: _BadgedIcon(
                    icon: Icons.person,
                    showBadge: unreadNotices > 0,
                  ),
                  label: const Text('Profile'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _withBanner(banner, bannerAtTop, navigationShell)),
          ],
        ),
      );
    }

    return Scaffold(
      body: _withBanner(banner, bannerAtTop, navigationShell),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => _select(ref, index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          const NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Matches',
          ),
          NavigationDestination(
            icon: _BadgedIcon(
              icon: Icons.chat_bubble_outline,
              showBadge: unreadNotices > 0,
            ),
            selectedIcon: _BadgedIcon(
              icon: Icons.chat_bubble,
              showBadge: unreadNotices > 0,
            ),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: _BadgedIcon(
              icon: Icons.person_outline,
              showBadge: unreadNotices > 0,
            ),
            selectedIcon: _BadgedIcon(
              icon: Icons.person,
              showBadge: unreadNotices > 0,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _BadgedIcon extends StatelessWidget {
  const _BadgedIcon({required this.icon, required this.showBadge});

  final IconData icon;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: false,
      backgroundColor: AppColors.coral,
      smallSize: showBadge ? 8 : 0,
      child: Icon(icon),
    );
  }
}

Widget _withBanner(Widget banner, bool bannerAtTop, Widget child) {
  return Column(
    children: [
      if (bannerAtTop) banner,
      Expanded(child: child),
      if (!bannerAtTop) banner,
    ],
  );
}
