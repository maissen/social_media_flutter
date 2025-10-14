import 'package:flutter/material.dart';
import 'package:demo/utils/posts_helpers.dart';

class LikesBottomSheet extends StatefulWidget {
  final int postId;

  const LikesBottomSheet({Key? key, required this.postId}) : super(key: key);

  @override
  State<LikesBottomSheet> createState() => _LikesBottomSheetState();
}

class _LikesBottomSheetState extends State<LikesBottomSheet> {
  List<dynamic> likes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLikes();
  }

  Future<void> _fetchLikes() async {
    final response = await getPostLikes(postId: widget.postId);
    if (response.success && response.data != null) {
      setState(() {
        likes = response.data!;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 700,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Drag indicator
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 8),
          const Text(
            'Likes',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : likes.isEmpty
                ? const Center(child: Text('No likes yet'))
                : ScrollConfiguration(
                    behavior: const _NoGlowBounceScrollBehavior(),
                    child: ListView.builder(
                      // ensure bouncing physics is applied
                      physics: const BouncingScrollPhysics(),
                      itemCount: likes.length,
                      itemBuilder: (context, index) {
                        final like = likes[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: like['profile_picture'] != null
                                ? NetworkImage(like['profile_picture'])
                                : null,
                            backgroundColor: Colors.grey[300],
                          ),
                          title: Text(like['username'] ?? ''),
                          subtitle: Text(like['email'] ?? ''),
                          trailing: like['is_following'] == true
                              ? const Text(
                                  'Following',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// ScrollBehavior that removes the overscroll glow and keeps bouncing physics.
/// Overrides buildOverscrollIndicator (newer API) to disable glow.
class _NoGlowBounceScrollBehavior extends ScrollBehavior {
  const _NoGlowBounceScrollBehavior();

  // Removes the overscroll indicator (glow) on both Android and iOS.
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  // Provide bouncing physics by default (ListView also explicitly sets it).
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}
