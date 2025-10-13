import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data from your API response
    const userData = {
      "user_id": "v4",
      "email": "user@example.com",
      "username": "johndoe",
      "bio": "Software developer and tech enthusiast",
      "profile_picture": "https://storage.com/profile.jpg",
      "followers_count": 150,
      "following_count": 200,
      "posts_count": 45,
      "is_following": false,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(userData['username'] as String),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Info Section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Row(
                children: [
                  // Profile Picture
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(
                      userData['profile_picture'] as String,
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Posts, Followers, Following
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

            // Username & Bio
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
                  // Follow Button
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

            // Placeholder for Posts Grid
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
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
