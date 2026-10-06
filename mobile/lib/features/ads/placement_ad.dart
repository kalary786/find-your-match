import 'package:find_your_match/features/preview/preview_models.dart';
import 'package:find_your_match/features/social/social_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class PlacementAd extends ConsumerWidget {
  const PlacementAd({required this.placement, super.key});

  final String placement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ad = ref.watch(socialControllerProvider).ads[placement];
    if (ad == null || ad.imageUrl.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => _open(ad),
          child: SizedBox(
            height: 72,
            width: double.infinity,
            child: Image.network(
              ad.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Center(child: Text(ad.title));
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(HostedAd ad) async {
    final uri = Uri.tryParse(ad.linkUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
