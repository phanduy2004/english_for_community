import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Scroll behavior for E4C (web + desktop).
///
/// Avoids `Scrollbar's ScrollController has no ScrollPosition attached` when
/// Flutter builds a scrollbar before the scrollable lays out (TabBarView, RefreshIndicator, etc.).
class E4cScrollBehavior extends MaterialScrollBehavior {
  const E4cScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    final controller = details.controller;
    if (controller == null) {
      return child;
    }
    return _SafeScrollbar(controller: controller, child: child);
  }
}

/// Renders [Scrollbar] only after [ScrollController.hasClients].
class _SafeScrollbar extends StatefulWidget {
  const _SafeScrollbar({required this.controller, required this.child});

  final ScrollController controller;
  final Widget child;

  @override
  State<_SafeScrollbar> createState() => _SafeScrollbarState();
}

class _SafeScrollbarState extends State<_SafeScrollbar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_scheduleRebuild);
  }

  @override
  void didUpdateWidget(_SafeScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_scheduleRebuild);
      widget.controller.addListener(_scheduleRebuild);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_scheduleRebuild);
    super.dispose();
  }

  void _scheduleRebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.hasClients) {
      return widget.child;
    }
    return Scrollbar(
      controller: widget.controller,
      thumbVisibility: true,
      interactive: true,
      radius: const Radius.circular(4),
      thickness: 6,
      child: widget.child,
    );
  }
}

/// Explicit controller + scrollbar for teacher pages with custom scroll body.
class E4cScrollableColumn extends StatefulWidget {
  const E4cScrollableColumn({
    super.key,
    required this.child,
    this.padding,
    this.showScrollbar = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool showScrollbar;

  @override
  State<E4cScrollableColumn> createState() => _E4cScrollableColumnState();
}

class _E4cScrollableColumnState extends State<E4cScrollableColumn> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scrollView = SingleChildScrollView(
      controller: _controller,
      padding: widget.padding,
      child: widget.child,
    );
    if (!widget.showScrollbar) return scrollView;
    return Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      interactive: true,
      radius: const Radius.circular(4),
      thickness: 6,
      child: scrollView,
    );
  }
}
