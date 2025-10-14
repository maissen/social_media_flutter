import 'package:demo/features/posts/widgets/scrollable_post_widget.dart';
import 'package:demo/utils/feed_helpers.dart';
import 'package:flutter/material.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<Post> explorePosts = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExploreFeed();
  }

  Future<void> _loadExploreFeed() async {
    try {
      final posts = await fetchExploreFeed();
      setState(() {
        explorePosts = posts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load explore feed: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text(errorMessage!)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white, // body background
      appBar: AppBar(
        title: const Text('Explore'),
        backgroundColor: Colors.white, // app bar background
        foregroundColor: Colors.black, // app bar text & icons
        elevation: 0, // remove shadow for flat white look
      ),
      body: ListView.builder(
        itemCount: explorePosts.length,
        itemBuilder: (context, index) {
          final post = explorePosts[index];
          return PostWidget(postId: post.postId);
        },
      ),
    );
  }
}
