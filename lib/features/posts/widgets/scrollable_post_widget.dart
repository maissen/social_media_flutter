import 'package:demo/features/posts/screens/post_screen.dart';
import 'package:demo/features/posts/widgets/comments_bottom_sheet_widget.dart';
import 'package:demo/features/posts/widgets/likes_bottom_sheet_widget.dart';
import 'package:demo/utils/posts_helpers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demo/utils/feed_helpers.dart';
import 'package:demo/utils/user_helpers.dart';
import 'package:demo/utils/user_profile.dart';
import 'package:demo/features/profile/screens/profile_screen.dart';

class PostWidget extends StatefulWidget {
  final int postId;
  final Function(String postId)? onDelete;
  final Function(String postId)? onUpdate;
  final List<List<dynamic>>? categoryObjects; // Add this parameter

  const PostWidget({
    Key? key,
    required this.postId,
    this.onDelete,
    this.onUpdate,
    this.categoryObjects, // Add this
  }) : super(key: key);

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  Post? post;
  UserProfile? postOwner;
  bool isLoading = true;
  String? loggedInUserId;

  // Local states for likes
  bool _isLiked = false;
  int _likesCount = 0;
  int _commentsCount = 0;

  // Local state for content
  String _currentContent = '';

  // Flag to hide the widget after deletion
  bool _isDeleted = false;

  @override
  void initState() {
    super.initState();
    _fetchPost();
    _fetchLoggedInUserId();
  }

  Future<void> _fetchPost() async {
    try {
      final response = await getPostById(widget.postId);

      if (response.success && response.post != null) {
        final postData = response.post!;

        setState(() {
          post = Post.fromJson(postData);
          _isLiked = post!.isLikedByMe;
          _likesCount = post!.likesNbr;
          _commentsCount = post!.commentsNbr;
          _currentContent = post!.content;
        });

        // Fetch post owner
        _fetchPostOwner();
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchPostOwner() async {
    if (post == null) return;

    try {
      final owner = await fetchUserProfile(post!.userId.toString());
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

                final newContent = await showDialog<String>(
                  context: context,
                  builder: (context) {
                    String tempContent = _currentContent;
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
                    postId: widget.postId,
                    newContent: newContent,
                  );

                  if (response.success) {
                    setState(() {
                      _currentContent = newContent;
                    });
                    if (widget.onUpdate != null) {
                      widget.onUpdate!(widget.postId.toString());
                    }
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
                  final response = await deletePost(postId: widget.postId);

                  if (response.success) {
                    setState(() {
                      _isDeleted = true;
                    });
                    if (widget.onDelete != null) {
                      widget.onDelete!(widget.postId.toString());
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

  // Helper method to build category chips
  Widget _buildCategoryChips() {
    final categories = widget.categoryObjects;

    if (categories == null || categories.isEmpty) {
      return const SizedBox.shrink();
    }

    final categoryNames = categories.map((cat) => cat[1] as String).toList();

    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categoryNames.length,
        itemBuilder: (context, index) {
          final categoryName = categoryNames[index];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white, // background white
              border: Border.all(color: Colors.grey), // gray border
            ),
            child: Center(
              child: Text(
                categoryName,
                style: const TextStyle(
                  color: Colors.black, // gray text
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDeleted) {
      return const SizedBox.shrink();
    }

    if (isLoading || post == null) {
      return Container(
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 20),
        height: 400,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final isOwner =
        loggedInUserId != null && loggedInUserId == post!.userId.toString();

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header ---
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(
                    userId: postOwner?.userId ?? post!.userId.toString(),
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
                          postOwner?.username ?? 'User ${post!.userId}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          DateFormat.yMMMd().add_jm().format(post!.createdAt),
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
          if (_currentContent.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(_currentContent),
            ),

          // --- Media ---
          AspectRatio(
            aspectRatio: 1,
            child: post!.mediaUrl.isNotEmpty
                ? Image.network(
                    post!.mediaUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholder(),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildPlaceholder();
                    },
                  )
                : _buildPlaceholder(),
          ),

          // --- CATEGORIES (between image and likes/comments) ---
          _buildCategoryChips(),

          // --- Likes & Comments ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () async {
                        final response = await likeOrDislikePost(
                          postId: widget.postId,
                        );
                        if (response.success) {
                          setState(() {
                            _isLiked = !_isLiked;
                            _likesCount += _isLiked ? 1 : -1;
                          });
                        }
                      },
                      child: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked
                            ? Colors.deepPurpleAccent
                            : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) =>
                              LikesBottomSheet(postId: widget.postId),
                        );
                      },
                      child: Text(
                        '$_likesCount ${_likesCount == 1 ? 'like' : 'likes'}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) =>
                          CommentsBottomSheet(postId: widget.postId),
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
                        '$_commentsCount ${_commentsCount == 1 ? 'comment' : 'comments'}',
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
