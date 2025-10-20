import 'dart:ui';
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade50,
              Colors.blue.shade50,
              Colors.deepPurple.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with gradient
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.deepPurple, Colors.blue],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text(
                      'Chats',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: FutureBuilder<List<UserProfileSimplified>>(
                  future: _contactsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.deepPurple, Colors.blue],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error: ${snapshot.error}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.deepPurple.withOpacity(0.1),
                                    Colors.blue.withOpacity(0.1),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.deepPurple.shade300,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No conversations yet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start chatting with your contacts',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final contacts = snapshot.data!;

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: contacts.length,
                      itemBuilder: (context, index) {
                        final contact = contacts[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurple.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.deepPurple.shade200,
                                              Colors.blue.shade200,
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.deepPurple
                                                  .withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: CircleAvatar(
                                          radius: 28,
                                          backgroundColor: Colors.transparent,
                                          backgroundImage:
                                              contact.profilePicture != null
                                              ? NetworkImage(
                                                  contact.profilePicture!,
                                                )
                                              : null,
                                          child: contact.profilePicture == null
                                              ? Text(
                                                  contact.username[0]
                                                      .toUpperCase(),
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : null,
                                        ),
                                      ),
                                      if (contact.isFollowing)
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.check_circle,
                                              color: Colors.green.shade400,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  title: Text(
                                    contact.username,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      contact.email,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  trailing: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.deepPurple.withOpacity(0.2),
                                          Colors.blue.withOpacity(0.2),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: Colors.deepPurple.shade400,
                                        size: 18,
                                      ),
                                      onPressed: () =>
                                          _openConversation(contact),
                                    ),
                                  ),
                                  onTap: () => _openConversation(contact),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
