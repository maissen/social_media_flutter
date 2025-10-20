import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String receiverUserId;

  const ChatScreen({
    Key? key,
    required this.currentUserId,
    required this.receiverUserId,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late IOWebSocketChannel channel;
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    connectWebSocket();
  }

  void connectWebSocket() {
    // Connect to your FastAPI WebSocket
    channel = IOWebSocketChannel.connect(
      Uri.parse('ws://localhost:8000/ws/${widget.currentUserId}'),
    );

    // Listen for incoming messages
    channel.stream.listen((data) {
      final message = json.decode(data);
      if (message['type'] == 'private_message') {
        setState(() {
          messages.add({
            'sender_id': message['sender_id'].toString(),
            'content': message['content'],
          });
        });
      } else if (message['type'] == 'user_list') {
        // You can handle user list updates if needed
        print('Active users: ${message['users']}');
      }
    }, onDone: () {
      print('WebSocket disconnected');
    }, onError: (error) {
      print('WebSocket error: $error');
    });
  }

  void sendMessage(String content) {
    if (content.isEmpty) return;
    final message = {
      'sender_id': int.parse(widget.currentUserId),
      'recipient_id': int.parse(widget.receiverUserId),
      'content': content,
    };
    channel.sink.add(json.encode(message));

    setState(() {
      messages.add({
        'sender_id': widget.currentUserId,
        'content': content,
      });
    });

    _controller.clear();
  }

  @override
  void dispose() {
    channel.sink.close(status.goingAway);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.receiverUserId}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isMe = message['sender_id'] == widget.currentUserId;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blueAccent : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      message['content'],
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                    ),
                    onSubmitted: sendMessage,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
