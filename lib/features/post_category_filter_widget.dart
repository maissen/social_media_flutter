import 'package:flutter/material.dart';
import 'package:demo/utils/categories_helpers.dart';

class CategoryFilterButton extends StatefulWidget {
  final int? selectedCategoryId;
  final Function(int? categoryId, String? categoryName) onCategorySelected;

  const CategoryFilterButton({
    Key? key,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  State<CategoryFilterButton> createState() => _CategoryFilterButtonState();
}

class _CategoryFilterButtonState extends State<CategoryFilterButton> {
  List<Category> _categories = [];
  bool _isLoadingCategories = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);

    try {
      final categories = await fetchCategories();
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load categories: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCategoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.deepPurple, Colors.blue],
                      ).createShader(bounds),
                      child: const Text(
                        'Filter by Category',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (widget.selectedCategoryId != null)
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onCategorySelected(null, null);
                        },
                        child: const Text('Clear'),
                      ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Categories list
              Expanded(
                child: _isLoadingCategories
                    ? const Center(child: CircularProgressIndicator())
                    : _categories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.category_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No categories available',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadCategories,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _categories.length + 1,
                        itemBuilder: (context, index) {
                          // Leading width for tick icons
                          const leadingWidth = 24.0;

                          // "All Categories" option
                          if (index == 0) {
                            final isSelected =
                                widget.selectedCategoryId == null;
                            return ListTile(
                              leading: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.deepPurple,
                                    )
                                  : const SizedBox(width: leadingWidth),
                              title: Text(
                                'All Categories',
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                widget.onCategorySelected(null, null);
                              },
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            );
                          }

                          // Category options
                          final category = _categories[index - 1];
                          final isSelected =
                              widget.selectedCategoryId == category.id;

                          return ListTile(
                            leading: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.deepPurple,
                                  )
                                : const SizedBox(width: leadingWidth),
                            title: Text(
                              category.name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              widget.onCategorySelected(
                                category.id,
                                category.name,
                              );
                            },
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFiltered = widget.selectedCategoryId != null;

    return IconButton(
      icon: Icon(
        isFiltered ? Icons.filter_alt : Icons.filter_alt_outlined,
        color: Colors.blue,
      ),
      onPressed: _showCategoryBottomSheet,
      tooltip: 'Filter by Category',
    );
  }
}
