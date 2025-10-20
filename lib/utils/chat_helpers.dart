import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:demo/config/constants.dart';
import 'package:demo/utils/auth_helpers.dart';

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
/// Automatically uses the saved access token
/// --------------------------
Future<List<UserProfileSimplified>> getMyConversations() async {
  final token = await getAccessToken();

  if (token == null) {
    throw Exception("No access token found. Please login first.");
  }

  final url = chatApiBase.replace(path: '${chatApiBase.path}/my_conversations');

  final response = await http.get(
    url,
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data
        .map(
          (user) =>
              UserProfileSimplified.fromJson(user as Map<String, dynamic>),
        )
        .toList();
  } else {
    throw Exception(
      "Failed to fetch contacts: ${response.statusCode} ${response.body}",
    );
  }
}

class UserProfileSimplified {
  final int userId;
  final String email;
  final String username;
  final String? profilePicture;
  final bool isFollowing;

  UserProfileSimplified({
    required this.userId,
    required this.email,
    required this.username,
    this.profilePicture,
    required this.isFollowing,
  });

  factory UserProfileSimplified.fromJson(Map<String, dynamic> json) {
    return UserProfileSimplified(
      userId: json['user_id'] as int,
      email: json['email'] as String,
      username: json['username'] as String,
      profilePicture: (json['profile_picture'] as String).isNotEmpty
          ? json['profile_picture'] as String
          : null,
      isFollowing: json['is_following'] as bool,
    );
  }
}
