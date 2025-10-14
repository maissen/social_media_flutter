import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demo/utils/posts_helpers.dart';

// Global variable accessible anywhere in this file
late GetPostResponse postResponse;

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
    if (userIdStr != null) _loggedInUserId = int.tryParse(userIdStr);
    _fetchPost();
  }

  Future<void> _fetchPost() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      postResponse = await getPostById(int.parse(widget.postId));

      if (postResponse.success && postResponse.post != null) {
        setState(() {
          _postData = postResponse.post!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = postResponse.message;
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

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_errorMessage != null)
      return Scaffold(body: Center(child: Text(_errorMessage!)));
    if (_postData == null)
      return const Scaffold(body: Center(child: Text('Post not found')));

    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: PostContent(
                postData: _postData!,
                loggedInUserId: _loggedInUserId,
                onUpdate: (updatedPost) {
                  setState(() => _postData = updatedPost);
                },
                onDelete: () => Navigator.pop(context),
              ),
            ),
          ),
          CommentInput(controller: _commentController),
        ],
      ),
    );
  }
}

class PostContent extends StatelessWidget {
  final Map<String, dynamic> postData;
  final int? loggedInUserId;
  final ValueChanged<Map<String, dynamic>> onUpdate;
  final VoidCallback onDelete;

  const PostContent({
    Key? key,
    required this.postData,
    required this.loggedInUserId,
    required this.onUpdate,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PostHeader(
          postData: postData,
          loggedInUserId: loggedInUserId,
          onUpdate: onUpdate,
          onDelete: onDelete,
        ),
        const SizedBox(height: 16),
        PostMedia(mediaUrl: postData['media_url']),
        const SizedBox(height: 16),
        if (postData['content'] != null)
          Text(postData['content'], style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 16),
        _PostActions(
          postId: postData['post_id'],
          likesNbr: postData['likes_nbr'] ?? 0,
          isLikedByMe: postData['is_liked_by_me'] ?? false,
          commentsNbr: postData['comments_nbr'] ?? 0,
          createdAt: postData['created_at'],
        ),
      ],
    );
  }
}

class _PostHeader extends StatelessWidget {
  final Map<String, dynamic> postData;
  final int? loggedInUserId;
  final ValueChanged<Map<String, dynamic>> onUpdate;
  final VoidCallback onDelete;

  const _PostHeader({
    Key? key,
    required this.postData,
    required this.loggedInUserId,
    required this.onUpdate,
    required this.onDelete,
  }) : super(key: key);

  void _showUpdateDialog(BuildContext context) {
    final controller = TextEditingController(text: postData['content'] ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Update Post'),
        content: TextField(
          controller: controller,
          maxLines: null,
          maxLength: 100,
          decoration: const InputDecoration(
            hintText: 'Edit your post...',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newContent = controller.text.trim();
              if (newContent.isEmpty) return;
              Navigator.pop(context);
              final response = await updatePost(
                postId: postData['post_id'],
                newContent: newContent,
              );
              if (response.success && response.data != null) {
                final updatedPost = Map<String, dynamic>.from(postData);
                updatedPost['content'] = response.data!['new_content'];
                onUpdate(updatedPost);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post updated successfully!')),
                );
              } else {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(response.message)));
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final response = await deletePost(postId: postData['post_id']);
              if (response.success) {
                onDelete();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(response.message)));
              } else {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(response.message)));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwner =
        loggedInUserId != null && postData['user']['user_id'] == loggedInUserId;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundImage: postData['user']['profile_picture'] != null
                  ? NetworkImage(postData['user']['profile_picture'])
                  : null,
              radius: 24,
              child: postData['user']['profile_picture'] == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              postData['user']['username'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        if (isOwner)
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'update') _showUpdateDialog(context);
              if (value == 'delete') _showDeleteDialog(context);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'update', child: Text('Update Post')),
              PopupMenuItem(value: 'delete', child: Text('Delete Post')),
            ],
            icon: const Icon(Icons.more_vert),
          ),
      ],
    );
  }
}

class PostMedia extends StatelessWidget {
  final String? mediaUrl;
  const PostMedia({Key? key, this.mediaUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double aspectRatio = 1.0;
    if (mediaUrl == null || mediaUrl!.isEmpty) {
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
          mediaUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) => Container(
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
}

class _PostActions extends StatelessWidget {
  final int postId;
  final int likesNbr;
  final bool isLikedByMe;
  final int commentsNbr;
  final String createdAt;

  const _PostActions({
    Key? key,
    required this.postId,
    required this.likesNbr,
    required this.isLikedByMe,
    required this.commentsNbr,
    required this.createdAt,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            LikeButton(postId: postId),
            Row(
              children: [
                const Icon(Icons.comment_outlined),
                const SizedBox(width: 4),
                Text(
                  '$commentsNbr comments',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Posted on: $createdAt',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }
}

class CommentInput extends StatelessWidget {
  final TextEditingController controller;
  const CommentInput({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Add a comment...',
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blue),
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  controller.clear();
                  // TODO: call API to add comment
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class LikeButton extends StatefulWidget {
  final int postId;

  const LikeButton({Key? key, required this.postId}) : super(key: key);

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  int likesCount = 0;
  bool isLiked = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLikes();
  }

  Future<void> _fetchLikes() async {
    setState(() => _isLoading = true);

    final response = await getPostLikes(postId: widget.postId);

    if (response.success && response.data != null) {
      final prefs = await SharedPreferences.getInstance();
      final currentUserEmail = prefs.getString('email');

      final likesList = response.data!;
      final userHasLiked = likesList.any(
        (like) => like['email'] != null && like['email'] == currentUserEmail,
      );

      setState(() {
        likesCount = likesList.length;
        isLiked = userHasLiked;
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
    }

    setState(() => _isLoading = false);
  }

  /// Toggle like/unlike when heart is tapped
  Future<void> _toggleLike() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final response = await likeOrDislikePost(postId: widget.postId);

    if (response.success) {
      await _fetchLikes();
      postResponse.post?['is_liked_by_me'] =
          !postResponse.post?['is_liked_by_me'];
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      setState(() => _isLoading = false);
    }
  }

  /// Function to run when likes count text is clicked
  void _onLikesCountTap() {
    // Example: Navigate to list of users who liked
    print('Likes count clicked! Show list of users who liked.');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Heart icon toggles like
        InkWell(
          onTap: _toggleLike,
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  postResponse.post?['is_liked_by_me']
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: postResponse.post?['is_liked_by_me']
                      ? Colors.red
                      : Colors.grey,
                ),
        ),
        const SizedBox(width: 4),
        // Likes count triggers a different function
        RichText(
          text: TextSpan(
            text: '$likesCount likes',
            style: const TextStyle(fontSize: 14, color: Colors.blue),
            recognizer: TapGestureRecognizer()..onTap = _onLikesCountTap,
          ),
        ),
      ],
    );
  }
}
