import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:demo/utils/auth_helpers.dart';
import 'package:demo/config/constants.dart';

/// Base API URL for chat
final Uri chatApiBase = Uri.parse('${AppConstants.baseApiUrl}/chat');

Future<List<dynamic>> getConversation({
  required String token,
  required int recipientId,
}) async {
  final url = chatApiBase.replace(
    path: '${chatApiBase.path}/conversation',
    queryParameters: {"recipient_id": recipientId.toString()},
  );

  final response = await http.get(
    url,
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data["messages"] as List<dynamic>? ?? [];
  } else {
    throw Exception(
      "Failed to fetch conversation: ${response.statusCode} ${response.body}",
    );
  }
}

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

  WebSocketChannel? _channel;
  List<Map<String, dynamic>> _messages = [];
  bool _isConnected = false;
  bool _isSending = false;
  String? _myUserId;
  bool _recipientIsOnline = false;
  bool _recipientIsInConversation = false;

  Timer? _resetTimer;

  @override
  void initState() {
    super.initState();
    _initializeConversation();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _messageController.dispose();
    _scrollController.dispose();
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeConversation() async {
    await _fetchMessages(); // Fetch messages first
    await _connectWebSocket(); // Then open WebSocket
  }

  Future<void> _fetchMessages() async {
    try {
      final token = await getAccessToken();
      if (token == null) return;

      final messages = await getConversation(
        token: token,
        recipientId: int.parse(widget.recipientUserId),
      );

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
      });

      _scrollToBottom();
    } catch (e) {
      print('Failed to fetch messages: $e');
    }
  }

  Future<void> _connectWebSocket() async {
    try {
      final token = await getAccessToken();
      if (token == null) return;

      _myUserId = await _getCurrentUserId(token);
      if (_myUserId == null) return;

      final wsUrl = Uri.parse('ws://localhost:8000/ws?user_id=$_myUserId');
      _channel = WebSocketChannel.connect(wsUrl);

      setState(() {
        _isConnected = true;
      });

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
        if (from == widget.recipientUserId) {
          setState(() => _recipientIsInConversation = true);
          _resetRecipientStatus();
        }
      }
    } catch (e) {
      print('Error handling WebSocket message: $e');
    }
  }

  void _resetRecipientStatus() {
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _recipientIsInConversation = false;
        });
      }
    });
  }

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

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || !_isConnected) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    setState(() => _isSending = true);

    try {
      final payload = json.encode({
        'type': 'chat',
        'recipient_id': int.parse(widget.recipientUserId),
        'content': content,
      });

      _channel?.sink.add(payload);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Conversation'),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isConnected ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            if (_recipientIsOnline)
              Text(
                _recipientIsInConversation ? 'Active now' : 'Online',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          if (!_isConnected)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.orange[100],
              child: Row(
                children: const [
                  Icon(Icons.warning, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Connecting to chat server...',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages yet. Start the conversation!',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
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
                            color: isMe ? Colors.blue : Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            message['content'] ?? '',
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    enabled: _isConnected,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: _isConnected ? Colors.blue : Colors.grey,
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
    );
  }
}
