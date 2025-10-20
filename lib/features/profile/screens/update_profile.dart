import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:demo/utils/user_profile.dart';
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
  XFile? _selectedImage;
  String _currentProfilePicture = '';

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
      setState(() => _selectedImage = pickedFile);
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);

    bool bioSuccess = false;
    bool picSuccess = false;
    String? newProfilePicUrl;

    final bioResponse = await updateUserBio(_bioController.text);
    bioSuccess = bioResponse.success;

    if (_selectedImage != null) {
      dynamic fileToUpload = kIsWeb
          ? _selectedImage!
          : File(_selectedImage!.path);
      final picResponse = await updateProfilePicture(fileToUpload);
      picSuccess = picResponse.success;

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

    String message;
    Color backgroundColor;

    if (_selectedImage == null && bioSuccess) {
      message = 'Profile updated successfully';
      backgroundColor = Colors.green;
    } else if (_selectedImage != null && bioSuccess && picSuccess) {
      message = 'Profile updated successfully';
      backgroundColor = Colors.green;
    } else if (!bioSuccess && _selectedImage != null && !picSuccess) {
      message = 'Failed to update profile';
      backgroundColor = Colors.red;
    } else if (!bioSuccess || (_selectedImage != null && !picSuccess)) {
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade50,
              Colors.blue.shade50,
              Colors.deepPurple.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 🔙 Centered title bar with back arrow
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.deepPurple, Colors.blue],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurple.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.deepPurple, Colors.blue],
                          ).createShader(bounds),
                          child: const Text(
                            'Update Profile',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),

                    // Profile Picture
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurple.withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
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
                                            errorBuilder:
                                                (context, error, stackTrace) {
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
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Colors.deepPurple, Colors.blue],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.deepPurple.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                ),
                                onPressed: _pickImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Bio input
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            child: TextField(
                              controller: _bioController,
                              decoration: InputDecoration(
                                labelText: 'Enter your new bio',
                                prefixIcon: Icon(
                                  Icons.edit,
                                  color: Colors.deepPurple.shade300,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(20),
                                labelStyle: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              maxLines: 3,
                              maxLength: 150,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Update Button
                    _isLoading
                        ? Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.deepPurple, Colors.blue],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Colors.deepPurple, Colors.blue],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurple.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _updateProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Update Profile',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
