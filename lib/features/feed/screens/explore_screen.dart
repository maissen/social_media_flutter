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
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

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
    Widget bodyContent;

    if (isLoading) {
      bodyContent = const Center(child: CircularProgressIndicator());
    } else if (errorMessage != null) {
      bodyContent = Center(child: Text(errorMessage!));
    } else if (explorePosts.isEmpty) {
      bodyContent = const Center(child: Text('No posts available'));
    } else {
      bodyContent = ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: explorePosts.length,
        itemBuilder: (context, index) {
          final post = explorePosts[index];
          return PostWidget(postId: post.postId);
        },
      );
    }

    // Wrap all states in RefreshIndicator
    if (bodyContent is! RefreshIndicator) {
      bodyContent = RefreshIndicator(
        onRefresh: _loadExploreFeed,
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
      appBar: AppBar(
        title: const Text('Explore'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: bodyContent,
    );
  }
}
