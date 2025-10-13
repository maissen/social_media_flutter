// lib/features/profile/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:demo/utils/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demo/features/profile/screens/update_profile.dart';
import 'package:demo/utils/user_helpers.dart';
import 'package:demo/features/profile/screens/followers_screen.dart';
import 'package:demo/features/profile/screens/followings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onSharePostTapped;
  final String userId;
  final bool showTopBanner;

  const ProfileScreen({
    super.key,
    this.onSharePostTapped,
    required this.userId,
    this.showTopBanner = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  String? _loggedInUserId;
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isFollowLoading = false;

  @override
  bool get wantKeepAlive => false;

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
    try {
      final profile = await fetchUserProfile(widget.userId);

      final prefs = await SharedPreferences.getInstance();
      final cachedFollowState = prefs.getBool('follow_state_${widget.userId}');

      setState(() {
        _userProfile = profile;
        if (cachedFollowState != null) {
          _userProfile = UserProfile(
            userId: profile.userId,
            email: profile.email,
            username: profile.username,
            bio: profile.bio,
            profilePicture: profile.profilePicture,
            followersCount: profile.followersCount,
            followingCount: profile.followingCount,
            postsCount: profile.postsCount,
            isFollowing: cachedFollowState,
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleFollowToggle() async {
    if (_userProfile == null || _isFollowLoading) return;

    setState(() {
      _isFollowLoading = true;
    });

    final response = await toggleFollow(targetUserId: widget.userId);

    if (response.success && response.isFollowing != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        'follow_state_${widget.userId}',
        response.isFollowing!,
      );

      setState(() {
        _userProfile = UserProfile(
          userId: _userProfile!.userId,
          email: _userProfile!.email,
          username: _userProfile!.username,
          bio: _userProfile!.bio,
          profilePicture: _userProfile!.profilePicture,
          followersCount: response.isFollowing!
              ? _userProfile!.followersCount + 1
              : _userProfile!.followersCount - 1,
          followingCount: _userProfile!.followingCount,
          postsCount: _userProfile!.postsCount,
          isFollowing: response.isFollowing!,
        );
        _isFollowLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      setState(() {
        _isFollowLoading = false;
      });

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

  @override
  Widget build(BuildContext context) {
    super.build(context); // for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: widget.showTopBanner
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              elevation: 0,
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userProfile == null
          ? _buildErrorState()
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(),
                  _buildUsernameBioSection(),
                  const Divider(height: 32),
                  _buildPostsSection(),
                ],
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
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadProfile();
            },
            child: const Text('Retry'),
          ),
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
            backgroundImage: NetworkImage(_userProfile!.profilePicture),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _userProfile!.username,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(_userProfile!.bio, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          if (_loggedInUserId == _userProfile!.userId)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UpdateProfile()),
                );
              },
              child: const Text(
                'Update Profile',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          const SizedBox(height: 12),
          if (_loggedInUserId != _userProfile!.userId)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isFollowLoading ? null : _handleFollowToggle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _userProfile!.isFollowing
                      ? Colors.grey
                      : Colors.blue,
                ),
                child: _isFollowLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(_userProfile!.isFollowing ? 'Unfollow' : 'Follow'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _userProfile!.postsCount == 0
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'No posts shared yet',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (_loggedInUserId == _userProfile!.userId)
                  ElevatedButton(
                    onPressed: widget.onSharePostTapped,
                    child: const Text('Share a Post'),
                  ),
              ],
            )
          : const Text(
              'Posts Grid goes here',
              style: TextStyle(color: Colors.grey),
            ),
    );
  }

  Widget _buildStatColumn(String label, int count, {VoidCallback? onTap}) {
    final content = Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }
}
