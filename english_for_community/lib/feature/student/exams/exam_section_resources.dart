/// Resolves CMS-linked exercises for integrated exam skill sections.
List<Map<String, dynamic>> sectionResourcesFrom(Map<String, dynamic> section) {
  final resources = <Map<String, dynamic>>[];
  final raw = section['resources'];
  if (raw is List && raw.isNotEmpty) {
    for (final e in raw) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final id = _resourceIdFromMap(m);
      if (id.isEmpty) continue;
      resources.add({
        'id': id,
        'title': (m['title'] as String?)?.trim() ?? (m['name'] as String?)?.trim() ?? '',
      });
    }
  }
  if (resources.isEmpty) {
    final id = (section['resourceId'] as String?)?.trim() ?? '';
    final title = (section['resourceTitle'] as String?)?.trim() ?? '';
    if (id.isNotEmpty) resources.add({'id': id, 'title': title});
  }
  return resources;
}

String _resourceIdFromMap(Map<String, dynamic> m) {
  final id = m['id'] ?? m['_id'] ?? m['resourceId'];
  return id?.toString().trim() ?? '';
}

Map<String, dynamic>? fixedWritingPromptFrom(Map<String, dynamic> section) {
  final raw = section['fixedWritingPrompt'];
  if (raw is Map && (raw['text'] as String?)?.trim().isNotEmpty == true) {
    return Map<String, dynamic>.from(raw);
  }
  return null;
}

bool sectionHasWritingPromptOnly(Map<String, dynamic> section) {
  return section['skill'] == 'writing' &&
      fixedWritingPromptFrom(section) != null &&
      sectionResourcesFrom(section).isEmpty;
}
