/// Shared avatar URL validation — avoids broken hosts (e.g. github profile pages).
bool isUsableAvatarUrl(String? url) {
  if (url == null || url.trim().isEmpty) return false;
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !uri.hasScheme) return false;
  final host = uri.host.toLowerCase();
  if (host == 'github.com' || host == 'www.github.com') return false;
  return true;
}

String avatarInitials(String? name, {String fallback = '?'}) {
  final trimmed = name?.trim() ?? '';
  if (trimmed.isEmpty) return fallback;
  return trimmed[0].toUpperCase();
}
