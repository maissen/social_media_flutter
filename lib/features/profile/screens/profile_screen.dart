// lib/features/profile/screens/profile_screen.dart
import 'package:demo/features/posts/screens/create_post_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demo/utils/user_profile.dart';
import 'package:demo/utils/user_helpers.dart';
import 'package:demo/features/profile/screens/update_profile.dart';
import 'package:demo/features/profile/screens/followers_screen.dart';
import 'package:demo/features/profile/screens/followings_screen.dart';
import 'package:demo/features/profile/widgets/user_posts_widget.dart';

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

      setState(() {
        _userProfile = profile; // always use server value
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFollowToggle() async {
    if (_userProfile == null || _isFollowLoading) return;

    setState(() => _isFollowLoading = true);

    final response = await toggleFollow(targetUserId: widget.userId);

    if (response.success && response.isFollowing != null) {
      // Optimistically update UI without showing a SnackBar
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
      // Show SnackBar only on error
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
    } else {
      final newPost = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const CreatePostScreen()),
      );

      if (newPost == true) {
        setState(() {
          _userProfile = _userProfile!.copyWith(
            postsCount: _userProfile!.postsCount + 1,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  const SizedBox(height: 24),
                  UserPostsWidget(
                    profileUserId: _userProfile!.userId,
                    loggedInUserId: _loggedInUserId,
                    onSharePostTapped: _onSharePostTapped,
                  ),
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
