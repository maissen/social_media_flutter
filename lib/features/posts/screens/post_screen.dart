import 'dart:async';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demo/utils/posts_helpers.dart';
import 'package:demo/features/posts/widgets/comments_bottom_sheet_widget.dart';
import 'package:demo/features/posts/widgets/likes_bottom_sheet_widget.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

// Widget to display post categories
class PostCategories extends StatelessWidget {
  final List<dynamic>? categoryObjects;

  PostCategories({Key? key, this.categoryObjects}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (categoryObjects == null || categoryObjects!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categoryObjects!.length,
        itemBuilder: (context, index) {
          final category = categoryObjects![index];

          // Extract the category name
          String categoryName = 'Category';

          if (category is List && category.length > 1) {
            categoryName = category[1].toString();
          } else if (category is Map<String, dynamic>) {
            categoryName =
                category['category_name'] ?? category['name'] ?? 'Category';
          } else {
            categoryName = category.toString();
          }

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
}

// Global variables accessible anywhere in this file
late GetPostResponse postResponse;
bool isPostLikedByMe = false;

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
        isPostLikedByMe = postResponse.post!['is_liked_by_me'] ?? false;

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
    Navigator.pop(context, true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchPost,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_postData == null) {
      return const Scaffold(body: Center(child: Text('Post not found')));
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 1,
          leading: IconButton(
            icon: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.deepPurple, Colors.blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            onPressed: () => Navigator.pop(context, true),
          ),
          title: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.deepPurple, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: const Text(
              'Post insights',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchPost,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: PostContent(
                    postData: _postData!,
                    loggedInUserId: _loggedInUserId,
                    onUpdate: (updatedPost) {
                      setState(() => _postData = updatedPost);
                    },
                    onDelete: () => Navigator.pop(context, true),
                  ),
                ),
              ),
            ),
            CommentInput(
              controller: _commentController,
              postId: _postData!['post_id'],
              onCommentAdded: _fetchPost,
            ),
          ],
        ),
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
        PostHeader(
          postData: postData,
          loggedInUserId: loggedInUserId,
          onUpdate: onUpdate,
          onDelete: onDelete,
        ),
        const SizedBox(height: 16),
        PostCategories(categoryObjects: postData['category_objects']),
        const SizedBox(height: 12),

        // FIXED MEDIA HERE
        PostMedia(mediaUrl: postData['media_url']),

        const SizedBox(height: 16),
        if (postData['content'] != null &&
            postData['content'].toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Linkify(
              text: postData['content'],
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
                              const SnackBar(
                                content: Text('Could not open the link'),
                              ),
                            );
                          }
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },

              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
                color: Colors.black,
              ),
              linkStyle: TextStyle(
                foreground: Paint()
                  ..shader = const LinearGradient(
                    colors: [Colors.deepPurple, Colors.blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 20.0)),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        const SizedBox(height: 16),
        PostActions(
          postId: postData['post_id'],
          likesNbr: postData['likes_nbr'] ?? 0,
          isLikedByMe: isPostLikedByMe,
          commentsNbr: postData['comments_nbr'] ?? 0,
          createdAt: postData['created_at'],
        ),
      ],
    );
  }
}

class PostHeader extends StatelessWidget {
  final Map<String, dynamic> postData;
  final int? loggedInUserId;
  final ValueChanged<Map<String, dynamic>> onUpdate;
  final VoidCallback onDelete;

  const PostHeader({
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
      builder: (ctx) => AlertDialog(
        title: const Text('Update Post'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'Edit your post...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newContent = controller.text.trim();
              if (newContent.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post content cannot be empty')),
                );
                return;
              }
              Navigator.pop(ctx);

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
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);

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
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = postData['user'] as Map<String, dynamic>?;
    final isOwner =
        loggedInUserId != null &&
        user != null &&
        user['user_id'] == loggedInUserId;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: user?['profile_picture'] != null
                    ? NetworkImage(user!['profile_picture'])
                    : null,
                radius: 24,
                child: user?['profile_picture'] == null
                    ? const Icon(Icons.person, size: 24)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?['username'] ?? 'Unknown User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (postData['created_at'] != null)
                      Text(
                        _formatDateTime(postData['created_at']),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (isOwner)
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'update') _showUpdateDialog(context);
              if (value == 'delete') _showDeleteDialog(context);
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'update',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Update Post'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Post', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
      ],
    );
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return timeago.format(dateTime, locale: 'en_short');
    } catch (e) {
      return dateTimeStr;
    }
  }
}

////////////////////////////////////////////////////////////////////////////////
// ✔ FIXED POST MEDIA (FULL WIDTH + NO CROP + DYNAMIC HEIGHT)
////////////////////////////////////////////////////////////////////////////////

class PostMedia extends StatefulWidget {
  final String? mediaUrl;

  const PostMedia({Key? key, this.mediaUrl}) : super(key: key);

  @override
  State<PostMedia> createState() => _PostMediaState();
}

class _PostMediaState extends State<PostMedia> {
  double? _aspectRatio;

  @override
  void initState() {
    super.initState();
    if (widget.mediaUrl != null && widget.mediaUrl!.isNotEmpty) {
      _calculateImageAspectRatio(widget.mediaUrl!);
    }
  }

  Future<void> _calculateImageAspectRatio(String url) async {
    final image = Image.network(url);
    final completer = Completer<ImageInfo>();

    image.image
        .resolve(const ImageConfiguration())
        .addListener(
          ImageStreamListener(
            (ImageInfo info, bool _) {
              completer.complete(info);
            },
            onError: (error, stack) {
              completer.completeError(error);
            },
          ),
        );

    try {
      final info = await completer.future;
      final width = info.image.width.toDouble();
      final height = info.image.height.toDouble();

      if (mounted) {
        setState(() {
          _aspectRatio = width / height;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _aspectRatio = 1.0); // fallback
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.mediaUrl;

    if (url == null || url.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        height: 220,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'No media available',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_aspectRatio == null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 260,
          width: double.infinity,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: _aspectRatio!,
        child: Image.network(
          url,
          width: double.infinity,
          fit: BoxFit.fitWidth, // FULL WIDTH — NO CROP
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  const Text(
                    'Failed to load image',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          },
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;

            final pct = progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                : null;

            return Container(
              color: Colors.grey[200],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(value: pct, strokeWidth: 2),
                    if (pct != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        "${(pct * 100).toInt()}%",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////////////////////////

class PostActions extends StatelessWidget {
  final int postId;
  final int likesNbr;
  final bool isLikedByMe;
  final int commentsNbr;
  final String createdAt;

  const PostActions({
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
      builder: (ctx) => CommentsBottomSheet(postId: postId),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr);
      return "${_monthName(dateTime.month)} ${dateTime.day}, ${dateTime.year} at "
          "${_formatHour(dateTime)}";
    } catch (e) {
      return dateStr;
    }
  }

  String _monthName(int month) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return months[month - 1];
  }

  String _formatHour(DateTime dt) {
    int hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    String minute = dt.minute.toString().padLeft(2, '0');
    String period = dt.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            LikeButton(postId: postId),
            GestureDetector(
              onTap: () => _showCommentsBottomSheet(context),
              child: Row(
                children: [
                  Icon(
                    Icons.comment_outlined,
                    size: 20,
                    color: const Color.fromARGB(255, 75, 75, 75),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$commentsNbr comment${commentsNbr != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(255, 75, 75, 75),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            _formatDate(createdAt),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      ],
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (postResponse.post != null) {
      likesCount = postResponse.post!['likes_nbr'] ?? 0;
    }
  }

  @override
  void didUpdateWidget(LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (postResponse.post != null) {
      if (likesCount != (postResponse.post!['likes_nbr'] ?? 0)) {
        setState(() {
          likesCount = postResponse.post!['likes_nbr'] ?? 0;
        });
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final response = await likeOrDislikePost(postId: widget.postId);

    if (response.success && response.data != null) {
      bool newIsLiked;
      int newLikesCount = likesCount;

      if (response.data!.containsKey('is_liked')) {
        newIsLiked = response.data!['is_liked'] == true;
        if (newIsLiked && !isPostLikedByMe) {
          newLikesCount += 1;
        } else if (!newIsLiked && isPostLikedByMe) {
          newLikesCount -= 1;
        }
      } else if (response.data!.containsKey('is_liked_by_me') &&
          response.data!.containsKey('likes_nbr')) {
        newIsLiked = response.data!['is_liked_by_me'] == true;
        newLikesCount += 1;
      } else {
        newIsLiked = isPostLikedByMe;
      }

      isPostLikedByMe = newIsLiked;

      setState(() {
        likesCount = newLikesCount;
      });

      if (postResponse.post != null) {
        postResponse.post!['is_liked_by_me'] = newIsLiked;
        postResponse.post!['likes_nbr'] = newLikesCount;
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
    }

    setState(() => _isLoading = false);
  }

  void _onLikesCountTap() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LikesBottomSheet(postId: widget.postId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: _toggleLike,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isPostLikedByMe ? Icons.favorite : Icons.favorite_border,
                    color: isPostLikedByMe
                        ? Colors.deepPurpleAccent
                        : Colors.grey[700],
                    size: 24,
                  ),
          ),
        ),
        const SizedBox(width: 4),
        InkWell(
          onTap: _onLikesCountTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              '$likesCount like${likesCount != 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 14,
                color: Color.fromARGB(255, 75, 75, 75),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CommentInput extends StatelessWidget {
  final TextEditingController controller;
  final int postId;
  final VoidCallback? onCommentAdded;

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
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText:
                      'Add a comment${postResponse.post?['user']?['username'] != null ? ' @${postResponse.post!['user']['username']}' : ''}...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.deepPurple),
              onPressed: () async {
                final content = controller.text.trim();
                if (content.isEmpty) return;

                FocusScope.of(context).unfocus();

                final response = await createComment(
                  postId: postId,
                  content: content,
                );

                if (response.success) {
                  controller.clear();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Comment added!'),
                      duration: Duration(seconds: 2),
                    ),
                  );

                  if (onCommentAdded != null) {
                    onCommentAdded!();
                  }
                } else {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(response.message)));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
