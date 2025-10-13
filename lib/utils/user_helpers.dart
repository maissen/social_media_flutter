import 'dart:convert';
import 'package:http/http.dart' as http;
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

Future<SearchUsersResponse> searchUsers(String username) async {
  final url = Uri.parse(
    '${AppConstants.baseApiUrl}/users/search?username=$username',
  );

  try {
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      // Parse the list of users
      final List<Map<String, dynamic>> users = List<Map<String, dynamic>>.from(
        body['data'],
      );

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
