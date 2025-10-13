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
