import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class CreatePostResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? post;

  CreatePostResponse({required this.success, required this.message, this.post});
}

Future<CreatePostResponse> createPost({
  String? content,
  File? mediaFile,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token'); // Get token

  if (token == null) {
    return CreatePostResponse(
      success: false,
      message: 'User not authenticated. Please login.',
      post: null,
    );
  }

  final url = Uri.parse('${AppConstants.baseApiUrl}/posts/create');

  try {
    // Use MultipartRequest to handle file upload
    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $token';

    // Add text field if provided
    if (content != null && content.isNotEmpty) {
      request.fields['content'] = content;
    }

    // Add media file if provided
    if (mediaFile != null && await mediaFile.exists()) {
      final mediaStream = http.MultipartFile.fromBytes(
        'media_file',
        await mediaFile.readAsBytes(),
        filename: mediaFile.path.split('/').last,
      );
      request.files.add(mediaStream);
    }

    // Send request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final body = jsonDecode(response.body);

    if (response.statusCode == 201 && body['success'] == true) {
      return CreatePostResponse(
        success: true,
        message: body['message'] ?? 'Post created successfully',
        post: body['data'],
      );
    } else {
      return CreatePostResponse(
        success: false,
        message: body['message'] ?? 'Failed to create post',
        post: null,
      );
    }
  } catch (e) {
    return CreatePostResponse(
      success: false,
      message: 'An error occurred: $e',
      post: null,
    );
  }
}

class GetPostResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? post;

  GetPostResponse({required this.success, required this.message, this.post});
}

Future<GetPostResponse> getPostById(int postId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token'); // Retrieve stored token

  if (token == null) {
    return GetPostResponse(
      success: false,
      message: 'User not authenticated. Please login.',
      post: null,
    );
  }

  final url = Uri.parse('${AppConstants.baseApiUrl}/posts/get?post_id=$postId');

  try {
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return GetPostResponse(
        success: true,
        message: body['message'] ?? 'Post retrieved successfully',
        post: body['data'],
      );
    } else {
      return GetPostResponse(
        success: false,
        message: body['message'] ?? 'Failed to retrieve post',
        post: null,
      );
    }
  } catch (e) {
    return GetPostResponse(
      success: false,
      message: 'An error occurred: $e',
      post: null,
    );
  }
}

class UpdatePostResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  UpdatePostResponse({required this.success, required this.message, this.data});
}

class DeletePostResponse {
  final bool success;
  final String message;

  DeletePostResponse({required this.success, required this.message});
}

/// Update a post's text content
Future<UpdatePostResponse> updatePost({
  required int postId,
  required String newContent,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  if (token == null) {
    return UpdatePostResponse(
      success: false,
      message: 'User not authenticated. Please login.',
      data: null,
    );
  }

  final url = Uri.parse('${AppConstants.baseApiUrl}/posts/update/$postId');

  try {
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'new_content': newContent}),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return UpdatePostResponse(
        success: true,
        message: body['message'] ?? 'Post updated successfully',
        data: body['data'],
      );
    } else {
      return UpdatePostResponse(
        success: false,
        message: body['message'] ?? 'Failed to update post',
        data: null,
      );
    }
  } catch (e) {
    return UpdatePostResponse(
      success: false,
      message: 'An error occurred: $e',
      data: null,
    );
  }
}

/// Delete a post
Future<DeletePostResponse> deletePost({required int postId}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  if (token == null) {
    return DeletePostResponse(
      success: false,
      message: 'User not authenticated. Please login.',
    );
  }

  final url = Uri.parse('${AppConstants.baseApiUrl}/posts/delete/$postId');

  try {
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return DeletePostResponse(
        success: true,
        message: body['message'] ?? 'Post deleted successfully',
      );
    } else {
      return DeletePostResponse(
        success: false,
        message: body['message'] ?? 'Failed to delete post',
      );
    }
  } catch (e) {
    return DeletePostResponse(success: false, message: 'An error occurred: $e');
  }
}

class LikePostResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  LikePostResponse({required this.success, required this.message, this.data});
}

class GetLikesResponse {
  final bool success;
  final String message;
  final List<Map<String, dynamic>>? data;

  GetLikesResponse({required this.success, required this.message, this.data});
}

/// Like or dislike a post
Future<LikePostResponse> likeOrDislikePost({required int postId}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  if (token == null) {
    return LikePostResponse(
      success: false,
      message: 'User not authenticated',
      data: null,
    );
  }

  final url = Uri.parse(
    '${AppConstants.baseApiUrl}/posts/like-deslike/$postId',
  );

  try {
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      return LikePostResponse(
        success: true,
        message: body['message'] ?? 'Post liked/disliked successfully',
        data: body['data'],
      );
    } else {
      return LikePostResponse(
        success: false,
        message: body['message'] ?? 'Failed to like/dislike post',
        data: null,
      );
    }
  } catch (e) {
    return LikePostResponse(
      success: false,
      message: 'An error occurred: $e',
      data: null,
    );
  }
}

/// Get likes of a post
Future<GetLikesResponse> getPostLikes({required int postId}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  if (token == null) {
    return GetLikesResponse(
      success: false,
      message: 'User not authenticated',
      data: null,
    );
  }

  final url = Uri.parse(
    '${AppConstants.baseApiUrl}/posts/likes?post_id=$postId',
  );

  try {
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      List<Map<String, dynamic>> likesList = [];
      if (body['data'] != null) {
        likesList = List<Map<String, dynamic>>.from(body['data']);
      }

      return GetLikesResponse(
        success: true,
        message: body['message'] ?? 'Likes fetched successfully',
        data: likesList,
      );
    } else {
      return GetLikesResponse(
        success: false,
        message: body['message'] ?? 'Failed to retrieve likes',
        data: null,
      );
    }
  } catch (e) {
    return GetLikesResponse(
      success: false,
      message: 'An error occurred: $e',
      data: null,
    );
  }
}
