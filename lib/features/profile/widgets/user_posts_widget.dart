// lib/features/profile/widgets/user_posts_widget.dart
import 'package:flutter/material.dart';
import 'package:demo/utils/user_profile.dart';

class UserPostsWidget extends StatefulWidget {
  final String profileUserId;
  final String? loggedInUserId;
  final VoidCallback? onSharePostTapped;

  const UserPostsWidget({
    Key? key,
    required this.profileUserId,
    required this.loggedInUserId,
    this.onSharePostTapped,
  }) : super(key: key);

  @override
  State<UserPostsWidget> createState() => _UserPostsWidgetState();
}

class _UserPostsWidgetState extends State<UserPostsWidget> {
  List<UserPost>? _userPosts;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserPosts();
  }

  @override
  void didUpdateWidget(UserPostsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileUserId != widget.profileUserId) {
      _loadUserPosts();
    }
  }

  Future<void> _loadUserPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await getUserPosts(userId: widget.profileUserId);
      setState(() {
        _userPosts = response.posts ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _userPosts = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userPosts == null || _userPosts!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'No posts shared yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (widget.loggedInUserId == widget.profileUserId &&
                widget.onSharePostTapped != null)
              ElevatedButton(
                onPressed: widget.onSharePostTapped,
                child: const Text('Share a Post'),
              ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _userPosts!.length,
      itemBuilder: (context, index) {
        final post = _userPosts![index];
        return GestureDetector(
          onTap: () {
            // Navigate to post detail or perform other action
          },
          child: Container(
            decoration: BoxDecoration(color: Colors.grey[300]),
            child: post.mediaUrl != null
                ? ClipRRect(
                    child: Image.network(
                      post.mediaUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                  ),
          ),
        );
      },
    );
  }
}
