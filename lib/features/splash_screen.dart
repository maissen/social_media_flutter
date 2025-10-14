// lib/features/auth/screens/auth_check_screen.dart
import 'package:demo/features/auth/screens/login_screen.dart';
import 'package:demo/features/main_app_screen.dart';
import 'package:flutter/material.dart';
import '../../../utils/auth_helpers.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Delay for splash effect
    await Future.delayed(const Duration(seconds: 2));

    final isValid = await isTokenValid();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => isValid ? const MainAppScreen() : const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea), // Purple
              Color(0xFF764ba2), // Deep Purple
              Color(0xFFf093fb), // Pink
            ],
          ),
        ),
        child: Center(
          child: Center(
            child: Image.asset('assets/main_logo.png', width: 150, height: 150),
          ),
        ),
      ),
    );
  }
}
