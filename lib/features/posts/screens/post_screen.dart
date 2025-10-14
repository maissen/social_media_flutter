import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final TextEditingController _commentController = TextEditingController();
  int? _loggedInUserId;

  @override
  void initState() {
    super.initState();
    _loadLoggedInUser();
  }

  Future<void> _loadLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userIdStr = prefs.getString('user_id');
    if (userIdStr != null) {
      _loggedInUserId = int.tryParse(userIdStr);
    }
    _fetchPost();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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
    const double aspectRatio = 1.0;

    if (mediaUrl == null || mediaUrl.toString().isEmpty) {
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

  void _showUpdateDialog() {
    final TextEditingController _updateController = TextEditingController(
      text: _postData!['content'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Post'),
          content: TextField(
            controller: _updateController,
            maxLines: null,
            decoration: const InputDecoration(hintText: 'Edit your post...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _postData!['content'] = _updateController.text;
                });
                Navigator.pop(context);
                // TODO: call API to update post content
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Post'),
          content: const Text('Are you sure you want to delete this post?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: call API to delete post
                print('Delete post clicked');
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
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
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User info + menu button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage:
                                      _postData!['user']['profile_picture'] !=
                                          null
                                      ? NetworkImage(
                                          _postData!['user']['profile_picture'],
                                        )
                                      : null,
                                  radius: 24,
                                  child:
                                      _postData!['user']['profile_picture'] ==
                                          null
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
                            // Menu button for owner
                            if (_loggedInUserId != null &&
                                _postData!['user']['user_id'] ==
                                    _loggedInUserId)
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'update') {
                                    _showUpdateDialog();
                                  } else if (value == 'delete') {
                                    _showDeleteDialog();
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'update',
                                    child: Text('Update Post'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete Post'),
                                  ),
                                ],
                                icon: const Icon(Icons.more_vert),
                              ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        _buildMedia(),

                        const SizedBox(height: 16),

                        if (_postData!['content'] != null)
                          Text(
                            _postData!['content'],
                            style: const TextStyle(fontSize: 16),
                          ),

                        const SizedBox(height: 16),

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
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Comment input
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey[300]!)),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_emotions_outlined),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                              hintText: 'Add a comment...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.blue),
                          onPressed: () {
                            if (_commentController.text.isNotEmpty) {
                              print(
                                'Comment typed: ${_commentController.text}',
                              );
                              _commentController.clear();
                              // TODO: call API to add comment
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
