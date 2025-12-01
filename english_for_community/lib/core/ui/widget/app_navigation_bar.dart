import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppNavItem {
  const AppNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.routeName,
    this.badge,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String? routeName; // optional: dùng với GoRouter
  final Widget? badge;     // optional: Badge cho icon
}

class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onIndexSelected,
    required this.items,
    this.useGoRouter = false,
    this.labelBehavior = NavigationDestinationLabelBehavior.alwaysShow,
  }) : assert(items.length >= 2, 'Need at least 2 tabs');

  /// Chỉ số tab đang chọn (mode index)
  final int currentIndex;

  /// Callback khi chọn tab (mode index). Bỏ qua nếu `useGoRouter = true`
  final ValueChanged<int> onIndexSelected;

  /// Danh sách item
  final List<AppNavItem> items;

  /// Nếu true và có routeName, sẽ điều hướng bằng GoRouter thay vì onIndexSelected
  final bool useGoRouter;

  /// Hiển thị nhãn
  final NavigationDestinationLabelBehavior labelBehavior;

  /// Factory nhanh: 4 tab chuẩn của app
  factory AppNavigationBar.main({
    Key? key,
    required int currentIndex,
    required ValueChanged<int> onIndexSelected,
    bool useGoRouter = false,
    // Gắn tên route nếu bạn dùng GoRouter
    String? homeRouteName,
    String? vocabularyRouteName,
    String? practiceRouteName,
    String? profileRouteName,
    // Badge tuỳ chọn
    Widget? vocabularyBadge,
    Widget? practiceBadge,
    Widget? profileBadge,
  }) {
    final items = <AppNavItem>[
      AppNavItem(
        label: 'Home',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        routeName: homeRouteName,
      ),
      AppNavItem(
        label: 'Progress',
        icon: Icons.style_outlined,
        selectedIcon: Icons.style,
        routeName: vocabularyRouteName,
        badge: vocabularyBadge,
      ),
      AppNavItem(
        label: 'Profile',
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        routeName: profileRouteName,
        badge: profileBadge,
      ),
    ];

    return AppNavigationBar(
      key: key,
      currentIndex: currentIndex,
      onIndexSelected: onIndexSelected,
      items: items,
      useGoRouter: useGoRouter,
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      labelBehavior: labelBehavior,
      onDestinationSelected: (i) {
        if (useGoRouter && items[i].routeName != null) {
          context.goNamed(items[i].routeName!);
          return;
        }
        onIndexSelected(i);
      },
      destinations: items.map((it) {
        final icon = Icon(it.icon);
        final selected = Icon(it.selectedIcon);

        // Nếu có badge, bọc icon bằng Badge (Material 3)
        final iconWithBadge = it.badge == null
            ? icon
            : Badge(
          alignment: Alignment.topRight,
          label: it.badge is Text ? it.badge as Text? : null,
          child: icon,
        );

        final selectedWithBadge = it.badge == null
            ? selected
            : Badge(
          alignment: Alignment.topRight,
          label: it.badge is Text ? it.badge as Text? : null,
          child: selected,
        );

        return NavigationDestination(
          icon: iconWithBadge,
          selectedIcon: selectedWithBadge,
          label: it.label,
        );
      }).toList(),
    );
  }
}
