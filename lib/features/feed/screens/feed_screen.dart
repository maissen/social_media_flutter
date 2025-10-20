import 'dart:ui';
import 'package:demo/features/notifications_screen.dart';
import 'package:demo/features/posts/widgets/scrollable_post_widget.dart';
import 'package:demo/utils/feed_helpers.dart';
import 'package:demo/utils/auth_helpers.dart';
import 'package:demo/features/auth/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/chat/chat_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Post> userFeedPosts = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserFeed();
  }

  Future<void> _loadUserFeed() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final posts = await fetchUserFeed();
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
      bodyContent = Center(child: Text(errorMessage!));
    } else if (userFeedPosts.isEmpty) {
      bodyContent = const Center(
        child: Text(
          'No posts available.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    } else {
      bodyContent = RefreshIndicator(
        onRefresh: _loadUserFeed,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: userFeedPosts.length,
          itemBuilder: (context, index) {
            final post = userFeedPosts[index];
            return PostWidget(postId: post.postId);
          },
        ),
      );
    }

    // Wrap the empty/error/loading states with RefreshIndicator as well
    if (bodyContent is! RefreshIndicator) {
      bodyContent = RefreshIndicator(
        onRefresh: _loadUserFeed,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
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
