import 'dart:async';
import 'package:demo/utils/user_helpers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  Timer? _timer; // Timer to refresh every second
  bool _isFetching = false; // Prevent overlapping API calls

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!_isFetching) {
        await _loadNotifications();
      }
    });
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

  String timeAgo(String isoDate) {
    final date = DateTime.parse(isoDate).toLocal();
    final diff = DateTime.now().difference(date);

    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), elevation: 0),
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
            ? timeAgo(notification['created_at'])
            : 'Just now',
      ),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tapped: ${notification['message']}')),
        );
      },
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
