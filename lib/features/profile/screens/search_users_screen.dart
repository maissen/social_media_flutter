import 'dart:async';
import 'package:flutter/material.dart';
import 'package:demo/utils/user_helpers.dart';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;
  List<Map<String, dynamic>> _users = [];

  // Debounced search
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (query.isEmpty) {
        setState(() => _users = []);
        return;
      }

      setState(() => _isLoading = true);

      final response = await searchUsers(
        username: query,
      ); // ✅ named parameter fixed

      if (mounted) {
        setState(() {
          _isLoading = false;
          _users = response.success ? response.users ?? [] : [];
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey, width: 0.2),
              ),
            ),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _controller,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _controller.text.isEmpty
          ? _buildRecentSearchesPlaceholder()
          : _users.isEmpty
          ? const Center(
              child: Text(
                'No users found',
                style: TextStyle(color: Colors.grey),
              ),
            )
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
          trailing: TextButton(
            onPressed: () {
              // TODO: implement follow/unfollow
            },
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
          onTap: () {
            // TODO: Navigate to user profile page
          },
        );
      },
    );
  }

  Widget _buildRecentSearchesPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.search, size: 64, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'Search for people',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
