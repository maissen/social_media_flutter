// lib/features/auth/screens/auth_check_screen.dart

import 'package:demo/features/auth/screens/login_screen.dart';
import 'package:demo/features/main_app_screen.dart';
import 'package:demo/utils/auth_helpers.dart';
import 'package:flutter/material.dart';

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
    // Small delay for splash effect (optional)
    await Future.delayed(const Duration(seconds: 1));

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
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
