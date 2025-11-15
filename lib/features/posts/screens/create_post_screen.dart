import 'dart:io' show File;
import 'dart:convert';
import 'package:demo/config/constants.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../utils/categories_helpers.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isLoading = false;
  List<Category> _categories = [];
  bool _isCategoriesLoading = true;
  Set<int> _selectedCategoryIds = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await fetchCategories();
      setState(() {
        _categories = categories;
        _isCategoriesLoading = false;
      });
    } catch (e) {
      setState(() => _isCategoriesLoading = false);
      _showErrorSnackBar('Failed to load categories');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) setState(() => _selectedImage = image);
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[50],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _selectedImage = null);
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
      _selectedCategoryIds.clear();
    });
  }

  Future<void> _handleCreatePost() async {
    final content = _contentController.text.trim();

    if (_selectedImage == null) {
      _showErrorSnackBar('Please select an image');
      return;
    }

    if (_selectedCategoryIds.isEmpty) {
      _showErrorSnackBar('Please select at least one category');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';
      final url = Uri.parse('${AppConstants.baseApiUrl}/posts/create');

      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      if (content.isNotEmpty) request.fields['content'] = content;

      // Add category IDs
      request.fields['category_ids'] = jsonEncode(
        _selectedCategoryIds.toList(),
      );

      if (_selectedImage != null) {
        if (kIsWeb) {
          final bytes = await _selectedImage!.readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              'media_file',
              bytes,
              filename: _selectedImage!.name,
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        } else {
          request.files.add(
            await http.MultipartFile.fromPath(
              'media_file',
              _selectedImage!.path,
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final body = jsonDecode(response.body);

      setState(() => _isLoading = false);

      if (response.statusCode == 201 && body['success'] == true) {
        _showSuccessSnackBar(body['message'] ?? 'Post created successfully');
        _clearForm();
      } else {
        _showErrorSnackBar(body['message'] ?? 'Failed to create post');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('An error occurred: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Widget _buildCategoryChip(Category category) {
    final isSelected = _selectedCategoryIds.contains(category.id);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedCategoryIds.remove(category.id);
          } else {
            _selectedCategoryIds.add(category.id);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Colors.deepPurple, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Colors.deepPurple.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 8 : 4,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.check_circle, color: Colors.white, size: 18),
              ),
            Text(
              category.name,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[800],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    if (_isCategoriesLoading) {
      return Container(
        height: 60,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    if (_categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No categories available',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Split categories into 3 rows
    final itemsPerRow = (_categories.length / 3).ceil();
    final row1 = _categories.take(itemsPerRow).toList();
    final row2 = _categories.skip(itemsPerRow).take(itemsPerRow).toList();
    final row3 = _categories.skip(itemsPerRow * 2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.deepPurple, Colors.blue],
                ).createShader(bounds),
                child: const Text(
                  'Select Categories',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _selectedCategoryIds.isEmpty
                      ? Colors.red[50]
                      : Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selectedCategoryIds.length} selected',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _selectedCategoryIds.isEmpty
                        ? Colors.red[700]
                        : Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 170,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1
                  SizedBox(
                    height: 50,
                    child: Row(
                      children: row1
                          .map((category) => _buildCategoryChip(category))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Row 2
                  SizedBox(
                    height: 50,
                    child: Row(
                      children: row2
                          .map((category) => _buildCategoryChip(category))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Row 3
                  SizedBox(
                    height: 50,
                    child: Row(
                      children: row3
                          .map((category) => _buildCategoryChip(category))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.deepPurple, Colors.blue],
          ).createShader(bounds),
          child: const Text(
            'Create new post',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          color: Colors.grey[100],
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              children: [
                // Image card
                GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _selectedImage != null
                          ? (kIsWeb
                                ? Image.network(
                                    _selectedImage!.path,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(_selectedImage!.path),
                                    fit: BoxFit.cover,
                                  ))
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        colors: [
                                          Colors.deepPurple,
                                          Colors.blue,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds),
                                  child: const Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 80,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        colors: [
                                          Colors.deepPurple,
                                          Colors.blue,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds),
                                  child: const Text(
                                    'Tap to add photo',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Categories section
                _buildCategoriesSection(),

                const SizedBox(height: 24),

                // Caption text field
                TextField(
                  controller: _contentController,
                  maxLines: 5,
                  maxLength: 400,
                  decoration: InputDecoration(
                    hintText: 'Write a caption...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Post button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.deepPurple, Colors.blue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading ? null : _handleCreatePost,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.cloud_upload_outlined,
                              color: Colors.white,
                            ),
                      label: Text(
                        _isLoading ? 'Posting...' : 'Share Post',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
