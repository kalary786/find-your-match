import 'package:find_your_match/app.dart';
import 'package:find_your_match/features/ads/live_network_ads.dart';
import 'package:find_your_match/features/ads/network_ad_controller.dart';
import 'package:find_your_match/features/ads/network_banner.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        fullScreenAdPlayerProvider.overrideWithValue(
          const LiveFullScreenAdPlayer(),
        ),
        networkBannerViewProvider.overrideWithValue(liveBannerView),
      ],
      child: const FindYourMatchApp(),
    ),
  );
}
