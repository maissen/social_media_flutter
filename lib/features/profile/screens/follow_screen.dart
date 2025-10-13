import 'package:flutter/material.dart';

class FollowScreen extends StatelessWidget {
  const FollowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigates back to the previous screen
          },
        ),
        title: const Text('Followers / Following'),
        centerTitle: true,
      ),
      body: const Center(child: Text('Followers / Following Screen')),
    );
  }
}
