import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';

extension L10nBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
