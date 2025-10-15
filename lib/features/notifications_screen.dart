import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));

    // Dummy notifications — replace with API response later
    setState(() {
      _notifications = [
        {
          'id': 1,
          'type': 'like',
          'message': 'John liked your post',
          'time': '2h ago',
        },
        {
          'id': 2,
          'type': 'follow',
          'message': 'Alice started following you',
          'time': '5h ago',
        },
        {
          'id': 3,
          'type': 'comment',
          'message': 'Mike commented on your photo',
          'time': '1d ago',
        },
      ];
      _isLoading = false;
    });
  }

  Future<void> _refreshNotifications() async {
    await _loadNotifications();
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
      case 'like':
        icon = Icons.favorite;
        iconColor = Colors.red;
        break;
      case 'comment':
        icon = Icons.comment;
        iconColor = Colors.blue;
        break;
      case 'follow':
        icon = Icons.person_add;
        iconColor = Colors.green;
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
      title: Text(notification['message']),
      subtitle: Text(notification['time']),
      onTap: () {
        // Example: Navigate to a post or profile later
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
