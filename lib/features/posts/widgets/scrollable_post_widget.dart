import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:demo/utils/feed_helpers.dart'; // Post model
import 'package:demo/utils/user_helpers.dart'; // fetchUserProfile function
import 'package:demo/utils/user_profile.dart'; // fetchUserProfile function

class PostWidget extends StatefulWidget {
  final Post post;

  const PostWidget({Key? key, required this.post}) : super(key: key);

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  UserProfile? postOwner; // will hold the post owner info
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
          // Post header
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(
                    postOwner?.profilePicture ?? '',
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
          // Post content
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(post.content),
            ),
          // Media
          if (post.mediaUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Image.network(
                post.mediaUrl,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          // Likes & comments
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
                Icon(Icons.comment, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${post.commentsNbr} comments'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
