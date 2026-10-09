import 'package:url_launcher/url_launcher.dart';

Uri? externalHttpUri(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null || uri.host.isEmpty) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  return uri;
}

Future<bool> openExternalLink(String value) async {
  final uri = externalHttpUri(value);
  if (uri == null) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
