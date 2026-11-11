import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import 'web_top_bar.dart';

/// Browser windows at least this wide get the desktop web layout (top
/// navigation bar, wide content, multi-column lists). Narrower windows —
/// and every Android / iOS build — keep the normal mobile layout.
const double kWebWideBreakpoint = 900;

/// True only in a browser window wide enough for the desktop layout.
/// Always false on Android / iOS.
bool isWideWeb(BuildContext context) {
  if (!kIsWeb) return false;
  // Inside WebContent the MediaQuery width is the (narrower) content
  // column, so the marker it leaves in the tree is checked first.
  if (context.getInheritedWidgetOfExactType<_WideWebScope>() != null) {
    return true;
  }
  return MediaQuery.sizeOf(context).width >= kWebWideBreakpoint;
}

/// Marks a subtree as being inside the desktop web layout.
class _WideWebScope extends InheritedWidget {
  const _WideWebScope({required super.child});

  @override
  bool updateShouldNotify(_WideWebScope oldWidget) => false;
}

/// Centres [child] and caps its width on the desktop web layout so text
/// lines and forms stay readable on large monitors. Returns [child]
/// untouched on mobile and in narrow browser windows.
class WebContent extends StatelessWidget {
  const WebContent({super.key, required this.child, this.maxWidth = 1200});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (!isWideWeb(context)) return child;
    final mq = MediaQuery.of(context);
    final width = mq.size.width < maxWidth ? mq.size.width : maxWidth;
    return ColoredBox(
      color: context.colors.bg,
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: width,
          // Widgets that size themselves from MediaQuery must see the
          // content width, not the whole browser window.
          child: MediaQuery(
            data: mq.copyWith(size: Size(width, mq.size.height)),
            child: _WideWebScope(child: child),
          ),
        ),
      ),
    );
  }
}

/// Desktop web page chrome for full-screen routes (login, booking steps,
/// campaign status, settings pages…): a full-width top bar with the page
/// content centred underneath at [maxWidth]. Returns [child] untouched on
/// mobile and in narrow browser windows.
class WebPageFrame extends StatelessWidget {
  const WebPageFrame({
    super.key,
    required this.child,
    this.maxWidth = 760,
    this.showNav = true,
  });

  final Widget child;
  final double maxWidth;

  /// Show the Home / History / Profile links and the notifications bell.
  /// Off for the signed-out pages (onboarding, login, OTP, signup).
  final bool showNav;

  @override
  Widget build(BuildContext context) {
    if (!isWideWeb(context)) return child;
    final mq = MediaQuery.of(context);
    return ColoredBox(
      color: context.colors.bg,
      child: Column(
        children: [
          WebTopBar(showNav: showNav),
          Expanded(
            child: MediaQuery(
              data: mq.copyWith(
                size: Size(mq.size.width, mq.size.height - kWebTopBarHeight),
              ),
              child: WebContent(maxWidth: maxWidth, child: child),
            ),
          ),
        ],
      ),
    );
  }
}
