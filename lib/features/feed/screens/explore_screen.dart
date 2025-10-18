import 'dart:ui';
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
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              title: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.deepPurple, Colors.blue],
                ).createShader(bounds),
                child: const Text(
                  'Explore',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
              ),
              backgroundColor: Colors.white.withOpacity(0.7),
              foregroundColor: Colors.black,
              elevation: 0,
              centerTitle: false,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadExploreFeed,
          child: isLoading
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(
                      height: 300,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                )
              : errorMessage != null
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: Center(child: Text(errorMessage!)),
                    ),
                  ],
                )
              : explorePosts.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: const Center(
                        child: Text(
                          'No posts available',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: explorePosts.length,
                  itemBuilder: (context, index) {
                    final post = explorePosts[index];
                    return PostWidget(postId: post.postId);
                  },
                ),
        ),
      ),
    );
  }
}
