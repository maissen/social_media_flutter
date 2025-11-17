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
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

class PostWidget extends StatefulWidget {
  final int postId;
  final Function(String postId)? onDelete;
  final Function(String postId)? onUpdate;
  final List<List<dynamic>>? categoryObjects;

  const PostWidget({
    Key? key,
    required this.postId,
    this.onDelete,
    this.onUpdate,
    this.categoryObjects,
  }) : super(key: key);

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  Post? post;
  UserProfile? postOwner;
  bool isLoading = true;
  String? loggedInUserId;

  bool _isLiked = false;
  int _likesCount = 0;
  int _commentsCount = 0;
  String _currentContent = '';

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

        _fetchPostOwner();
      } else {
        setState(() => isLoading = false);
      }
    } catch (_) {
      setState(() => isLoading = false);
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
    } catch (_) {
      setState(() => isLoading = false);
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
                    setState(() => _currentContent = newContent);
                    widget.onUpdate?.call(widget.postId.toString());
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
                    setState(() => _isDeleted = true);
                    widget.onDelete?.call(widget.postId.toString());
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = widget.categoryObjects;

    if (categories == null || categories.isEmpty)
      return const SizedBox.shrink();

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
              color: Colors.white,
              border: Border.all(color: Colors.grey),
            ),
            child: Center(
              child: Text(
                categoryName,
                style: const TextStyle(
                  color: Colors.black,
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

  Widget _buildPostText() {
    if (_currentContent.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Linkify(
        text: _currentContent,
        onOpen: (link) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Open Link'),
              content: const Text(
                'You need to open your browser to visit this link',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final uri = Uri.parse(link.url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not launch link')),
                      );
                    }
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
        style: const TextStyle(fontSize: 14, color: Colors.black),
        linkStyle: TextStyle(
          foreground: Paint()
            ..shader = const LinearGradient(
              colors: [Colors.deepPurple, Colors.blue],
            ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 20.0)),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDeleted) return const SizedBox.shrink();

    if (isLoading || post == null) {
      return Container(
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 20),
        height: 400,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final isOwner = loggedInUserId == post!.userId.toString();

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(
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

          // CONTENT TEXT WITH LINKIFY
          _buildPostText(),

          // FULL-WIDTH IMAGE
          if (post!.mediaUrl.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.black12,
              child: Image.network(
                post!.mediaUrl,
                width: double.infinity,
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => _buildPlaceholder(),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return SizedBox(height: 200, child: _buildPlaceholder());
                },
              ),
            ),

          // CATEGORIES
          _buildCategoryChips(),

          // LIKE + COMMENT ROW
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
                        '$_likesCount likes',
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
                      const Icon(Icons.mode_comment_outlined),
                      const SizedBox(width: 6),
                      Text(
                        '$_commentsCount comments',
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
