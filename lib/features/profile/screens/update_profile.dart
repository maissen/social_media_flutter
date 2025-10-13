import 'package:flutter/material.dart';

class UpdateProfile extends StatelessWidget {
  const UpdateProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Profile'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Circular profile container (bigger)
            Center(
              child: Container(
                width: 140, // increased size
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                ),
                child: const Icon(Icons.person, size: 70, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),

            // Upload new profile picture button (placeholder, above bio)
            ElevatedButton(
              onPressed: () {
                // Placeholder
              },
              child: const Text('Upload New Profile Picture'),
            ),
            const SizedBox(height: 20),

            // Input for new bio
            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'New Bio',
              ),
              maxLines: 3,
            ),
            const Spacer(),

            // Bottom update profile button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Placeholder
                },
                child: const Text('Update Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
