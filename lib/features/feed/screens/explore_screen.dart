import 'dart:ui';
import 'package:demo/features/posts/widgets/scrollable_post_widget.dart';
import 'package:demo/utils/feed_helpers.dart';
import '../../post_category_filter_widget.dart';
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
  int? selectedCategoryId;
  String? selectedCategoryName;

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
      final posts = await fetchExploreFeed(categoryId: selectedCategoryId);
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

  void _onCategorySelected(int? categoryId, String? categoryName) {
    setState(() {
      selectedCategoryId = categoryId;
      selectedCategoryName = categoryName;
    });
    _loadExploreFeed();
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
              onPressed: _loadExploreFeed,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (explorePosts.isEmpty) {
      bodyContent = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              selectedCategoryId != null
                  ? 'No posts in "$selectedCategoryName"'
                  : 'No posts available',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              selectedCategoryId != null
                  ? 'Try selecting a different category or clear the filter'
                  : 'Check back later for new content!',
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
              onRefresh: _loadExploreFeed,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: explorePosts.length,
                itemBuilder: (context, index) {
                  final post = explorePosts[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PostWidget(
                        postId: post.postId,
                        categoryObjects: post.categoryObjects ?? [],
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
        onRefresh: _loadExploreFeed,
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
                  'Explore',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
              ),
              centerTitle: false,
              actions: [
                // Category Filter Button
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8, right: 12),
                  child: CategoryFilterButton(
                    selectedCategoryId: selectedCategoryId,
                    onCategorySelected: _onCategorySelected,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: bodyContent,
    );
  }
}
