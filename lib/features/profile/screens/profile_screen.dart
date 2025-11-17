import 'package:demo/features/chat/conversation_screen.dart';
import 'package:demo/features/posts/screens/create_post_screen.dart';
import 'package:demo/features/posts/screens/post_screen.dart';
import 'package:demo/utils/auth_helpers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demo/utils/user_profile.dart';
import 'package:demo/utils/user_helpers.dart';
import 'package:demo/features/profile/screens/update_profile.dart';
import 'package:demo/features/profile/screens/followers_screen.dart';
import 'package:demo/features/profile/screens/followings_screen.dart';
import 'package:demo/features/profile/widgets/user_posts_widget.dart';
import 'package:demo/features/chat/conversations_list_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onSharePostTapped;
  final String userId;
  final bool showTopBanner;

  const ProfileScreen({
    Key? key,
    this.onSharePostTapped,
    required this.userId,
    this.showTopBanner = false,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _loggedInUserId;
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isFollowLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLoggedInUserId();
    _loadProfile();
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _loadProfile();
    }
  }

  Future<void> _loadLoggedInUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _loggedInUserId = prefs.getString('user_id');
    });
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await fetchUserProfile(widget.userId);
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFollowToggle() async {
    if (_userProfile == null || _isFollowLoading) return;

    setState(() => _isFollowLoading = true);
    final response = await toggleFollow(targetUserId: widget.userId);

    if (response.success && response.isFollowing != null) {
      setState(() {
        _userProfile = _userProfile!.copyWith(
          followersCount: response.isFollowing!
              ? _userProfile!.followersCount + 1
              : _userProfile!.followersCount - 1,
          isFollowing: response.isFollowing!,
        );
        _isFollowLoading = false;
      });
    } else {
      setState(() => _isFollowLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _onSharePostTapped() async {
    if (widget.onSharePostTapped != null) {
      widget.onSharePostTapped!();
      return;
    }

    final newPost = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );

    if (newPost == true && mounted) {
      await _loadProfile();
    }
  }

  Future<void> _openPostScreen(String postId) async {
    final shouldRefresh = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PostScreen(postId: postId)),
    );

    if (shouldRefresh == true && mounted) {
      await _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.deepPurple, Colors.blue],
          ).createShader(bounds),
          child: const Text(
            'Profile',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
        ),
        leading: widget.showTopBanner
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.deepPurple),
              tooltip: 'Create Post',
              onPressed: _onSharePostTapped,
            ),
          ),
        ],
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userProfile == null
          ? _buildErrorState()
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: 110,
                  ), // ← added bottom padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(),
                      _buildUsernameBioSection(),
                      const SizedBox(height: 24),
                      UserPostsWidget(
                        profileUserId: _userProfile!.userId,
                        loggedInUserId: _loggedInUserId,
                        onPostTapped: _openPostScreen,
                        onSharePostTapped: _onSharePostTapped,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('No profile data available.'),
          const SizedBox(height: 8),
          Text(
            'User ID: ${widget.userId}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadProfile, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: _userProfile!.profilePicture.isNotEmpty
                ? NetworkImage(_userProfile!.profilePicture)
                : null,
            child: _userProfile!.profilePicture.isEmpty
                ? const Icon(Icons.person, size: 40)
                : null,
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Posts', _userProfile!.postsCount),
                _buildStatColumn(
                  'Followers',
                  _userProfile!.followersCount,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FollowersScreen(userId: widget.userId),
                      ),
                    );
                  },
                ),
                _buildStatColumn(
                  'Following',
                  _userProfile!.followingCount,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FollowingsScreen(userId: widget.userId),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsernameBioSection() {
    final hasBio = _userProfile!.bio.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _userProfile!.username,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          if (hasBio) ...[
            const SizedBox(height: 4),
            Text(_userProfile!.bio, style: const TextStyle(fontSize: 14)),
          ],
          const SizedBox(height: 8),
          if (_loggedInUserId == _userProfile!.userId)
            GestureDetector(
              onTap: () async {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const UpdateProfile()),
                );

                if (updated == true && mounted) {
                  await _loadProfile();
                }
              },
              child: const Text(
                'Update Profile',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          const SizedBox(height: 12),
          if (_loggedInUserId != _userProfile!.userId)
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: _userProfile!.isFollowing
                          ? null
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.deepPurple, Colors.blue],
                            ),
                      color: _userProfile!.isFollowing
                          ? Colors.grey.shade200
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      border: _userProfile!.isFollowing
                          ? Border.all(color: Colors.grey.shade300, width: 1.5)
                          : null,
                      boxShadow: _userProfile!.isFollowing
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.deepPurple.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isFollowLoading ? null : _handleFollowToggle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isFollowLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _userProfile!.isFollowing
                                      ? Colors.grey.shade600
                                      : Colors.white,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _userProfile!.isFollowing
                                      ? Icons.person_remove_rounded
                                      : Icons.person_add_rounded,
                                  size: 18,
                                  color: _userProfile!.isFollowing
                                      ? Colors.grey.shade700
                                      : Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _userProfile!.isFollowing
                                      ? 'Unfollow'
                                      : 'Follow',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: _userProfile!.isFollowing
                                        ? Colors.grey.shade700
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        final token = await getAccessToken();
                        if (_loggedInUserId != null && token != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ConversationScreen(
                                recipientUserId: _userProfile!.userId,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'You need to be logged in to chat.',
                              ),
                              backgroundColor: Colors.red.shade400,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.chat_bubble_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Message',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, int count, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
