import 'package:demo/config/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ConversationsScreen extends StatefulWidget {
  final int loggedUserId;

  const ConversationsScreen({Key? key, required this.loggedUserId})
    : super(key: key);

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<Conversation> conversations = [];
  bool isLoading = true;
  String? errorMessage;

  // Base API URL as a String
  static const String baseUrl = AppConstants.baseApiUrl;

  @override
  void initState() {
    super.initState();
    fetchConversations();
  }

  Future<void> fetchConversations() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Fetch all users to find conversations
      final usersResponse = await http.get(Uri.parse('$baseUrl/users'));

      if (usersResponse.statusCode == 200) {
        final List<dynamic> users = json.decode(usersResponse.body);
        List<Conversation> fetchedConversations = [];

        // Fetch conversation with each user
        for (var user in users) {
          if (user['id'] != widget.loggedUserId) {
            try {
              final conversationResponse = await http.get(
                Uri.parse(
                  '$baseUrl/conversation/${widget.loggedUserId}/${user['id']}',
                ),
              );

              if (conversationResponse.statusCode == 200) {
                final List<dynamic> messages = json.decode(
                  conversationResponse.body,
                );

                // Only add conversations that have messages
                if (messages.isNotEmpty) {
                  final lastMessage = messages.last;
                  fetchedConversations.add(
                    Conversation(
                      userId: user['id'],
                      username: user['username'] ?? 'Unknown User',
                      lastMessage: lastMessage['content'],
                      messageCount: messages.length,
                    ),
                  );
                }
              }
            } catch (e) {
              // Skip users with no conversations
              continue;
            }
          }
        }

        setState(() {
          conversations = fetchedConversations;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch users');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading conversations: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchConversations,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: fetchConversations,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : conversations.isEmpty
          ? const Center(
              child: Text(
                'No conversations yet',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return ConversationTile(
                  conversation: conversation,
                  onTap: () {
                    // Navigate to chat screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          loggedUserId: widget.loggedUserId,
                          otherUserId: conversation.userId,
                          otherUsername: conversation.username,
                        ),
                      ),
                    ).then((_) => fetchConversations());
                  },
                );
              },
            ),
    );
  }
}

class Conversation {
  final int userId;
  final String username;
  final String lastMessage;
  final int messageCount;

  Conversation({
    required this.userId,
    required this.username,
    required this.lastMessage,
    required this.messageCount,
  });
}

class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const ConversationTile({
    Key? key,
    required this.conversation,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue,
        child: Text(
          conversation.username[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        conversation.username,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        conversation.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.grey),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${conversation.messageCount}',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
      onTap: onTap,
    );
  }
}

// Placeholder ChatScreen - implement this based on your needs
class ChatScreen extends StatelessWidget {
  final int loggedUserId;
  final int otherUserId;
  final String otherUsername;

  const ChatScreen({
    Key? key,
    required this.loggedUserId,
    required this.otherUserId,
    required this.otherUsername,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(otherUsername)),
      body: Center(child: Text('Chat with $otherUsername')),
    );
  }
}
