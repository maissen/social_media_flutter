import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:demo/utils/user_profile.dart'; // your API functions
import 'package:shared_preferences/shared_preferences.dart';

class UpdateProfile extends StatefulWidget {
  const UpdateProfile({super.key});

  @override
  State<UpdateProfile> createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile> {
  final TextEditingController _bioController = TextEditingController();
  bool _isLoading = false;
  bool _isFetching = true;
  XFile? _selectedImage; // Changed from File? to XFile?

  @override
  void initState() {
    super.initState();
    _loadUserBio();
  }

  Future<void> _loadUserBio() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';

      if (userId.isNotEmpty) {
        final profile = await fetchUserProfile(userId);
        _bioController.text = profile.bio;
      }
    } catch (e) {
      debugPrint('Failed to load user profile: $e');
    } finally {
      setState(() => _isFetching = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _selectedImage = pickedFile); // Store XFile directly
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);

    String message = '';

    // Update bio
    final bioResponse = await updateUserBio(_bioController.text);
    message += 'Bio: ${bioResponse.message}\n';

    // Update profile picture if selected
    if (_selectedImage != null) {
      // Pass the XFile for web or convert to File for mobile
      dynamic fileToUpload;
      if (kIsWeb) {
        fileToUpload = _selectedImage!; // XFile for web
      } else {
        fileToUpload = File(_selectedImage!.path); // File for mobile
      }

      final picResponse = await updateProfilePicture(fileToUpload);
      message += 'Profile Picture: ${picResponse.message}';

      // Clear selected image if successful
      if (picResponse.success) {
        setState(() => _selectedImage = null);
      }
    }

    setState(() => _isLoading = false);

    // Show combined result
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.trim()),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 4),
        ),
      );
    }

    // Optionally update bio field with returned value
    if (bioResponse.success) {
      _bioController.text = bioResponse.newBio ?? _bioController.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetching) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Update Profile'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Circular profile container
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[300],
                    ),
                    child: _selectedImage != null
                        ? ClipOval(
                            child: kIsWeb
                                ? Image.network(
                                    _selectedImage!.path,
                                    fit: BoxFit.cover,
                                    width: 140,
                                    height: 140,
                                  )
                                : Image.file(
                                    File(_selectedImage!.path),
                                    fit: BoxFit.cover,
                                    width: 140,
                                    height: 140,
                                  ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 70,
                            color: Colors.white,
                          ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.black),
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                ],
              ),
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

            // Update profile (bio & pic) button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
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
