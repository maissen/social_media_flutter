import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_size/window_size.dart';

Future<void> setupPlatform() async {
  if (Platform.isWindows) {
    const double windowWidth = 500.0;
    const double windowHeight = 932.0;

    // Set window title
    setWindowTitle('BrainHub - Where you inspire');

    // Fix the window size (unresizable)
    setWindowMinSize(const Size(windowWidth, windowHeight));
    setWindowMaxSize(const Size(windowWidth, windowHeight));

    // Center the window on the primary screen
    final screen = await getCurrentScreen();
    if (screen != null) {
      final screenFrame = screen.frame;
      final double left =
          screenFrame.left + (screenFrame.width - windowWidth) / 2;
      final double top =
          screenFrame.top + (screenFrame.height - windowHeight) / 2;

      setWindowFrame(Rect.fromLTWH(left, top, windowWidth, windowHeight));
    }
  }
}
