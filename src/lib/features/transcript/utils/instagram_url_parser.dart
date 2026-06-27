class InstagramUrlParser {
  const InstagramUrlParser._();

  static final RegExp _urlPattern = RegExp(
    r'https?://(?:www\.)?instagram\.com/[^\s]+',
    caseSensitive: false,
  );

  static String? firstInstagramUrl(String? text) {
    if (text == null) return null;

    final Match? match = _urlPattern.firstMatch(text.trim());
    final String? candidate = match == null ? text.trim() : match.group(0);
    if (candidate == null || candidate.isEmpty) return null;

    return isValid(candidate) ? candidate : null;
  }

  static bool isValid(String url) {
    final Uri? uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return false;

    final String host = uri.host.toLowerCase();
    final String path = uri.path.toLowerCase();

    return (host == 'instagram.com' || host == 'www.instagram.com') &&
        (path.contains('/reel/') || path.contains('/p/') || path.contains('/tv/'));
  }
}
