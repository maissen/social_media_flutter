import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demo/utils/feed_helpers.dart'; // Post model
import 'package:demo/utils/user_helpers.dart'; // fetchUserProfile
import 'package:demo/utils/user_profile.dart';
import 'package:demo/features/profile/screens/profile_screen.dart';

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
              onTap: () {
                Navigator.pop(context);
                if (widget.onUpdate != null)
                  widget.onUpdate!(widget.post.postId.toString());
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete Post'),
              onTap: () {
                Navigator.pop(context);
                if (widget.onDelete != null)
                  widget.onDelete!(widget.post.postId.toString());
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        : null, // no image
                    backgroundColor:
                        Colors.grey[400], // gray circle as fallback
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
                  // Show three dots menu only for post owner
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
                const Icon(Icons.mode_comment_outlined, color: Colors.black),
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
