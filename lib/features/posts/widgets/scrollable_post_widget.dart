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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header (profile) ---
          InkWell(
            onTap: () {
              // Navigate to profile screen
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
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(
                      postOwner?.profilePicture?.isNotEmpty == true
                          ? postOwner!.profilePicture
                          : 'https://i.pravatar.cc/150?img=${post.userId}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          postOwner?.username ?? 'User ${post.userId}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
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

          // --- Post content text ---
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(post.content),
            ),

          // --- Media Section (Image or Placeholder) ---
          AspectRatio(
            aspectRatio: 1, // Instagram-style square
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
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Icon(
                  post.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                  color: post.isLikedByMe ? Colors.red : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text('${post.likesNbr} likes'),
                const SizedBox(width: 16),
                const Icon(Icons.comment, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${post.commentsNbr} comments'),
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
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.image_outlined, size: 60, color: Colors.grey),
      ),
    );
  }
}
