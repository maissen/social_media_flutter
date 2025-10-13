import 'package:flutter/material.dart';

class RestorePasswordScreen extends StatelessWidget {
  const RestorePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        // Back arrow appears automatically
      ),
      body: const Center(child: Text('Restore Password Screen')),
    );
  }
}
