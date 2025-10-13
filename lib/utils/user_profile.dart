import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http_parser/http_parser.dart';

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
  // print('Fetching user profile for ID: $userId');
  // print('Request URL: $url');

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

class UpdateBioResponse {
  final bool success;
  final String message;
  final String? newBio;

  UpdateBioResponse({
    required this.success,
    required this.message,
    this.newBio,
  });
}

Future<UpdateBioResponse> updateUserBio(String newBio) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token') ?? '';

  final url = Uri.parse('${AppConstants.baseApiUrl}/users/update/bio');

  try {
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'new_bio': newBio}),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return UpdateBioResponse(
        success: true,
        message: body['message'] ?? 'Bio updated successfully',
        newBio: body['data']?['new_bio'],
      );
    } else {
      return UpdateBioResponse(
        success: false,
        message: body['message'] ?? 'Failed to update bio',
      );
    }
  } catch (e) {
    return UpdateBioResponse(success: false, message: 'An error occurred: $e');
  }
}

class UpdateProfilePictureResponse {
  final bool success;
  final String message;
  final String? fileUrl;

  UpdateProfilePictureResponse({
    required this.success,
    required this.message,
    this.fileUrl,
  });
}

Future<UpdateProfilePictureResponse> updateProfilePicture(dynamic file) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token') ?? '';
  final url = Uri.parse(
    '${AppConstants.baseApiUrl}/users/update-profile-picture',
  );

  try {
    var request = http.MultipartRequest('PUT', url);
    request.headers['Authorization'] = 'Bearer $token';

    if (kIsWeb) {
      // For web: `file` must be an XFile from image_picker
      final bytes = await file.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name, // works on web
          contentType: MediaType('image', 'jpeg'), // optional but recommended
        ),
      );
    } else {
      // For mobile: `file` is a dart:io File
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return UpdateProfilePictureResponse(
        success: true,
        message: body['message'] ?? 'Profile picture updated successfully',
        fileUrl: body['data']?['file_url'],
      );
    } else {
      return UpdateProfilePictureResponse(
        success: false,
        message: body['message'] ?? 'Failed to update profile picture',
      );
    }
  } catch (e) {
    return UpdateProfilePictureResponse(
      success: false,
      message: 'An error occurred: $e',
    );
  }
}
