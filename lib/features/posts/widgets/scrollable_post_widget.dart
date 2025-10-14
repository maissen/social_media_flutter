import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:demo/utils/feed_helpers.dart'; // Post model
import 'package:demo/utils/user_helpers.dart'; // fetchUserProfile function
import 'package:demo/utils/user_profile.dart'; // UserProfile model
import 'package:demo/features/profile/screens/profile_screen.dart'; // ProfileScreen

class PostWidget extends StatefulWidget {
  final Post post;

  const PostWidget({Key? key, required this.post}) : super(key: key);

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  UserProfile? postOwner;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPostOwner();
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

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Container(
      color: Colors.white, // Pure white background like Instagram
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header (profile) ---
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
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(
                      postOwner?.profilePicture?.isNotEmpty == true
                          ? postOwner!.profilePicture
                          : 'https://i.pravatar.cc/150?img=${post.userId}',
                    ),
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
                ],
              ),
            ),
          ),

          // --- Post content text (caption) ---
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(post.content),
            ),

          // --- Media Section (Image or Placeholder) ---
          AspectRatio(
            aspectRatio: 1, // Instagram square format
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

  /// Placeholder for when there's no image or an error occurs
  Widget _buildPlaceholder() {
    return Container(
      color: Colors.black12,
      child: const Center(
        child: Icon(Icons.image_outlined, size: 60, color: Colors.grey),
      ),
    );
  }
}
