import 'package:flutter/material.dart';
import 'package:demo/utils/user_profile.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback? onSharePostTapped;
  final String userId;

  const ProfileScreen({
    super.key,
    this.onSharePostTapped,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<UserProfile>(
        future: fetchUserProfile(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Loading indicator while fetching data
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Show error message
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            // No data returned
            return const Center(child: Text('No profile data available.'));
          }

          // Data loaded successfully
          final userData = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
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
                            ),
                            _buildStatColumn(
                              'Following',
                              userData.followingCount,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Username & Bio
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
                      const SizedBox(height: 12),
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
                          mainAxisAlignment: MainAxisAlignment.center,
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
                            ElevatedButton(
                              onPressed: onSharePostTapped,
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

  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}
