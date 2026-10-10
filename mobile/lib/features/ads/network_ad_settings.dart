import 'package:find_your_match/features/ads/external_link.dart';

enum AdNetwork { admob, admobAppOpen, monetag }

class AdSlot {
  const AdSlot(this.network, this.id);

  final AdNetwork network;
  final String id;
}

class NetworkAdSettings {
  const NetworkAdSettings({
    this.bannerEnabled = false,
    this.interstitialEnabled = false,
    this.admobAppId = '',
    this.admobBannerUnit = '',
    this.admobInterstitialUnit = '',
    this.admobAppOpenUnit = '',
    this.admobInChats = false,
    this.appnextBanner = '',
    this.appnextInterstitial = '',
    this.appnextType = 'interstitial',
    this.facebookBanner = '',
    this.facebookInterstitial = '',
    this.startioAppId = '',
    this.unityGameId = '',
    this.unityBannerPlacement = '',
    this.unityInterstitialPlacement = '',
    this.ironsourceAppKey = '',
    this.wortiseAppId = '',
    this.wortiseBannerUnit = '',
    this.wortiseInterstitialUnit = '',
    this.monetagLink = '',
    this.bannerPosition = 'bottom',
    this.bannerSize = 'normal',
    this.pageInterval = 4,
    this.chatInterval = 20,
    this.launchInterval = 4,
    this.showFirstLaunch = true,
  });

  static const off = NetworkAdSettings();

  final bool bannerEnabled;
  final bool interstitialEnabled;
  final String admobAppId;
  final String admobBannerUnit;
  final String admobInterstitialUnit;
  final String admobAppOpenUnit;
  final bool admobInChats;
  final String appnextBanner;
  final String appnextInterstitial;
  final String appnextType;
  final String facebookBanner;
  final String facebookInterstitial;
  final String startioAppId;
  final String unityGameId;
  final String unityBannerPlacement;
  final String unityInterstitialPlacement;
  final String ironsourceAppKey;
  final String wortiseAppId;
  final String wortiseBannerUnit;
  final String wortiseInterstitialUnit;
  final String monetagLink;
  final String bannerPosition;
  final String bannerSize;
  final int pageInterval;
  final int chatInterval;
  final int launchInterval;
  final bool showFirstLaunch;

  bool get bannerAtTop => bannerPosition == 'top';
  bool get largeBanner => bannerSize == 'large';

  factory NetworkAdSettings.fromJson(Map<String, dynamic> json) {
    return NetworkAdSettings(
      bannerEnabled: _flag(json['bannerEnabled']),
      interstitialEnabled: _flag(json['interstitialEnabled']),
      admobAppId: _text(json['admobAppId']),
      admobBannerUnit: _text(json['admobBannerUnit']),
      admobInterstitialUnit: _text(json['admobInterstitialUnit']),
      admobAppOpenUnit: _text(json['admobAppOpenUnit']),
      admobInChats: _flag(json['admobInChats']),
      appnextBanner: _text(json['appnextBanner']),
      appnextInterstitial: _text(json['appnextInterstitial']),
      appnextType: _text(json['appnextType']),
      facebookBanner: _text(json['facebookBanner']),
      facebookInterstitial: _text(json['facebookInterstitial']),
      startioAppId: _text(json['startioAppId']),
      unityGameId: _text(json['unityGameId']),
      unityBannerPlacement: _text(json['unityBannerPlacement']),
      unityInterstitialPlacement: _text(json['unityInterstitialPlacement']),
      ironsourceAppKey: _text(json['ironsourceAppKey']),
      wortiseAppId: _text(json['wortiseAppId']),
      wortiseBannerUnit: _text(json['wortiseBannerUnit']),
      wortiseInterstitialUnit: _text(json['wortiseInterstitialUnit']),
      monetagLink: _text(json['monetagLink']),
      bannerPosition: _text(json['bannerPosition']).isEmpty
          ? 'bottom'
          : _text(json['bannerPosition']),
      bannerSize: _text(json['bannerSize']).isEmpty
          ? 'normal'
          : _text(json['bannerSize']),
      pageInterval: _number(json['pageInterval'], 4),
      chatInterval: _number(json['chatInterval'], 20),
      launchInterval: _number(json['launchInterval'], 4),
      showFirstLaunch: json['showFirstLaunch'] == null
          ? true
          : _flag(json['showFirstLaunch']),
    );
  }
}

const fullScreenCooldown = Duration(seconds: 45);

bool cooledDown(DateTime? last, DateTime now) {
  if (last == null) return true;
  return now.difference(last) >= fullScreenCooldown;
}

bool dueEvery(int count, int interval) {
  return interval > 0 && count > 0 && count % interval == 0;
}

bool dueOnLaunch({
  required int count,
  required int interval,
  required bool showFirst,
}) {
  if (interval <= 0 || count <= 0) return false;
  if (count == 1) return showFirst;
  return count % interval == 0;
}

bool countsAsContentPage(String path) {
  if (path.startsWith('/report')) return false;
  if (path.startsWith('/settings/delete-account')) return false;
  if (path.startsWith('/conversation')) return false;
  if (path.startsWith('/splash') ||
      path.startsWith('/setup') ||
      path.startsWith('/onboarding') ||
      path.startsWith('/error')) {
    return false;
  }
  const prefixes = [
    '/discover',
    '/search',
    '/matches',
    '/chats',
    '/profile',
    '/people/',
    '/settings',
    '/filters',
    '/edit-profile',
    '/notices',
    '/legal/',
  ];
  return prefixes.any(path.startsWith);
}

List<AdSlot> bannerChoices(NetworkAdSettings settings, {required bool inChat}) {
  if (!settings.bannerEnabled || settings.admobBannerUnit.isEmpty) {
    return const [];
  }
  if (inChat && !settings.admobInChats) return const [];
  return [AdSlot(AdNetwork.admob, settings.admobBannerUnit)];
}

List<AdSlot> interstitialChoices(
  NetworkAdSettings settings, {
  required bool inChat,
}) {
  if (!settings.interstitialEnabled) return const [];
  final slots = <AdSlot>[];
  if (!inChat && settings.admobInterstitialUnit.isNotEmpty) {
    slots.add(AdSlot(AdNetwork.admob, settings.admobInterstitialUnit));
  }
  final link = settings.monetagLink.trim();
  if (externalHttpUri(link) != null) {
    slots.add(AdSlot(AdNetwork.monetag, link));
  }
  return slots;
}

AdSlot? chooseSlot(List<AdSlot> slots, int roll) {
  if (slots.isEmpty) return null;
  return slots[roll.abs() % slots.length];
}

bool _flag(Object? value) => value == true || value == 1 || value == '1';

String _text(Object? value) => value?.toString() ?? '';

int _number(Object? value, int fallback) {
  if (value is int) return value;
  return int.tryParse('$value') ?? fallback;
}
