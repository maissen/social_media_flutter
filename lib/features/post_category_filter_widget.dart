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
                          // "All Categories" option
                          if (index == 0) {
                            final isSelected =
                                widget.selectedCategoryId == null;
                            return ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? const LinearGradient(
                                          colors: [
                                            Colors.deepPurple,
                                            Colors.blue,
                                          ],
                                        )
                                      : null,
                                  color: isSelected ? null : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.select_all,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[600],
                                  size: 22,
                                ),
                              ),
                              title: const Text(
                                'All Categories',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.deepPurple,
                                    )
                                  : null,
                              onTap: () {
                                Navigator.pop(context);
                                widget.onCategorySelected(null, null);
                              },
                            );
                          }

                          // Category options
                          final category = _categories[index - 1];
                          final isSelected =
                              widget.selectedCategoryId == category.id;

                          return ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? const LinearGradient(
                                        colors: [
                                          Colors.deepPurple,
                                          Colors.blue,
                                        ],
                                      )
                                    : null,
                                color: isSelected ? null : Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  _getEmoji(category.name),
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                            title: Text(
                              category.name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.deepPurple,
                                  )
                                : null,
                            onTap: () {
                              Navigator.pop(context);
                              widget.onCategorySelected(
                                category.id,
                                category.name,
                              );
                            },
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

  String _getEmoji(String categoryName) {
    // Extract emoji from category name if it exists
    final emojiRegex = RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true);
    final match = emojiRegex.firstMatch(categoryName);
    if (match != null) {
      return match.group(0)!;
    }
    // Default emojis based on category name
    if (categoryName.toLowerCase().contains('art')) return '🎨';
    if (categoryName.toLowerCase().contains('music')) return '🎵';
    if (categoryName.toLowerCase().contains('sport')) return '⚽';
    if (categoryName.toLowerCase().contains('food')) return '🍔';
    if (categoryName.toLowerCase().contains('travel')) return '✈️';
    if (categoryName.toLowerCase().contains('tech')) return '💻';
    if (categoryName.toLowerCase().contains('game')) return '🎮';
    if (categoryName.toLowerCase().contains('ai') ||
        categoryName.toLowerCase().contains('artificial'))
      return '🤖';
    return '📁'; // Default category icon
  }

  String? _getSelectedCategoryName() {
    if (widget.selectedCategoryId == null) return null;
    final category = _categories.firstWhere(
      (cat) => cat.id == widget.selectedCategoryId,
      orElse: () => Category(id: 0, name: 'Unknown'),
    );
    return category.name;
  }

  @override
  Widget build(BuildContext context) {
    final selectedName = _getSelectedCategoryName();
    final isFiltered = widget.selectedCategoryId != null;

    return Container(
      decoration: BoxDecoration(
        gradient: isFiltered
            ? const LinearGradient(
                colors: [Colors.deepPurple, Colors.blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isFiltered ? null : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFiltered ? Colors.transparent : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _showCategoryBottomSheet,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isFiltered ? Icons.filter_alt : Icons.filter_alt_outlined,
                  size: 20,
                  color: isFiltered ? Colors.white : Colors.grey[700],
                ),
                const SizedBox(width: 8),
                Text(
                  isFiltered && selectedName != null
                      ? selectedName.length > 20
                            ? '${selectedName.substring(0, 20)}...'
                            : selectedName
                      : 'Filter',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isFiltered ? Colors.white : Colors.grey[700],
                  ),
                ),
                if (isFiltered) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, size: 20, color: Colors.white),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
