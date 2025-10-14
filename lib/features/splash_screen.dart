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
    // Optional delay for splash effect
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
      backgroundColor: const Color(0xFFdee2ff), // full screen color
      body: Center(child: Text("Maissen Belgacem")),
    );
  }
}
