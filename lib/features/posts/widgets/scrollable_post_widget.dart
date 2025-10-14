import 'package:demo/utils/posts_helpers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demo/utils/feed_helpers.dart'; // Post model
import 'package:demo/utils/user_helpers.dart'; // fetchUserProfile
import 'package:demo/utils/user_profile.dart';
import 'package:demo/features/profile/screens/profile_screen.dart';
import 'package:demo/features/posts/widgets/comments_bottom_sheet_widget.dart';

class PostWidget extends StatefulWidget {
  final Post post;
  final Function(String postId)? onDelete; // optional callback for delete
  final Function(String postId)? onUpdate; // optional callback for update

  const PostWidget({Key? key, required this.post, this.onDelete, this.onUpdate})
    : super(key: key);

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  UserProfile? postOwner;
  bool isLoading = true;
  String? loggedInUserId;

  // Flag to hide the widget after deletion
  bool _isDeleted = false;

  @override
  void initState() {
    super.initState();
    _fetchPostOwner();
    _fetchLoggedInUserId();
  }

  Future<void> _fetchPostOwner() async {
    try {
      final owner = await fetchUserProfile(widget.post.userId.toString());
      setState(() {
        postOwner = owner;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchLoggedInUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      loggedInUserId = prefs.getString('user_id') ?? '';
    });
  }

  void _showPostMenu() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Update Post'),
              onTap: () async {
                Navigator.pop(context);

                // Show dialog to enter new content
                final newContent = await showDialog<String>(
                  context: context,
                  builder: (context) {
                    String tempContent = widget.post.content;
                    return AlertDialog(
                      title: const Text('Update Post'),
                      content: TextField(
                        controller: TextEditingController(text: tempContent),
                        maxLines: null,
                        onChanged: (val) => tempContent = val,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, null),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, tempContent),
                          child: const Text('Update'),
                        ),
                      ],
                    );
                  },
                );

                if (newContent != null && newContent.isNotEmpty) {
                  final response = await updatePost(
                    postId: widget.post.postId,
                    newContent: newContent,
                  );

                  if (response.success) {
                    setState(() {
                      widget.post.content = newContent; // update locally
                    });
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete Post'),
              onTap: () async {
                Navigator.pop(context);

                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Post'),
                    content: const Text(
                      'Are you sure you want to delete this post?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  final response = await deletePost(postId: widget.post.postId);

                  if (response.success) {
                    // Hide the widget
                    setState(() {
                      _isDeleted = true;
                    });

                    if (widget.onDelete != null) {
                      widget.onDelete!(widget.post.postId.toString());
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDeleted) {
      return const SizedBox.shrink(); // shrink widget to height 0
    }

    final post = widget.post;
    final isOwner =
        loggedInUserId != null && loggedInUserId == post.userId.toString();

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header (profile + menu) ---
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(
                    userId: postOwner?.userId ?? post.userId.toString(),
                    showTopBanner: true,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage:
                        (postOwner?.profilePicture?.isNotEmpty == true)
                        ? NetworkImage(postOwner!.profilePicture)
                        : null,
                    backgroundColor: Colors.grey[400],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          postOwner?.username ?? 'User ${post.userId}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          DateFormat.yMMMd().add_jm().format(post.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isOwner)
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: _showPostMenu,
                    ),
                ],
              ),
            ),
          ),

          // --- Post content ---
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(post.content),
            ),

          // --- Media ---
          AspectRatio(
            aspectRatio: 1,
            child: post.mediaUrl.isNotEmpty
                ? Image.network(
                    post.mediaUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholder();
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildPlaceholder();
                    },
                  )
                : _buildPlaceholder(),
          ),

          // --- Likes & Comments ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Like button
                Icon(
                  post.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                  color: post.isLikedByMe ? Colors.red : Colors.black,
                ),
                const SizedBox(width: 6),
                Text(
                  '${post.likesNbr}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),

                // Comment button with tap
                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => CommentsBottomSheet(postId: post.postId),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(
                        Icons.mode_comment_outlined,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.commentsNbr}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.black12,
      child: const Center(
        child: Icon(Icons.image_outlined, size: 60, color: Colors.grey),
      ),
    );
  }
}
