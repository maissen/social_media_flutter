import 'package:flutter/material.dart';
import 'features/auth/screens/login_screen.dart';

void main() {
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
    // Removes the glow effect when overscrolling
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // Adds iOS-style bounce effect to all scrollables
    return const BouncingScrollPhysics();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      scrollBehavior: const NoGlowBounceScrollBehavior(), // 👈 global behavior
      home: const LoginScreen(),
    );
  }
}
