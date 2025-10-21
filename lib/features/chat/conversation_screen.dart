import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demo/config/constants.dart';
import 'package:demo/utils/auth_helpers.dart';
import 'package:demo/utils/chat_helpers.dart';

// ---------------------------
// User profile fetcher
// ---------------------------
class GetUserResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? user;

  GetUserResponse({required this.success, required this.message, this.user});
}

Future<GetUserResponse> getUserSimplifiedProfile({
  required String userId,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  if (token == null) {
    return GetUserResponse(
      success: false,
      message: 'User not authenticated. Please login.',
      user: null,
    );
  }

  final url = Uri.parse(
    '${AppConstants.baseApiUrl}/users/get-user?user_id=$userId',
  );

  try {
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return GetUserResponse(
        success: true,
        message: body['message'] ?? 'User retrieved successfully',
        user: Map<String, dynamic>.from(body['data']),
      );
    } else {
      return GetUserResponse(
        success: false,
        message: body['message'] ?? 'Failed to fetch user',
        user: null,
      );
    }
  } catch (e) {
    return GetUserResponse(
      success: false,
      message: 'An error occurred: $e',
      user: null,
    );
  }
}

// ---------------------------
// Conversation Screen
// ---------------------------
class ConversationScreen extends StatefulWidget {
  final String recipientUserId;

  const ConversationScreen({Key? key, required this.recipientUserId})
    : super(key: key);

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _recipientUser;

  WebSocketChannel? _channel;
  Timer? _timer;
  Timer? _resetTimer;
  Timer? _typingTimer;

  bool _isConnected = false;
  bool _isLoading = false;
  bool _isSending = false;
  bool _recipientIsOnline = false;
  bool _recipientIsInConversation = false;
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    _fetchRecipientUser();
    // _fetchMessages();
    _initializeConversation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _channel?.sink.close();
    _messageController.dispose();
    _scrollController.dispose();
    _resetTimer?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }

  // ---------------------------
  // Fetch recipient user info
  // ---------------------------
  Future<void> _fetchRecipientUser() async {
    try {
      final response = await getUserSimplifiedProfile(
        userId: widget.recipientUserId,
      );
      if (response.success && response.user != null) {
        setState(() {
          _recipientUser = response.user;
        });
      } else {
        print('Failed to fetch recipient: ${response.message}');
      }
    } catch (e) {
      print('Error fetching recipient user: $e');
    }
  }

  // ---------------------------
  // Initialize conversation
  // ---------------------------
  Future<void> _initializeConversation() async {
    await _fetchMessages();
    await _connectWebSocket();
  }

  // ---------------------------
  // Fetch messages
  // ---------------------------
  Future<void> _fetchMessages() async {
    if (_isSending) return;

    try {
      final token = await getAccessToken();
      if (token == null) return;

      final messages = await getConversation(
        token: token,
        recipientId: int.parse(widget.recipientUserId),
      );

      if (!mounted) return;
      setState(() {
        _messages = messages
            .map<Map<String, dynamic>>(
              (msg) => {
                'sender_id': msg['sender_id'].toString(),
                'content': msg['content'],
                'timestamp': msg['timestamp'],
              },
            )
            .toList();
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      print('Failed to fetch messages: $e');
    }
  }

  // ---------------------------
  // Connect WebSocket
  // ---------------------------
  Future<void> _connectWebSocket() async {
    try {
      final token = await getAccessToken();
      if (token == null) return;

      _myUserId = await _getCurrentUserId(token);
      if (_myUserId == null) return;

      final wsUrl = Uri.parse(
        '${AppConstants.baseWsUrl}/ws?user_id=$_myUserId',
      );
      _channel = WebSocketChannel.connect(wsUrl);

      setState(() => _isConnected = true);

      _channel!.stream.listen(
        (message) => _handleWebSocketMessage(message),
        onError: (error) {
          print('WebSocket error: $error');
          setState(() => _isConnected = false);
        },
        onDone: () {
          setState(() => _isConnected = false);
        },
      );
    } catch (e) {
      print('Failed to connect WebSocket: $e');
      setState(() => _isConnected = false);
    }
  }

  // ---------------------------
  // Decode current user ID
  // ---------------------------
  Future<String?> _getCurrentUserId(String token) async {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(decoded);

      return payloadMap['sub']?.toString();
    } catch (e) {
      print('Error getting user ID: $e');
      return null;
    }
  }

  // ---------------------------
  // Handle WebSocket messages
  // ---------------------------
  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = json.decode(message);

      if (data['type'] == 'user_list') {
        final users = data['users'] as List?;
        if (users != null) {
          final wasOnline = _recipientIsOnline;
          setState(() {
            _recipientIsOnline = users.any(
              (u) => u.toString() == widget.recipientUserId,
            );
          });
          if (!wasOnline && _recipientIsOnline) {
            _recipientIsInConversation = false;
          }
        }
      } else if (data['type'] == 'chat') {
        final from = data['from'].toString();
        final content = data['content'];

        if (from == widget.recipientUserId) {
          setState(() {
            _messages.add({
              'sender_id': from,
              'content': content,
              'timestamp': DateTime.now().toIso8601String(),
            });
            _recipientIsInConversation = true;
          });
          _scrollToBottom();
          _resetRecipientStatus();
        }
      } else if (data['type'] == 'sent') {
        final to = data['to'].toString();
        final content = data['content'];

        if (to == widget.recipientUserId) {
          setState(() {
            _messages.add({
              'sender_id': _myUserId,
              'content': content,
              'timestamp': DateTime.now().toIso8601String(),
            });
          });
          _scrollToBottom();
        }
      } else if (data['type'] == 'typing') {
        final from = data['from']?.toString();
        final status = data['status']?.toString();

        if (from == widget.recipientUserId) {
          setState(() => _recipientIsInConversation = status == 'start');
          _resetRecipientStatus();
        }
      }
    } catch (e) {
      print('Error handling WebSocket message: $e');
    }
  }

  // ---------------------------
  // Reset "watching you" / typing status
  // ---------------------------
  void _resetRecipientStatus() {
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _recipientIsInConversation = false);
      }
    });
  }

  // ---------------------------
  // Scroll to bottom
  // ---------------------------
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ---------------------------
  // Send typing status
  // ---------------------------
  void _sendTypingStatus({required bool startTyping}) {
    if (!_isConnected || _myUserId == null) return;

    final payload = json.encode({
      'type': 'typing',
      'recipient_id': int.parse(widget.recipientUserId),
      'status': startTyping ? 'start' : 'stop',
    });

    _channel?.sink.add(payload);

    // Reset typing status if user stops typing for 3 seconds
    _typingTimer?.cancel();
    if (startTyping) {
      _typingTimer = Timer(const Duration(seconds: 3), () {
        final stopPayload = json.encode({
          'type': 'typing',
          'recipient_id': int.parse(widget.recipientUserId),
          'status': 'stop',
        });
        _channel?.sink.add(stopPayload);
      });
    }
  }

  // ---------------------------
  // Send message
  // ---------------------------
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || !_isConnected) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    setState(() => _isSending = true);

    try {
      final token = await getAccessToken();
      if (token == null) throw Exception("No access token found");

      await sendChatMessage(
        token: token,
        recipientId: int.parse(widget.recipientUserId),
        content: content,
      );

      final payload = json.encode({
        'type': 'chat',
        'recipient_id': int.parse(widget.recipientUserId),
        'content': content,
      });

      _channel?.sink.add(payload);
      // await _fetchMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ---------------------------
  // UI
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0, // remove default elevation
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.deepPurple, Colors.blue],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25), // shadow color
                blurRadius: 8, // blur
                offset: const Offset(0, 4), // vertical offset downwards
              ),
            ],
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: profile + username
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage:
                      _recipientUser != null &&
                          (_recipientUser!['profile_picture']?.isNotEmpty ??
                              false)
                      ? NetworkImage(_recipientUser!['profile_picture'])
                      : null,
                  backgroundColor: Colors.deepPurple.shade300,
                  child:
                      _recipientUser != null &&
                          (_recipientUser!['profile_picture']?.isEmpty ?? true)
                      ? Text(
                          (_recipientUser!['username'] ?? 'U')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _recipientUser != null
                          ? _recipientUser!['username'] ??
                                _recipientUser!['email'] ??
                                'Conversation'
                          : 'Conversation',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (_recipientIsOnline)
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            color: Colors.greenAccent.shade400,
                            size: 8,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _recipientIsInConversation
                                ? '${_recipientUser!['username']} is typing...'
                                : 'Online',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: _recipientIsInConversation
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
            // Right: X button
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),

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
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Colors.deepPurple,
                      ),
                    )
                  : _messages.isEmpty
                  ? Center(
                      child: Text(
                        'No messages yet. Start the conversation!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isMe =
                            message['sender_id'].toString() !=
                            widget.recipientUserId;

                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: isMe
                                  ? LinearGradient(
                                      colors: [Colors.deepPurple, Colors.blue],
                                    )
                                  : null,
                              color: isMe
                                  ? null
                                  : Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: isMe
                                      ? Colors.deepPurple.withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              message['content'] ?? '',
                              style: TextStyle(
                                color: isMe
                                    ? Colors.white
                                    : Colors.grey.shade800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade50.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                              ),
                              maxLines: null,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                              enabled: _isConnected,
                              onChanged: (text) {
                                _sendTypingStatus(startTyping: text.isNotEmpty);
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: _isConnected
                          ? LinearGradient(
                              colors: [Colors.deepPurple, Colors.blue],
                            )
                          : null,
                      color: _isConnected ? null : Colors.grey.shade400,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _isConnected
                              ? Colors.deepPurple.withOpacity(0.4)
                              : Colors.grey.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                      onPressed: (_isSending || !_isConnected)
                          ? null
                          : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
