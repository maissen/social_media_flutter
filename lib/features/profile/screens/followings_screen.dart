import 'package:flutter/material.dart';
import 'package:demo/utils/user_helpers.dart';

class FollowingsScreen extends StatefulWidget {
  final String userId; // the user whose followings we want to display
  const FollowingsScreen({super.key, required this.userId});

  @override
  State<FollowingsScreen> createState() => _FollowingsScreenState();
}

class _FollowingsScreenState extends State<FollowingsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  final Map<String, bool> _isFollowLoading = {}; // track loading per user

  @override
  void initState() {
    super.initState();
    _fetchFollowings();
  }

  Future<void> _fetchFollowings() async {
    setState(() => _isLoading = true);

    final response = await getFollowings(userId: widget.userId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _users = response.success ? response.users ?? [] : [];
        // initialize follow loading state and normalize user_id to String
        for (var user in _users) {
          final userId = user['user_id']?.toString();
          if (userId != null && !_isFollowLoading.containsKey(userId)) {
            _isFollowLoading[userId] = false;
          }
        }
      });
    }
  }

  void _onFollowButtonPressed(Map<String, dynamic> user) async {
    final userId = user['user_id']?.toString();
    if (userId == null) return;

    setState(() => _isFollowLoading[userId] = true);

    final response = await toggleFollow(targetUserId: userId);

    if (mounted) {
      setState(() {
        _isFollowLoading[userId] = false;
        if (response.success && response.isFollowing != null) {
          user['is_following'] = response.isFollowing;
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(response.message)));
        }
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
        title: const Text('Following'),
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
        final userId = user['user_id']?.toString();

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
          trailing: SizedBox(
            width: 90,
            child: (userId != null && (_isFollowLoading[userId] ?? false))
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    onPressed: userId != null
                        ? () => _onFollowButtonPressed(user)
                        : null,
                    style: TextButton.styleFrom(
                      foregroundColor: user['is_following'] == true
                          ? Colors.black
                          : Colors.white,
                      backgroundColor: user['is_following'] == true
                          ? Colors.grey[300]
                          : Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      minimumSize: const Size(70, 32),
                    ),
                    child: Text(
                      user['is_following'] == true ? 'Following' : 'Follow',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: user['is_following'] == true
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),
                  ),
          ),
          onTap: () {
            // TODO: Navigate to user profile page
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
            'No users to display',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
