import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demo/utils/posts_helpers.dart';
import 'package:timeago/timeago.dart' as timeago;

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
          CommentInput(
            controller: _commentController,
            postId: postResponse.post?['post_id'],
          ),
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

  void _showCommentsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsBottomSheet(postId: postId),
    );
  }

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
                GestureDetector(
                  onTap: () => _showCommentsBottomSheet(context),
                  child: Text(
                    '$commentsNbr comments',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.blue, // optional: make it look tappable
                      decoration: TextDecoration.underline, // optional
                    ),
                  ),
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

//! comment widgets
class CommentsBottomSheet extends StatefulWidget {
  final int postId;

  const CommentsBottomSheet({super.key, required this.postId});

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>>? comments;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  void _loadComments() async {
    final response = await getCommentsOfPost(postId: widget.postId);

    if (response.success && response.data != null) {
      setState(() {
        comments = response.data;
      });
    } else {
      setState(() {
        comments = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.85;

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // --- Drag handle ---
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const Text(
            'Comments',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // --- Comments list ---
          Expanded(
            child: comments == null || comments!.isEmpty
                ? const Center(child: Text('No comments yet'))
                : ListView.builder(
                    itemCount: comments!.length,
                    itemBuilder: (context, index) {
                      final comment = comments![index];
                      final username =
                          comment['username'] ??
                          comment['user']?['username'] ??
                          'Unknown';
                      final profilePic =
                          comment['profile_picture'] ??
                          comment['user']?['profile_picture'] ??
                          '';
                      final text = comment['comment_payload'] ?? '';
                      final createdAt = comment['created_at'] ?? '';
                      final isLiked = comment['is_liked_by_me'] ?? false;
                      final likes = comment['likes_nbr'] ?? 0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile picture
                            CircleAvatar(
                              radius: 18,
                              backgroundImage: profilePic.isNotEmpty
                                  ? NetworkImage(profilePic)
                                  : null,
                              backgroundColor: Colors.grey[300],
                            ),
                            const SizedBox(width: 10),

                            // Comment content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '$username ',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TextSpan(text: text),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        createdAt.isNotEmpty
                                            ? timeago.format(
                                                DateTime.parse(createdAt),
                                                locale: 'en_short',
                                              )
                                            : '',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (likes > 0)
                                        Text(
                                          '$likes likes',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Like button
                            IconButton(
                              onPressed: () async {
                                final response = await likeOrDislikeComment(
                                  commentId: comment['comment_id'],
                                );

                                if (response.success && response.data != null) {
                                  setState(() {
                                    final wasLiked =
                                        comment['is_liked_by_me'] ?? false;
                                    comment['is_liked_by_me'] = !wasLiked;

                                    final likes = comment['likes_nbr'] ?? 0;
                                    comment['likes_nbr'] = wasLiked
                                        ? likes - 1
                                        : likes + 1;
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(response.message)),
                                  );
                                }
                              },
                              icon: Icon(
                                comment['is_liked_by_me'] == true
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: comment['is_liked_by_me'] == true
                                    ? Colors.red
                                    : Colors.grey,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class CommentInput extends StatelessWidget {
  final TextEditingController controller;
  final int postId;
  final VoidCallback? onCommentAdded; // callback to refresh UI after comment

  const CommentInput({
    Key? key,
    required this.controller,
    required this.postId,
    this.onCommentAdded,
  }) : super(key: key);

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
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText:
                      'Add a comment ${postResponse.post?['username'] ?? '...'}',
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blue),
              onPressed: () async {
                final content = controller.text.trim();
                if (content.isNotEmpty) {
                  FocusScope.of(context).unfocus(); // hide keyboard

                  final response = await createComment(
                    postId: postId,
                    content: content,
                  );

                  if (response.success) {
                    controller.clear();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Comment added!')),
                    );

                    // 🔥 Notify parent to refresh the comment count or list
                    if (onCommentAdded != null) {
                      onCommentAdded!();
                    }
                  } else {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(response.message)));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

//! likes widgets

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

  /// Fetch likes of the post and check if the user has liked it
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

  /// Show likes bottom sheet
  void _onLikesCountTap() {
    if (likesCount > 0) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => LikesBottomSheet(postId: widget.postId),
      );
    }
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
        // Likes count triggers bottom sheet
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

/// Instagram-style likes bottom sheet
class LikesBottomSheet extends StatefulWidget {
  final int postId;

  const LikesBottomSheet({Key? key, required this.postId}) : super(key: key);

  @override
  State<LikesBottomSheet> createState() => _LikesBottomSheetState();
}

class _LikesBottomSheetState extends State<LikesBottomSheet> {
  List<dynamic> likes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLikes();
  }

  Future<void> _fetchLikes() async {
    final response = await getPostLikes(postId: widget.postId);
    if (response.success && response.data != null) {
      setState(() {
        likes = response.data!;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Drag indicator
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Likes',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : likes.isEmpty
                ? const Center(child: Text('No likes yet'))
                : ListView.builder(
                    itemCount: likes.length,
                    itemBuilder: (context, index) {
                      final like = likes[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(
                            like['profile_picture'] ?? '',
                          ),
                        ),
                        title: Text(like['username'] ?? ''),
                        subtitle: Text(like['email'] ?? ''),
                        trailing: like['is_following'] == true
                            ? const Text(
                                'Following',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
