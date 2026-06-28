import 'dart:async';

import 'package:flutter/material.dart';

/// Debounced client-side search for skill hub list pages.
///
/// Avoids wrapping the list in [ValueListenableBuilder] — rebuilding slivers
/// on every keystroke while the mouse hovers cards triggers Flutter Web
/// `mouse_tracker` asserts.
mixin SkillListSearchMixin<T extends StatefulWidget> on State<T> {
  final TextEditingController skillListSearchController = TextEditingController();
  String _skillListSearchQuery = '';
  Timer? _skillListSearchDebounce;

  String get skillListSearchQuery => _skillListSearchQuery;

  @protected
  void initSkillListSearch({Duration debounce = const Duration(milliseconds: 200)}) {
    skillListSearchController.addListener(() {
      _skillListSearchDebounce?.cancel();
      _skillListSearchDebounce = Timer(debounce, () {
        final next = skillListSearchController.text;
        if (next != _skillListSearchQuery && mounted) {
          setState(() => _skillListSearchQuery = next);
        }
      });
    });
  }

  @protected
  void disposeSkillListSearch() {
    _skillListSearchDebounce?.cancel();
    skillListSearchController.dispose();
  }

  void clearSkillListSearch(BuildContext context) {
    _skillListSearchDebounce?.cancel();
    skillListSearchController.clear();
    if (_skillListSearchQuery.isNotEmpty) {
      setState(() => _skillListSearchQuery = '');
    }
    FocusScope.of(context).unfocus();
  }

  bool skillListMatchesPrefix(String source, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return true;
    return source.trimLeft().toLowerCase().startsWith(normalizedQuery);
  }
}
