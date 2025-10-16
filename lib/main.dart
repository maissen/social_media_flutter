import 'dart:io';
import 'package:demo/features/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:window_size/window_size.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(const MyApp());
}

/// Global scroll behavior: removes glow and adds iOS-like bounce everywhere.
class NoGlowBounceScrollBehavior extends ScrollBehavior {
  const NoGlowBounceScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BrainHub - Where you inspire',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      scrollBehavior: const NoGlowBounceScrollBehavior(),
      home: const AuthCheckScreen(),
    );
  }
}
