import 'package:flutter/material.dart';
import 'package:demo/utils/posts_helpers.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentsBottomSheet extends StatefulWidget {
  final int postId;

  const CommentsBottomSheet({Key? key, required this.postId}) : super(key: key);

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  List<Map<String, dynamic>>? comments;
  final TextEditingController _commentController = TextEditingController();
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
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

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isPosting = true);

    final response = await createComment(postId: widget.postId, content: text);
    if (response.success) {
      _commentController.clear();
      await _loadComments(); // Refresh comments
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
    }

    setState(() => _isPosting = false);
  }

  Future<void> _toggleLike(int? commentId) async {
    if (commentId == null) return; // Prevent null crash

    final response = await likeOrDislikeComment(commentId: commentId);
    if (response.success) {
      await _loadComments(); // Refresh like states
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
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
          // Drag handle
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

          // Comments list
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
                      final commentId =
                          comment['id'] ?? comment['comment_id']; // Safe ID
                      final likedByUser =
                          comment['is_liked_by_me'] ?? false; // API field
                      final likeCount = comment['likes_nbr'] ?? 0; // API field

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundImage: profilePic.isNotEmpty
                                  ? NetworkImage(profilePic)
                                  : null,
                              backgroundColor: Colors.grey[300],
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Username + comment
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

                                  // Timestamp + like count inline
                                  Text(
                                    createdAt.isNotEmpty
                                        ? likeCount > 0
                                              ? '${timeago.format(DateTime.parse(createdAt), locale: 'en_short')} • $likeCount likes'
                                              : timeago.format(
                                                  DateTime.parse(createdAt),
                                                  locale: 'en_short',
                                                )
                                        : '',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // ❤️ Like button
                            GestureDetector(
                              onTap: commentId != null
                                  ? () => _toggleLike(commentId)
                                  : null,
                              child: Icon(
                                likedByUser
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: likedByUser ? Colors.red : Colors.black,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Comment input + Share button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _isPosting ? null : _postComment,
                    child: _isPosting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Share',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
