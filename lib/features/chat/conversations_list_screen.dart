import 'package:demo/utils/auth_helpers.dart';
import 'package:demo/utils/chat_helpers.dart';
import 'package:flutter/material.dart';

class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({
    Key? key,
    required this.currentUserId,
    required this.recipientUserId,
  }) : super(key: key);

  final String currentUserId;
  final String recipientUserId;

  @override
  State<ConversationsListScreen> createState() =>
      _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  late Future<List<Map<String, dynamic>>> _conversationsFuture;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  void _loadConversations() async {
    _conversationsFuture = _fetchConversations();
  }

  Future<List<Map<String, dynamic>>> _fetchConversations() async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception("User not logged in");
    }
    return await getMyConversations(token: token);
  }

  void _openConversation(Map<String, dynamic> conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          recipientId: conversation['recipient_id'],
          recipientName: conversation['recipient_name'] ?? 'Unknown',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversations')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _conversationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No conversations found'));
          }

          final conversations = snapshot.data!;

          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return ListTile(
                title: Text(conversation['recipient_name'] ?? 'Unknown'),
                subtitle: Text(
                  conversation['last_message'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  conversation['last_message_time'] ?? '',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () => _openConversation(conversation),
              );
            },
          );
        },
      ),
    );
  }
}

// Example ChatDetailScreen stub
class ChatDetailScreen extends StatelessWidget {
  final int recipientId;
  final String recipientName;

  const ChatDetailScreen({
    Key? key,
    required this.recipientId,
    required this.recipientName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(recipientName)),
      body: Center(child: Text('Chat with $recipientName (ID: $recipientId)')),
    );
  }
}
