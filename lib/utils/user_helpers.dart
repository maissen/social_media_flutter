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

class ToggleFollowResponse {
  final bool success;
  final String message;
  final bool? isFollowing;

  ToggleFollowResponse({
    required this.success,
    required this.message,
    this.isFollowing,
  });
}

Future<ToggleFollowResponse> toggleFollow({
  required String targetUserId,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token'); // Get logged-in token

  if (token == null) {
    return ToggleFollowResponse(
      success: false,
      message: 'User not authenticated. Please login.',
      isFollowing: null,
    );
  }

  final url = Uri.parse(
    '${AppConstants.baseApiUrl}/users/follow-unfollow?target_user_id=$targetUserId',
  );

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      final isFollowing = body['data']?['is_following'] as bool?;
      return ToggleFollowResponse(
        success: true,
        message: body['message'] ?? 'Follow/unfollow successful',
        isFollowing: isFollowing,
      );
    } else {
      return ToggleFollowResponse(
        success: false,
        message: body['message'] ?? 'Failed to follow/unfollow user',
        isFollowing: null,
      );
    }
  } catch (e) {
    return ToggleFollowResponse(
      success: false,
      message: 'An error occurred: $e',
      isFollowing: null,
    );
  }
}

// Common response class
class FollowListResponse {
  final bool success;
  final String message;
  final List<Map<String, dynamic>>? users;

  FollowListResponse({
    required this.success,
    required this.message,
    this.users,
  });
}

// GET /users/followers?user_id=3
Future<FollowListResponse> getFollowers({required String userId}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  if (token == null) {
    return FollowListResponse(
      success: false,
      message: 'User not authenticated. Please login.',
      users: null,
    );
  }

  final url = Uri.parse(
    '${AppConstants.baseApiUrl}/users/followers?user_id=$userId',
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
      List<Map<String, dynamic>> users = List<Map<String, dynamic>>.from(
        body['data'],
      );

      // Normalize user_id to String for all users
      users = users.map((user) {
        user['user_id'] = user['user_id']?.toString();
        return user;
      }).toList();

      return FollowListResponse(
        success: true,
        message: body['message'] ?? 'Followers retrieved successfully',
        users: users,
      );
    } else {
      return FollowListResponse(
        success: false,
        message: body['message'] ?? 'Failed to fetch followers',
        users: null,
      );
    }
  } catch (e) {
    return FollowListResponse(
      success: false,
      message: 'An error occurred: $e',
      users: null,
    );
  }
}

// GET /users/followings?user_id=3
Future<FollowListResponse> getFollowings({required String userId}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  if (token == null) {
    return FollowListResponse(
      success: false,
      message: 'User not authenticated. Please login.',
      users: null,
    );
  }

  final url = Uri.parse(
    '${AppConstants.baseApiUrl}/users/followings?user_id=$userId',
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
      List<Map<String, dynamic>> users = List<Map<String, dynamic>>.from(
        body['data'],
      );

      // Normalize user_id to String for all users
      users = users.map((user) {
        user['user_id'] = user['user_id']?.toString();
        return user;
      }).toList();

      return FollowListResponse(
        success: true,
        message: body['message'] ?? 'Following list retrieved successfully',
        users: users,
      );
    } else {
      return FollowListResponse(
        success: false,
        message: body['message'] ?? 'Failed to fetch followings',
        users: null,
      );
    }
  } catch (e) {
    return FollowListResponse(
      success: false,
      message: 'An error occurred: $e',
      users: null,
    );
  }
}

class NotificationsResponse {
  final bool success;
  final String message;
  final List<Map<String, dynamic>>? notifications;

  NotificationsResponse({
    required this.success,
    required this.message,
    this.notifications,
  });
}

Future<NotificationsResponse> fetchNotifications({
  required String userId,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token'); // Get token

  if (token == null) {
    return NotificationsResponse(
      success: false,
      message: 'User not authenticated. Please login.',
      notifications: null,
    );
  }

  final url = Uri.parse(
    '${AppConstants.baseApiUrl}/notifications?user_id=$userId',
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
      List<Map<String, dynamic>> notifications =
          List<Map<String, dynamic>>.from(body['data']);

      return NotificationsResponse(
        success: true,
        message: body['message'] ?? 'Notifications retrieved successfully',
        notifications: notifications,
      );
    } else {
      return NotificationsResponse(
        success: false,
        message: body['message'] ?? 'Failed to fetch notifications',
        notifications: null,
      );
    }
  } catch (e) {
    return NotificationsResponse(
      success: false,
      message: 'An error occurred: $e',
      notifications: null,
    );
  }
}
