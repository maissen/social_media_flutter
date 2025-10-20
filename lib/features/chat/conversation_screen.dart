import 'package:flutter/material.dart';

class ConversationScreen extends StatelessWidget {
  final String currentUserId;
  final String recipientUserId;

  const ConversationScreen({
    Key? key,
    required this.currentUserId,
    required this.recipientUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with $recipientUserId'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Text(
          'User $currentUserId wants to chat with $recipientUserId',
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
