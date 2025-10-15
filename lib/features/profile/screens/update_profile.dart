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
  String _currentProfilePicture = ''; // Store current profile picture URL

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';

      if (userId.isNotEmpty) {
        final profile = await fetchUserProfile(userId);
        _bioController.text = profile.bio;
        _currentProfilePicture = profile.profilePicture;
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

    bool bioSuccess = false;
    bool picSuccess = false;
    String? newProfilePicUrl;

    // Update bio
    final bioResponse = await updateUserBio(_bioController.text);
    bioSuccess = bioResponse.success;

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
      picSuccess = picResponse.success;

      // Clear selected image and update profile picture if successful
      if (picResponse.success) {
        newProfilePicUrl = picResponse.fileUrl;
        setState(() {
          _selectedImage = null;
          if (newProfilePicUrl != null) {
            _currentProfilePicture = newProfilePicUrl;
          }
        });
      }
    }

    setState(() => _isLoading = false);

    // Show single success or error message
    String message;
    Color backgroundColor;

    if (_selectedImage == null && bioSuccess) {
      // Only bio was updated
      message = 'Profile updated successfully';
      backgroundColor = Colors.green;
    } else if (_selectedImage != null && bioSuccess && picSuccess) {
      // Both were updated
      message = 'Profile updated successfully';
      backgroundColor = Colors.green;
    } else if (!bioSuccess && _selectedImage != null && !picSuccess) {
      // Both failed
      message = 'Failed to update profile';
      backgroundColor = Colors.red;
    } else if (!bioSuccess || (_selectedImage != null && !picSuccess)) {
      // Partial success
      message = 'Profile partially updated';
      backgroundColor = Colors.orange;
    } else {
      message = 'Profile updated successfully';
      backgroundColor = Colors.green;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    // Update bio field with returned value
    if (bioSuccess) {
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
                    child: ClipOval(
                      child: _selectedImage != null
                          ? (kIsWeb
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
                                  ))
                          : (_currentProfilePicture.isNotEmpty
                                ? Image.network(
                                    _currentProfilePicture,
                                    fit: BoxFit.cover,
                                    width: 140,
                                    height: 140,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.person,
                                        size: 70,
                                        color: Colors.white,
                                      );
                                    },
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 70,
                                    color: Colors.white,
                                  )),
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
                labelText: 'Enter your new bio',
                counterText: '', // Optional: hides the default counter text
              ),
              maxLines: 3,
              maxLength: 150,
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
