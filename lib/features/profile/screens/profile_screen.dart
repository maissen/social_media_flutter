// lib/features/profile/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:demo/utils/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demo/features/profile/screens/follow_screen.dart';
import 'package:demo/features/profile/screens/update_profile.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onSharePostTapped;
  final String userId;

  const ProfileScreen({
    super.key,
    this.onSharePostTapped,
    required this.userId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _loggedInUserId;

  @override
  void initState() {
    super.initState();
    _loadLoggedInUserId();
  }

  Future<void> _loadLoggedInUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _loggedInUserId = prefs.getString('user_id');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<UserProfile>(
        future: fetchUserProfile(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No profile data available.'));
          }

          final userData = snapshot.data!;
          final isOwnProfile = _loggedInUserId == userData.userId;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile info section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(userData.profilePicture),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn('Posts', userData.postsCount),
                            _buildStatColumn(
                              'Followers',
                              userData.followersCount,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const FollowScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildStatColumn(
                              'Following',
                              userData.followingCount,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const FollowScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Username & Bio + Follow / Update Profile
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(userData.bio, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 8),

                      // "Update Profile" link for own profile
                      if (isOwnProfile)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const UpdateProfile(),
                              ),
                            );
                          },
                          child: const Text(
                            'Update Profile',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Follow button only for other users
                      if (!isOwnProfile)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: userData.isFollowing
                                  ? Colors.grey
                                  : Colors.blue,
                            ),
                            child: Text(
                              userData.isFollowing ? 'Following' : 'Follow',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const Divider(height: 32),

                // Posts section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: userData.postsCount == 0
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'No posts shared yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (isOwnProfile)
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
                ),
              ],
            ),
          );
        },
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
