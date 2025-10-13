import 'package:flutter/material.dart';
import 'package:demo/utils/user_profile.dart'; // import the file where updateUserBio is

class UpdateProfile extends StatefulWidget {
  const UpdateProfile({super.key});

  @override
  State<UpdateProfile> createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile> {
  final TextEditingController _bioController = TextEditingController();
  bool _isLoading = false;

  void _updateBio() async {
    setState(() => _isLoading = true);

    final response = await updateUserBio(_bioController.text);

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response.message),
        backgroundColor: response.success ? Colors.green : Colors.red,
      ),
    );

    if (response.success) {
      _bioController.text = response.newBio ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Profile'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Circular profile container
            Center(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                ),
                child: const Icon(Icons.person, size: 70, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),

            // Upload new profile picture button
            ElevatedButton(
              onPressed: () {},
              child: const Text('Upload New Profile Picture'),
            ),
            const SizedBox(height: 20),

            // Bio input
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'New Bio',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            // Update profile (bio) button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateBio,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Update Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
