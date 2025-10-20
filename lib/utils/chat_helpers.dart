import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:demo/config/constants.dart';

/// Base API URL for chat
final Uri chatApiBase = Uri.parse('${AppConstants.baseApiUrl}/chat');

/// --------------------------
/// Send a chat message
/// --------------------------
Future<Map<String, dynamic>> sendChatMessage({
  required String token,
  required int recipientId,
  required String content,
}) async {
  final url = chatApiBase.replace(path: '${chatApiBase.path}/send');

  final response = await http.post(
    url,
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({"recipient_id": recipientId, "content": content}),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  } else {
    throw Exception(
      "Failed to send chat message: ${response.statusCode} ${response.body}",
    );
  }
}

/// --------------------------
/// Fetch conversation with a specific recipient
/// --------------------------
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

/// --------------------------
/// Fetch all conversations of the current user
/// --------------------------
Future<List<Map<String, dynamic>>> getMyConversations({
  required String token,
}) async {
  final url = chatApiBase.replace(path: '${chatApiBase.path}/my_conversations');

  final response = await http.get(
    url,
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data);
  } else {
    throw Exception(
      "Failed to fetch my conversations: ${response.statusCode} ${response.body}",
    );
  }
}
