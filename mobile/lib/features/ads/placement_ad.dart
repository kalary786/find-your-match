import 'package:find_your_match/features/ads/external_link.dart';
import 'package:find_your_match/features/social/social_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlacementAd extends ConsumerWidget {
  const PlacementAd({required this.placement, super.key});

  final String placement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ad = ref.watch(socialControllerProvider).ads[placement];
    if (ad == null || ad.imageUrl.isEmpty) return const SizedBox.shrink();
    final link = externalHttpUri(ad.linkUrl);
    final cacheWidth = (MediaQuery.sizeOf(context).width *
            MediaQuery.devicePixelRatioOf(context))
        .round()
        .clamp(320, 1080)
        .toInt();
    final image = Image.network(
      ad.imageUrl,
      fit: BoxFit.cover,
      cacheWidth: cacheWidth,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) {
        return Center(child: Text(ad.title));
      },
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          height: 72,
          width: double.infinity,
          child: link == null
              ? image
              : InkWell(
                  onTap: () => openExternalLink(ad.linkUrl),
                  child: image,
                ),
        ),
      ),
    );
  }
}
