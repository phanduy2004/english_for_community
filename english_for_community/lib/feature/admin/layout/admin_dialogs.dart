import 'package:english_for_community/feature/admin/layout/admin_account_menu.dart';
import 'package:flutter/material.dart';

export 'admin_account_menu.dart' show showAdminAccountMenu;

abstract final class AdminDialogs {
  static void showAccountMenu(BuildContext context) => showAdminAccountMenu(context);
}
