import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class UserProfile {
  final String userId;
  final String email;
  final String username;
  final String bio;
  final String profilePicture;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool isFollowing;

  UserProfile({
    required this.userId,
    required this.email,
    required this.username,
    required this.bio,
    required this.profilePicture,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    required this.isFollowing,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id']?.toString() ?? '', // Convert to string
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      bio: json['bio'] ?? '',
      profilePicture: json['profile_picture'] ?? '',
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
      postsCount: json['posts_count'] ?? 0,
      isFollowing: json['is_following'] ?? false,
    );
  }
}

/// Fetch user profile by ID
Future<UserProfile> fetchUserProfile(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token') ?? '';

  final url = Uri.parse('${AppConstants.baseApiUrl}/users/profile/$userId');

  // Debug print
  print('Fetching user profile for ID: $userId');
  print('Request URL: $url');

  final response = await http.get(
    url,
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = json.decode(response.body);
    if (data['success'] == true) {
      return UserProfile.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Failed to load profile');
    }
  } else {
    throw Exception(
      'Failed to fetch user profile. Status: ${response.statusCode}',
    );
  }
}
