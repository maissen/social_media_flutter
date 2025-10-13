import 'dart:io' show File;
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:demo/utils/posts_helpers.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage; // Use XFile for cross-platform support
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to take photo: $e');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              if (_selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearForm() {
    setState(() {
      _contentController.clear();
      _selectedImage = null;
    });
  }

  Future<void> _handleCreatePost() async {
    final content = _contentController.text.trim();

    // Validate input - image is required
    if (_selectedImage == null) {
      _showErrorSnackBar('Please select an image');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare File for mobile, or null for web
      File? fileToUpload;
      if (!kIsWeb && _selectedImage != null) {
        fileToUpload = File(_selectedImage!.path);
      }

      final response = await createPost(
        content: content.isNotEmpty ? content : null,
        mediaFile: fileToUpload,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (response.success) {
          _showSuccessSnackBar(response.message);
          _clearForm(); // Clear form instead of closing screen
        } else {
          _showErrorSnackBar(response.message);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('An error occurred: $e');
      }
    }
  }

  Future<void> _handleBackNavigation() async {
    if (_contentController.text.isNotEmpty || _selectedImage != null) {
      final shouldDiscard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard Post?'),
          content: const Text(
            'Are you sure you want to discard your post draft?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (shouldDiscard == true && mounted) {
        Navigator.pop(context);
      }
    } else {
      Navigator.pop(context);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _handleCreatePost,
              child: const Text(
                'Share',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Preview
            if (_selectedImage != null)
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 400,
                    decoration: BoxDecoration(color: Colors.grey[200]),
                    child: kIsWeb
                        ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                        : Image.file(
                            File(_selectedImage!.path),
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            else
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 80,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tap to add photo',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Caption Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Caption',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contentController,
                    maxLines: 5,
                    maxLength: 2200,
                    decoration: InputDecoration(
                      hintText: 'Write a caption...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Change Photo Button
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  onPressed: _showImageSourceDialog,
                  icon: const Icon(Icons.edit),
                  label: const Text('Change Photo'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
