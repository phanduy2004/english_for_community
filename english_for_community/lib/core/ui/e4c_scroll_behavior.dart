import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Scroll without visible scrollbar — horizontal chip/tab rows on mobile.
class E4cNoScrollbarScrollBehavior extends E4cScrollBehavior {
  const E4cNoScrollbarScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

/// Wrap scroll areas that should not show a scrollbar thumb.
Widget e4cNoScrollbarScroll({required Widget child}) {
  return ScrollConfiguration(
    behavior: const E4cNoScrollbarScrollBehavior(),
    child: child,
  );
}

/// Horizontal lists (chip rows, cue selectors) without a visible scrollbar.
Widget e4cHorizontalScroll({required Widget child}) => e4cNoScrollbarScroll(child: child);
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
///
/// Only listens to the controller until `hasClients` becomes true, then removes
/// the listener. After that, Flutter's own [Scrollbar] handles its own repainting
/// internally — no setState on every scroll pixel.
class _SafeScrollbar extends StatefulWidget {
  const _SafeScrollbar({required this.controller, required this.child});

  final ScrollController controller;
  final Widget child;

  @override
  State<_SafeScrollbar> createState() => _SafeScrollbarState();
}

class _SafeScrollbarState extends State<_SafeScrollbar> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller.hasClients) {
      _ready = true;
    } else {
      widget.controller.addListener(_onFirstClient);
    }
  }

  @override
  void didUpdateWidget(_SafeScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onFirstClient);
      if (widget.controller.hasClients) {
        _ready = true;
      } else {
        _ready = false;
        widget.controller.addListener(_onFirstClient);
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onFirstClient);
    super.dispose();
  }

  void _onFirstClient() {
    if (!_ready && widget.controller.hasClients && mounted) {
      widget.controller.removeListener(_onFirstClient);
      // Tránh setState đồng bộ khi ScrollPosition attach — gây mouse_tracker assert trên web.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _ready = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || widget.controller.positions.length != 1) {
      return widget.child;
    }
    // Do not wrap [LayoutBuilder] here — unbounded flex/dialog constraints break layout.
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
