import 'package:flutter/material.dart';

class PostScreen extends StatelessWidget {
  final String postId;

  const PostScreen({Key? key, required this.postId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: Center(
        child: Text('Post ID: $postId', style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}
