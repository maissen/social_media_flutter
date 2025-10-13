import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class SearchUsersResponse {
  final bool success;
  final String message;
  final List<Map<String, dynamic>>? users;

  SearchUsersResponse({
    required this.success,
    required this.message,
    this.users,
  });
}

Future<SearchUsersResponse> searchUsers({required String username}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token'); // Retrieve token
  final loggedInUserId = prefs.getString('user_id'); // Retrieve current user ID

  if (token == null || loggedInUserId == null) {
    return SearchUsersResponse(
      success: false,
      message: 'User not authenticated. Please login.',
      users: null,
    );
  }

  final url = Uri.parse(
    '${AppConstants.baseApiUrl}/users/search?username=$username',
  );

  try {
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Add Bearer token
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      List<Map<String, dynamic>> users = List<Map<String, dynamic>>.from(
        body['data'],
      );

      // Exclude the currently logged-in user (normalize strings)
      users = users.where((user) {
        final apiUserId = user['user_id'].toString().trim();
        final currentUserId = loggedInUserId.toString().trim();
        return apiUserId != currentUserId;
      }).toList();

      return SearchUsersResponse(
        success: true,
        message: body['message'] ?? 'Users retrieved successfully',
        users: users,
      );
    } else {
      return SearchUsersResponse(
        success: false,
        message: body['message'] ?? 'Failed to fetch users',
        users: null,
      );
    }
  } catch (e) {
    return SearchUsersResponse(
      success: false,
      message: 'An error occurred: $e',
      users: null,
    );
  }
}
