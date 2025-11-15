import 'dart:ui';
import 'package:demo/features/notifications_screen.dart';
import 'package:demo/features/posts/widgets/scrollable_post_widget.dart';
import 'package:demo/utils/feed_helpers.dart';
import 'package:demo/features/auth/screens/login_screen.dart';
import '../../post_category_filter_widget.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demo/features/chat/conversations_list_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Post> userFeedPosts = [];
  bool isLoading = true;
  String? errorMessage;
  String? userId;
  int? selectedCategoryId;
  String? selectedCategoryName;

  @override
  void initState() {
    super.initState();
    _loadUserFeed();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('user_id');
    });
  }

  Future<void> _loadUserFeed() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final posts = await fetchUserFeed(categoryId: selectedCategoryId);
      setState(() {
        userFeedPosts = posts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load feed: $e';
        isLoading = false;
      });
    }
  }

  void _onCategorySelected(int? categoryId, String? categoryName) {
    setState(() {
      selectedCategoryId = categoryId;
      selectedCategoryName = categoryName;
    });
    _loadUserFeed();
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('user_id');
      await prefs.remove('expires_in');
      await prefs.remove('login_timestamp');

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;

    if (isLoading) {
      bodyContent = const Center(child: CircularProgressIndicator());
    } else if (errorMessage != null) {
      bodyContent = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserFeed,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (userFeedPosts.isEmpty) {
      bodyContent = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.feed_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              selectedCategoryId != null
                  ? 'No posts in "$selectedCategoryName"'
                  : 'No posts available.',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              selectedCategoryId != null
                  ? 'Try selecting a different category or clear the filter'
                  : 'Follow some users to see their posts here!',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (selectedCategoryId != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _onCategorySelected(null, null),
                child: const Text('Clear Filter'),
              ),
            ],
          ],
        ),
      );
    } else {
      bodyContent = Column(
        children: [
          // Category filter chip below app bar
          if (selectedCategoryId != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.deepPurple, Colors.blue],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.filter_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Filtered by: $selectedCategoryName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _onCategorySelected(null, null),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadUserFeed,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: userFeedPosts.length,
                itemBuilder: (context, index) {
                  final post = userFeedPosts[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PostWidget(
                        postId: post.postId,
                        categoryObjects: post.categoryObjects,
                      ),
                      Divider(height: 1, thickness: 1, color: Colors.grey[200]),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      );
    }

    // Wrap the empty/error/loading states with RefreshIndicator as well
    if (bodyContent is! Column && bodyContent is! RefreshIndicator) {
      bodyContent = RefreshIndicator(
        onRefresh: _loadUserFeed,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 100,
            child: bodyContent,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: Colors.white.withOpacity(0.7),
              elevation: 0,
              title: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.deepPurple, Colors.blue],
                ).createShader(bounds),
                child: const Text(
                  'Feed',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
              ),
              actions: [
                // Category Filter Button
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8, right: 4),
                  child: CategoryFilterButton(
                    selectedCategoryId: selectedCategoryId,
                    onCategorySelected: _onCategorySelected,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.message, color: Colors.blue),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final currentUserId = prefs.getString('user_id') ?? '';

                    if (currentUserId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'You must be logged in to view messages',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConversationsListScreen(),
                      ),
                    );
                  },
                  tooltip: 'Messages',
                ),
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                  tooltip: 'Notifications',
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.blue),
                  onPressed: _logout,
                  tooltip: 'Logout',
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: bodyContent,
    );
  }
}
