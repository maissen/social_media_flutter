import 'package:flutter/material.dart';

/// Global ScrollBehavior that removes overscroll glow and applies iOS-like bounce.
class NoGlowBounceScrollBehavior extends ScrollBehavior {
  const NoGlowBounceScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Removes the blue/white glow on Android
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // Makes scrolls feel like iOS — slightly bouncy at edges
    return const BouncingScrollPhysics();
  }
}
