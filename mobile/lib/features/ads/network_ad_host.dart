import 'package:find_your_match/core/routing/app_router.dart';
import 'package:find_your_match/core/session/session_controller.dart';
import 'package:find_your_match/core/session/session_state.dart';
import 'package:find_your_match/features/ads/network_ad_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NetworkAdHost extends ConsumerStatefulWidget {
  const NetworkAdHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<NetworkAdHost> createState() => _NetworkAdHostState();
}

class _NetworkAdHostState extends ConsumerState<NetworkAdHost> {
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bindRouter();
      _loadIfReady(ref.read(sessionControllerProvider));
    });
  }

  void _bindRouter() {
    final router = ref.read(routerProvider);
    if (identical(router, _router)) return;
    _router?.routerDelegate.removeListener(_onRoute);
    _router = router;
    router.routerDelegate.addListener(_onRoute);
    _onRoute();
  }

  void _onRoute() {
    final path = _router?.state.uri.path;
    if (path == null) return;
    ref.read(networkAdControllerProvider.notifier).onLocation(path);
  }

  void _loadIfReady(SessionState session) {
    if (session.status == SessionStatus.ready && session.hasProfile) {
      ref.read(networkAdControllerProvider.notifier).load();
    }
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onRoute);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionControllerProvider, (previous, next) => _loadIfReady(next));
    return widget.child;
  }
}
