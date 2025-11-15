import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class Post {
  final int postId;
  final int userId;
  String content;
  final String mediaUrl;
  final DateTime createdAt;
  final int likesNbr;
  final int commentsNbr;
  final bool isLikedByMe;
  final List<dynamic> categories;
  final List<List<dynamic>>? categoryObjects;

  Post({
    required this.postId,
    required this.userId,
    required this.content,
    required this.mediaUrl,
    required this.createdAt,
    required this.likesNbr,
    required this.commentsNbr,
    required this.isLikedByMe,
    required this.categories,
    this.categoryObjects,
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
      categories: json['categories'] ?? [],
      categoryObjects: json['category_objects'] != null
          ? List<List<dynamic>>.from(
              (json['category_objects'] as List).map(
                (item) => List<dynamic>.from(item),
              ),
            )
          : null,
    );
  }

  /// Helper method to get category names
  List<String> getCategoryNames() {
    if (categoryObjects == null || categoryObjects!.isEmpty) return [];
    return categoryObjects!.map((cat) => cat[1] as String).toList();
  }

  /// Helper method to check if post has a specific category
  bool hasCategory(int categoryId) {
    return categories.contains(categoryId);
  }

  /// Helper method to check if post has any of the given categories
  bool hasAnyCategory(List<int> categoryIds) {
    if (categoryIds.isEmpty) return true;
    return categoryIds.any((categoryId) => categories.contains(categoryId));
  }
}

/// Fetch user feed with optional category filter
///
/// [categoryId] - Optional category ID to filter posts. Pass null for all posts.
///
/// Example:
/// ```dart
/// // Get all posts
/// final allPosts = await fetchUserFeed();
///
/// // Get posts from AI category (ID: 16)
/// final aiPosts = await fetchUserFeed(categoryId: 16);
/// ```
Future<List<Post>> fetchUserFeed({int? categoryId}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  if (token == null) throw Exception('No access token found');

  // Build URL with optional category parameter
  String urlString = '${AppConstants.baseApiUrl}/feed/';
  if (categoryId != null) {
    urlString += '?category_id=$categoryId';
  }

  final url = Uri.parse(urlString);

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

      // Client-side filtering as backup (in case API doesn't support filtering)
      if (categoryId != null) {
        posts = posts.where((post) => post.hasCategory(categoryId)).toList();
      }

      return posts;
    } else {
      throw Exception(body['message'] ?? 'Failed to fetch user feed');
    }
  } catch (e) {
    throw Exception('Error fetching user feed: $e');
  }
}

/// Fetch explore feed with optional category filter
///
/// [categoryId] - Optional category ID to filter posts. Pass null for all posts.
///
/// Example:
/// ```dart
/// // Get all explore posts
/// final allPosts = await fetchExploreFeed();
///
/// // Get explore posts from Gaming category (ID: 18)
/// final gamingPosts = await fetchExploreFeed(categoryId: 18);
/// ```
Future<List<Post>> fetchExploreFeed({int? categoryId}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  if (token == null) throw Exception('No access token found');

  // Build URL with optional category parameter
  String urlString = '${AppConstants.baseApiUrl}/feed/explore';
  if (categoryId != null) {
    urlString += '?category_id=$categoryId';
  }

  final url = Uri.parse(urlString);

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

      // Client-side filtering as backup (in case API doesn't support filtering)
      if (categoryId != null) {
        posts = posts.where((post) => post.hasCategory(categoryId)).toList();
      }

      return posts;
    } else {
      throw Exception(body['message'] ?? 'Failed to fetch explore feed');
    }
  } catch (e) {
    throw Exception('Error fetching explore feed: $e');
  }
}

/// Filter posts by multiple categories (client-side filtering)
///
/// [posts] - List of posts to filter
/// [categoryIds] - List of category IDs. Posts matching ANY of these categories will be returned.
///
/// Example:
/// ```dart
/// final allPosts = await fetchUserFeed();
/// final filteredPosts = filterPostsByCategories(allPosts, [16, 17, 18]); // AI, Art, Gaming
/// ```
List<Post> filterPostsByCategories(List<Post> posts, List<int> categoryIds) {
  if (categoryIds.isEmpty) return posts;

  return posts.where((post) {
    // Check if post has ANY of the selected categories
    return categoryIds.any((categoryId) => post.hasCategory(categoryId));
  }).toList();
}

/// Filter posts by single category (client-side filtering)
///
/// [posts] - List of posts to filter
/// [categoryId] - Category ID to filter by
///
/// Example:
/// ```dart
/// final allPosts = await fetchUserFeed();
/// final aiPosts = filterPostsByCategory(allPosts, 16); // Only AI posts
/// ```
List<Post> filterPostsByCategory(List<Post> posts, int categoryId) {
  return posts.where((post) => post.hasCategory(categoryId)).toList();
}

/// Get all unique categories from a list of posts
///
/// Returns a list of [categoryId, categoryName] pairs
///
/// Example:
/// ```dart
/// final posts = await fetchUserFeed();
/// final categories = getUniqueCategoriesFromPosts(posts);
/// // Result: [[16, "🤖 Artificial Intelligence"], [17, "🎨 Art"], ...]
/// ```
List<List<dynamic>> getUniqueCategoriesFromPosts(List<Post> posts) {
  final Map<int, String> categoryMap = {};

  for (final post in posts) {
    if (post.categoryObjects != null) {
      for (final category in post.categoryObjects!) {
        if (category.length >= 2) {
          final id = category[0] as int;
          final name = category[1] as String;
          categoryMap[id] = name;
        }
      }
    }
  }

  return categoryMap.entries.map((entry) => [entry.key, entry.value]).toList()
    ..sort((a, b) => (a[1] as String).compareTo(b[1] as String));
}

/// Sort posts by different criteria
enum PostSortType {
  newest, // Most recent first
  oldest, // Oldest first
  mostLiked, // Most likes first
  mostCommented, // Most comments first
}

/// Sort posts by the specified criteria
///
/// Example:
/// ```dart
/// final posts = await fetchUserFeed();
/// final sortedPosts = sortPosts(posts, PostSortType.mostLiked);
/// ```
List<Post> sortPosts(List<Post> posts, PostSortType sortType) {
  final sortedPosts = List<Post>.from(posts);

  switch (sortType) {
    case PostSortType.newest:
      sortedPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      break;
    case PostSortType.oldest:
      sortedPosts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      break;
    case PostSortType.mostLiked:
      sortedPosts.sort((a, b) => b.likesNbr.compareTo(a.likesNbr));
      break;
    case PostSortType.mostCommented:
      sortedPosts.sort((a, b) => b.commentsNbr.compareTo(a.commentsNbr));
      break;
  }

  return sortedPosts;
}
