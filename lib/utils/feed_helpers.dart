import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class Post {
  final int postId;
  final int userId;
  final String content;
  final String mediaUrl;
  final DateTime createdAt;
  final int likesNbr;
  final int commentsNbr;
  final bool isLikedByMe;

  Post({
    required this.postId,
    required this.userId,
    required this.content,
    required this.mediaUrl,
    required this.createdAt,
    required this.likesNbr,
    required this.commentsNbr,
    required this.isLikedByMe,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      postId: json['post_id'],
      userId: json['user_id'],
      content: json['content'],
      mediaUrl: json['media_url'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      likesNbr: json['likes_nbr'],
      commentsNbr: json['comments_nbr'],
      isLikedByMe: json['is_liked_by_me'],
    );
  }
}

Future<List<Post>> fetchUserFeed() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  if (token == null) throw Exception('No access token found');

  final url = Uri.parse('${AppConstants.baseApiUrl}/feed/');

  try {
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      List<Post> posts = (body['data'] as List)
          .map((postJson) => Post.fromJson(postJson))
          .toList();
      return posts;
    } else {
      throw Exception(body['message'] ?? 'Failed to fetch user feed');
    }
  } catch (e) {
    throw Exception('Error fetching user feed: $e');
  }
}

Future<List<Post>> fetchExploreFeed() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  if (token == null) throw Exception('No access token found');

  final url = Uri.parse('${AppConstants.baseApiUrl}/feed/explore');

  try {
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body['success'] == true) {
      List<Post> posts = (body['data'] as List)
          .map((postJson) => Post.fromJson(postJson))
          .toList();
      return posts;
    } else {
      throw Exception(body['message'] ?? 'Failed to fetch explore feed');
    }
  } catch (e) {
    throw Exception('Error fetching explore feed: $e');
  }
}
