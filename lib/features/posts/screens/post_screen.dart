// lib/features/profile/screens/post_screen.dart
import 'package:flutter/material.dart';
import 'package:demo/utils/posts_helpers.dart';

class PostScreen extends StatefulWidget {
  final String postId;

  const PostScreen({Key? key, required this.postId}) : super(key: key);

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _postData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPost();
  }

  Future<void> _fetchPost() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await getPostById(int.parse(widget.postId));

      if (response.success && response.post != null) {
        setState(() {
          _postData = response.post;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading post: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildMedia() {
    final mediaUrl = _postData!['media_url'];
    const double aspectRatio = 1.0; // Instagram square format

    if (mediaUrl == null || mediaUrl.toString().isEmpty) {
      // Placeholder for posts without an image
      return AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(
          color: Colors.grey[300],
          child: const Icon(
            Icons.image_not_supported_outlined,
            size: 80,
            color: Colors.grey,
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          mediaUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, size: 80, color: Colors.grey),
          ),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : _postData == null
          ? const Center(child: Text('Post not found'))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage:
                              _postData!['user']['profile_picture'] != null
                              ? NetworkImage(
                                  _postData!['user']['profile_picture'],
                                )
                              : null,
                          radius: 24,
                          child: _postData!['user']['profile_picture'] == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _postData!['user']['username'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Media (with placeholder)
                    _buildMedia(),

                    const SizedBox(height: 16),

                    // Content
                    if (_postData!['content'] != null)
                      Text(
                        _postData!['content'],
                        style: const TextStyle(fontSize: 16),
                      ),

                    const SizedBox(height: 16),

                    // Likes and comments count
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.favorite_border),
                            const SizedBox(width: 4),
                            Text(
                              '${_postData!['likes_nbr']} likes',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.comment_outlined),
                            const SizedBox(width: 4),
                            Text(
                              '${_postData!['comments_nbr']} comments',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Text(
                      'Posted on: ${_postData!['created_at']}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
