import 'package:flutter/material.dart';

class ConversationScreen extends StatelessWidget {
  final String recipientUserId;

  const ConversationScreen({Key? key, required this.recipientUserId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversation'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Text(
          'you want to chat with User $recipientUserId',
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
