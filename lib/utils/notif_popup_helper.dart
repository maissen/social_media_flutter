// notif_popup_helper.dart
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:demo/config/constants.dart';

/// Fetch and display notifications as popups
Future<void> pushNotifsPopup(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('user_id');

  if (userId == null) return;

  try {
    // Direct API call
    final url = Uri.parse(
      '${AppConstants.baseApiUrl}/notifications/new/$userId',
    );
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

/// Display a single notification popup at the top with gradient theme
void _showNotifPopup(BuildContext context, Map<String, dynamic> notification) {
  final message = notification['message'] ?? 'New notification';
  final date = notification['created_at'] ?? DateTime.now().toIso8601String();
  final formattedDate = DateFormat(
    'hh:mm a',
  ).format(DateTime.parse(date).toLocal());

  final iconData = _getNotifIcon(notification['type']);
  final iconColor = _getNotifIconColor(notification['type']);

  final overlay = Overlay.of(context);
  if (overlay == null) return;

  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) {
      return Positioned(
        top: MediaQuery.of(context).padding.top + 16, // below status bar
        left: 16,
        right: 16,
        child: _AnimatedNotifCard(
          icon: iconData,
          iconColor: iconColor,
          message: message,
          formattedDate: formattedDate,
          onDismissed: () {
            overlayEntry.remove();
          },
        ),
      );
    },
  );

  overlay.insert(overlayEntry);
}

/// Animated gradient notification card
class _AnimatedNotifCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String message;
  final String formattedDate;
  final VoidCallback onDismissed;

  const _AnimatedNotifCard({
    required this.icon,
    required this.iconColor,
    required this.message,
    required this.formattedDate,
    required this.onDismissed,
  });

  @override
  State<_AnimatedNotifCard> createState() => _AnimatedNotifCardState();
}

class _AnimatedNotifCardState extends State<_AnimatedNotifCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      await _controller.reverse();
      if (mounted) widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          color: Colors.transparent,
          elevation: 10,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Colors.deepPurple, Colors.blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Icon(widget.icon, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.message,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        widget.formattedDate,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
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

/// Map notification type → icon
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

/// Map notification type → color (used for accent/avatars if needed)
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
      return Colors.white;
  }
}
