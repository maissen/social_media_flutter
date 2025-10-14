import 'package:demo/features/posts/widgets/scrollable_post_widget.dart';
import 'package:demo/utils/feed_helpers.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white, // set background to white
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white, // set background to white
        body: Center(child: Text(errorMessage!)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white, // set background to white
      appBar: AppBar(title: const Text('Feed')),
      body: ListView.builder(
        itemCount: userFeedPosts.length,
        itemBuilder: (context, index) {
          final post = userFeedPosts[index];
          return PostWidget(postId: post.postId); // Your post widget
        },
      ),
    );
  }
}
