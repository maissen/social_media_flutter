import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback? onSharePostTapped;

  const ProfileScreen({super.key, this.onSharePostTapped});

  @override
  Widget build(BuildContext context) {
    const userData = {
      "user_id": "v4",
      "email": "user@example.com",
      "username": "Maissen Belgacem",
      "bio": "Software developer and tech enthusiast",
      "profile_picture": "https://storage.com/profile.jpg",
      "followers_count": 150,
      "following_count": 200,
      "posts_count": 0,
      "is_following": false,
    };

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile info section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(
                      userData['profile_picture'] as String,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(
                          'Posts',
                          userData['posts_count'] as int,
                        ),
                        _buildStatColumn(
                          'Followers',
                          userData['followers_count'] as int,
                        ),
                        _buildStatColumn(
                          'Following',
                          userData['following_count'] as int,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Username & bio
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userData['username'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userData['bio'] as String,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: userData['is_following'] as bool
                            ? Colors.grey
                            : Colors.blue,
                      ),
                      child: Text(
                        (userData['is_following'] as bool)
                            ? 'Following'
                            : 'Follow',
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
              child: (userData['posts_count'] as int) == 0
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
