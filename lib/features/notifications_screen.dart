import 'dart:async';
import 'package:demo/utils/user_helpers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  bool _isFetching = false; // Prevent overlapping API calls

  @override
  void initState() {
    super.initState();
    _loadNotifications(); // Load notifications only once when screen loads
  }

  Future<void> _loadNotifications() async {
    _isFetching = true;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId == null) {
      setState(() {
        _notifications = [];
        _isLoading = false;
      });
      _isFetching = false;
      return;
    }

    try {
      final response = await fetchNotifications(userId: userId);

      if (response.success && response.notifications != null) {
        setState(() {
          _notifications = response.notifications!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _notifications = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _notifications = [];
        _isLoading = false;
      });
    }

    _isFetching = false;
  }

  Future<void> _refreshNotifications() async {
    await _loadNotifications();
  }

  String formatDateTime(String isoDate) {
    final date = DateTime.parse(isoDate).toLocal();
    final formatter = DateFormat(
      'MMM dd, yyyy – hh:mm a',
    ); // e.g., Oct 15, 2025 – 10:39 AM
    return formatter.format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // keep screen background white
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white, // keep AppBar background white
        leading: IconButton(
          icon: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.deepPurple, Colors.blue],
            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.deepPurple, Colors.blue],
          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          child: const Text(
            'Notifications',
            style: TextStyle(
              color: Colors.white, // overridden by gradient
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _refreshNotifications,
              child: ListView.builder(
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  return _buildNotificationTile(notification);
                },
              ),
            ),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> notification) {
    IconData icon;
    Color iconColor;

    switch (notification['type']) {
      case 'like post':
        icon = Icons.favorite;
        iconColor = Colors.red;
        break;
      case 'create post':
        icon = Icons.post_add;
        iconColor = Colors.orange;
        break;
      case 'create comment':
        icon = Icons.comment;
        iconColor = Colors.blue;
        break;
      case 'like comment':
        icon = Icons.thumb_up;
        iconColor = Colors.purple;
        break;
      case 'unfollow':
        icon = Icons.person_off;
        iconColor = Colors.grey;
        break;
      case 'follow':
        icon = Icons.person_add;
        iconColor = Colors.green;
        break;
      case 'update profile picture':
        icon = Icons.person;
        iconColor = Colors.teal;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.15),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(notification['message'] ?? ''),
      subtitle: Text(
        notification['created_at'] != null
            ? formatDateTime(notification['created_at'])
            : 'Just now',
        style: const TextStyle(
          color: Colors.grey, // make time gray
          fontSize: 13, // optional: slightly smaller font
        ),
      ),
      onTap: () {},
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No notifications yet.',
        style: TextStyle(color: Colors.grey, fontSize: 16),
      ),
    );
  }
}
