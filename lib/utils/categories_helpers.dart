import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(id: json['id'], name: json['name']);
  }
}

Future<List<Category>> fetchCategories() async {
  final url = Uri.parse('${AppConstants.baseApiUrl}/categories');

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);

      return jsonList.map((item) => Category.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load categories: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error loading categories: $e');
  }
}
