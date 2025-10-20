import 'package:demo/features/chat/conversation_screen.dart';
import 'package:flutter/material.dart';
import 'package:demo/utils/auth_helpers.dart';
import 'package:demo/utils/chat_helpers.dart';
import 'dart:async';

/// --------------------------
/// Conversations / Contacts List Screen
/// --------------------------
class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({Key? key}) : super(key: key);

  @override
  State<ConversationsListScreen> createState() =>
      _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  late Future<List<UserProfileSimplified>> _contactsFuture;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  void _loadContacts() {
    _contactsFuture = _fetchContacts();
  }

  Future<List<UserProfileSimplified>> _fetchContacts() async {
    final token = await getAccessToken();
    if (token == null) throw Exception("User not logged in");

    // Await the Future returned by getMyConversations
    final List<UserProfileSimplified> contacts = await getMyConversations();
    return contacts;
  }

  void _openConversation(UserProfileSimplified contact) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ConversationScreen(recipientUserId: contact.userId.toString()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: FutureBuilder<List<UserProfileSimplified>>(
        future: _contactsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No contacts found'));
          }

          final contacts = snapshot.data!;

          return ListView.separated(
            itemCount: contacts.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final contact = contacts[index];

              return ListTile(
                leading: CircleAvatar(
                  radius: 25,
                  backgroundImage: contact.profilePicture != null
                      ? NetworkImage(contact.profilePicture!)
                      : null,
                  child: contact.profilePicture == null
                      ? Text(contact.username[0].toUpperCase())
                      : null,
                ),
                title: Text(contact.username),
                subtitle: Text(contact.email),
                trailing: contact.isFollowing
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () => _openConversation(contact),
              );
            },
          );
        },
      ),
    );
  }
}
