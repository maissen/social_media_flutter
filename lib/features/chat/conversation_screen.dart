import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:demo/config/constants.dart';
import 'package:demo/utils/auth_helpers.dart';
import 'package:demo/utils/chat_helpers.dart';

// ---------------------------
// Timestamp Helper Functions
// ---------------------------
class TimestampHelper {
  static String formatMessageTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return DateFormat('h:mm a').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  static String formatDateHeader(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

      if (messageDate == today) {
        return 'Today';
      } else if (messageDate == yesterday) {
        return 'Yesterday';
      } else if (now.difference(messageDate).inDays < 7) {
        return DateFormat('EEEE').format(dateTime);
      } else {
        return DateFormat('MMM d, yyyy').format(dateTime);
      }
    } catch (e) {
      return '';
    }
  }

  static bool shouldShowDateHeader(
    String? previousTimestamp,
    String currentTimestamp,
  ) {
    if (previousTimestamp == null) return true;

    try {
      final prevDate = DateTime.parse(previousTimestamp);
      final currDate = DateTime.parse(currentTimestamp);

      return prevDate.year != currDate.year ||
          prevDate.month != currDate.month ||
          prevDate.day != currDate.day;
    } catch (e) {
      return false;
    }
  }

  static bool shouldShowTimestamp(
    String? previousTimestamp,
    String currentTimestamp,
    bool sameUser,
  ) {
    if (previousTimestamp == null || !sameUser) return true;

    try {
      final prevTime = DateTime.parse(previousTimestamp);
      final currTime = DateTime.parse(currentTimestamp);

      return currTime.difference(prevTime).inMinutes > 5;
    } catch (e) {
      return true;
    }
  }
}

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

  // Available reactions
  final List<String> _availableReactions = ['❤️', '😂', '👍', '😮', '😢'];

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

  // For reaction popup
  OverlayEntry? _reactionOverlay;

  @override
  void initState() {
    super.initState();
    _fetchRecipientUser();
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
    _removeReactionOverlay();
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
                'reactions':
                    msg['reactions'] ??
                    {'sender_reaction': null, 'recipient_reaction': null},
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
        final timestamp = data['timestamp'];
        final reactions =
            data['reactions'] ??
            {'sender_reaction': null, 'recipient_reaction': null};

        if (from == widget.recipientUserId) {
          setState(() {
            _messages.add({
              'sender_id': from,
              'content': content,
              'timestamp': timestamp ?? DateTime.now().toIso8601String(),
              'reactions': reactions,
            });
            _recipientIsInConversation = true;
          });
          _scrollToBottom();
          _resetRecipientStatus();
        }
      } else if (data['type'] == 'sent') {
        final to = data['to'].toString();
        final content = data['content'];
        final timestamp = data['timestamp'];
        final reactions =
            data['reactions'] ??
            {'sender_reaction': null, 'recipient_reaction': null};

        if (to == widget.recipientUserId) {
          setState(() {
            _messages.add({
              'sender_id': _myUserId,
              'content': content,
              'timestamp': timestamp ?? DateTime.now().toIso8601String(),
              'reactions': reactions,
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
      } else if (data['type'] == 'reaction') {
        // Handle reaction updates with new format
        final senderId = data['sender_id'].toString();
        final timestamp = data['timestamp'];
        final reactions = data['reactions'];

        setState(() {
          final index = _messages.indexWhere(
            (msg) =>
                msg['sender_id'] == senderId && msg['timestamp'] == timestamp,
          );

          if (index != -1) {
            _messages[index]['reactions'] = reactions;
          }
        });
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

  // ---------------------------
  // Send Reaction
  // ---------------------------
  void _sendReaction(Map<String, dynamic> message, String? reaction) {
    if (!_isConnected || _myUserId == null) return;

    final payload = json.encode({
      'type': 'reaction',
      'sender_id': int.parse(message['sender_id']),
      'recipient_id': message['sender_id'] == _myUserId
          ? int.parse(widget.recipientUserId)
          : int.parse(_myUserId!),
      'timestamp': message['timestamp'],
      'reaction': reaction, // null to remove reaction
    });

    _channel?.sink.add(payload);
  }

  // ---------------------------
  // Get user's current reaction
  // ---------------------------
  String? _getUserReaction(Map<String, dynamic> message) {
    final reactions = message['reactions'];
    if (reactions == null) return null;

    final isMe = message['sender_id'].toString() == _myUserId;
    return isMe
        ? reactions['sender_reaction']
        : reactions['recipient_reaction'];
  }

  // ---------------------------
  // Remove Reaction Overlay
  // ---------------------------
  void _removeReactionOverlay() {
    _reactionOverlay?.remove();
    _reactionOverlay = null;
  }

  // ---------------------------
  // Show Reaction Picker (Popup Style)
  // ---------------------------
  void _showReactionPicker(
    BuildContext context,
    Map<String, dynamic> message,
    Offset tapPosition,
  ) {
    _removeReactionOverlay();

    final currentReaction = _getUserReaction(message);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate reaction picker dimensions (5 reactions * 44px + padding)
    const pickerWidth = 280.0;
    const pickerHeight = 60.0;
    const edgePadding = 16.0;

    // Calculate center position
    double left = tapPosition.dx - (pickerWidth / 2);
    double top = tapPosition.dy - pickerHeight - 30;

    // Ensure picker stays within horizontal bounds
    if (left < edgePadding) {
      left = edgePadding;
    } else if (left + pickerWidth > screenWidth - edgePadding) {
      left = screenWidth - pickerWidth - edgePadding;
    }

    // Ensure picker stays within vertical bounds
    if (top < edgePadding + 60) {
      // 60 for app bar
      // Show below the message if no space above
      top = tapPosition.dy + 30;
    }

    // If still overflowing at bottom, adjust
    if (top + pickerHeight > screenHeight - edgePadding - 100) {
      top = screenHeight - pickerHeight - edgePadding - 100;
    }

    _reactionOverlay = OverlayEntry(
      builder: (context) => Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Transparent barrier to close overlay
            Positioned.fill(
              child: GestureDetector(
                onTap: _removeReactionOverlay,
                child: Container(color: Colors.transparent),
              ),
            ),
            // Reaction picker popup with constraints
            Positioned(
              left: left,
              top: top,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: screenWidth - (edgePadding * 2),
                ),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 250),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    // Clamp the value to ensure it stays within valid range
                    final clampedValue = value.clamp(0.0, 1.0);
                    return Transform.scale(
                      scale: 0.5 + (clampedValue * 0.5),
                      child: Opacity(opacity: clampedValue, child: child),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: _availableReactions.map((emoji) {
                        final isSelected = currentReaction == emoji;
                        return GestureDetector(
                          onTap: () {
                            // If tapping the same reaction, remove it
                            if (isSelected) {
                              _sendReaction(message, null);
                            } else {
                              _sendReaction(message, emoji);
                            }
                            _removeReactionOverlay();
                          },
                          child: TweenAnimationBuilder<double>(
                            duration: Duration(
                              milliseconds:
                                  300 +
                                  (_availableReactions.indexOf(emoji) * 50),
                            ),
                            tween: Tween(begin: 0.0, end: 1.0),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value.clamp(0.0, 1.0),
                                child: child,
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.deepPurple.shade100
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_reactionOverlay!);
  }

  // ---------------------------
  // Build Message Item
  // ---------------------------
  Widget _buildMessageItem(int index) {
    final message = _messages[index];
    final isMe = message['sender_id'].toString() != widget.recipientUserId;
    final timestamp = message['timestamp'];
    final reactions = message['reactions'];
    final senderReaction = reactions?['sender_reaction'];
    final recipientReaction = reactions?['recipient_reaction'];
    final hasReactions = senderReaction != null || recipientReaction != null;

    final previousTimestamp = index > 0
        ? _messages[index - 1]['timestamp']
        : null;
    final showDateHeader = TimestampHelper.shouldShowDateHeader(
      previousTimestamp,
      timestamp,
    );

    final previousSender = index > 0 ? _messages[index - 1]['sender_id'] : null;
    final sameUser = previousSender == message['sender_id'];
    final showTime = TimestampHelper.shouldShowTimestamp(
      previousTimestamp,
      timestamp,
      sameUser,
    );

    // Create a GlobalKey for this message bubble
    final GlobalKey messageKey = GlobalKey();

    return Column(
      children: [
        if (showDateHeader)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade300.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                TimestampHelper.formatDateHeader(timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        if (showTime)
          Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 12,
                right: 12,
                top: 8,
                bottom: 4,
              ),
              child: Text(
                TimestampHelper.formatMessageTime(timestamp),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ),
          ),
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onLongPress: () {
                  final RenderBox? box =
                      messageKey.currentContext?.findRenderObject()
                          as RenderBox?;
                  if (box != null) {
                    final Offset position = box.localToGlobal(Offset.zero);
                    _showReactionPicker(
                      context,
                      message,
                      Offset(position.dx + box.size.width / 2, position.dy),
                    );
                  }
                },
                onDoubleTap: () {
                  final RenderBox? box =
                      messageKey.currentContext?.findRenderObject()
                          as RenderBox?;
                  if (box != null) {
                    final Offset position = box.localToGlobal(Offset.zero);
                    _showReactionPicker(
                      context,
                      message,
                      Offset(position.dx + box.size.width / 2, position.dy),
                    );
                  }
                },
                child: Container(
                  key: messageKey,
                  margin: EdgeInsets.only(
                    bottom: 8,
                    top: showTime
                        ? 0
                        : ((index > 0 && !showDateHeader && sameUser) ? 2 : 8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    gradient: isMe
                        ? LinearGradient(
                            colors: [Colors.deepPurple, Colors.blue],
                          )
                        : null,
                    color: isMe ? null : Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(
                        isMe || (sameUser && !showDateHeader && !showTime)
                            ? 20
                            : 4,
                      ),
                      topRight: Radius.circular(
                        !isMe || (sameUser && !showDateHeader && !showTime)
                            ? 20
                            : 4,
                      ),
                      bottomLeft: const Radius.circular(20),
                      bottomRight: const Radius.circular(20),
                    ),
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
                      color: isMe ? Colors.white : Colors.grey.shade800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              // Reaction display below message
              if (hasReactions)
                Padding(
                  padding: EdgeInsets.only(
                    left: isMe ? 0 : 8,
                    right: isMe ? 8 : 0,
                    top: 2,
                    bottom: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isMe && senderReaction != null)
                        Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.deepPurple.shade200,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                senderReaction,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'You',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!isMe && recipientReaction != null)
                        Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.deepPurple.shade200,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                recipientReaction,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'You',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isMe && recipientReaction != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                recipientReaction,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Other',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!isMe && senderReaction != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                senderReaction,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Other',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------
  // UI
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.deepPurple, Colors.blue],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
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
                            _recipientIsInConversation ? 'typing...' : 'Online',
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
                      itemBuilder: (context, index) => _buildMessageItem(index),
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
