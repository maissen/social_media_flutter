// notif_popup_helper.dart
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

Future<void> pushNotifsPopup(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('user_id');

  if (userId == null) return;

  try {
    // Directly call the API
    final url = Uri.parse('http://localhost:8000/notifications/new/$userId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List && data.isNotEmpty) {
        for (var notification in data) {
          if (notification['is_read'] == true) continue;

          _showNotifPopup(context, notification);
        }
      }
    } else {
      debugPrint('API error: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint("Failed to fetch notifications: $e");
  }
}

void _showNotifPopup(BuildContext context, Map<String, dynamic> notification) {
  final message = notification['message'] ?? 'New notification';
  final date = notification['created_at'] ?? DateTime.now().toIso8601String();
  final formattedDate = DateFormat(
    'hh:mm a',
  ).format(DateTime.parse(date).toLocal());

  final iconData = _getNotifIcon(notification['type']);
  final iconColor = _getNotifIconColor(notification['type']);

  final snackBar = SnackBar(
    content: Row(
      children: [
        CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.2),
          child: Icon(iconData, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                formattedDate,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    ),
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 3),
  );

  ScaffoldMessenger.of(context)
    ..removeCurrentSnackBar()
    ..showSnackBar(snackBar);
}

IconData _getNotifIcon(String? type) {
  switch (type) {
    case 'post like':
      return Icons.favorite;
    case 'comment like':
      return Icons.thumb_up;
    case 'create post':
      return Icons.post_add;
    case 'create comment':
      return Icons.comment;
    case 'follow':
      return Icons.person_add;
    case 'unfollow':
      return Icons.person_off;
    case 'update profile picture':
      return Icons.person;
    default:
      return Icons.notifications;
  }
}

Color _getNotifIconColor(String? type) {
  switch (type) {
    case 'post like':
      return Colors.red;
    case 'comment like':
      return Colors.purple;
    case 'create post':
      return Colors.orange;
    case 'create comment':
      return Colors.blue;
    case 'follow':
      return Colors.green;
    case 'unfollow':
      return Colors.grey;
    case 'update profile picture':
      return Colors.teal;
    default:
      return Colors.grey;
  }
}
