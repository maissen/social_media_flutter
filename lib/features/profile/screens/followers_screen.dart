import 'package:flutter/material.dart';
import 'package:demo/features/profile/screens/profile_screen.dart';
import 'package:demo/utils/user_helpers.dart';

class FollowersScreen extends StatefulWidget {
  final String userId; // the user whose followers we want to display
  const FollowersScreen({super.key, required this.userId});

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchFollowers();
  }

  Future<void> _fetchFollowers() async {
    setState(() => _isLoading = true);

    final response = await getFollowers(userId: widget.userId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _users = response.success ? response.users ?? [] : [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Followers'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
          ? _buildEmptyState()
          : _buildUserList(),
    );
  }

  Widget _buildUserList() {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8),
      itemCount: _users.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.grey),
      itemBuilder: (context, index) {
        final user = _users[index];

        return ListTile(
          leading: CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(
              user['profile_picture'] ?? 'https://via.placeholder.com/150',
            ),
          ),
          title: Text(
            user['username'] ?? 'Unknown',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            user['bio'] ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            final userId = user['user_id']?.toString();
            if (userId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProfileScreen(userId: userId, showTopBanner: true),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.people, size: 64, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'No followers to display',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
