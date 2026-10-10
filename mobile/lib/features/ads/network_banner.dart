import 'package:find_your_match/features/ads/network_ad_controller.dart';
import 'package:find_your_match/features/ads/network_ad_settings.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef NetworkBannerView = Widget Function({
  required String unitId,
  required bool large,
});

final networkBannerViewProvider = Provider<NetworkBannerView>(
  (ref) =>
      ({required String unitId, required bool large}) => const SizedBox.shrink(),
);

class NetworkBanner extends ConsumerWidget {
  const NetworkBanner({required this.inChat, super.key});

  final bool inChat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ads = ref.watch(networkAdControllerProvider);
    final slot = chooseSlot(
      bannerChoices(ads.settings, inChat: inChat),
      ads.bannerRoll,
    );
    if (slot == null || slot.network != AdNetwork.admob) {
      return const SizedBox.shrink();
    }
    final view = ref.watch(networkBannerViewProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: view(unitId: slot.id, large: ads.settings.largeBanner),
      ),
    );
  }
}
