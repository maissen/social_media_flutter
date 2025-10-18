import 'package:demo/features/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional imports
import 'main_desktop.dart' if (dart.library.html) 'main_web.dart' as platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Call platform-specific setup
  await platform.setupPlatform();

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
