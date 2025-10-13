import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/feed/screens/feed_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/posts/screens/create_post_screen.dart';
import '../features/profile/screens/search_users_screen.dart';
import '../features/feed/screens/explore_screen.dart';

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;
  String? _loggedInUserId;

  @override
  void initState() {
    super.initState();
    _loadLoggedInUserId();
  }

  Future<void> _loadLoggedInUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Replace 'user_id' with the key you store the logged-in user's ID
      _loggedInUserId = prefs.getString('user_id') ?? '';
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // If the user ID is not loaded yet, show a loading indicator
    if (_loggedInUserId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Widget> screens = [
      const FeedScreen(),
      // Pass the logged-in user ID to ProfileScreen
      ProfileScreen(
        userId: _loggedInUserId!,
        onSharePostTapped: () {
          setState(() {
            _currentIndex = 2; // Switch to CreatePostScreen tab
          });
        },
      ),
      const CreatePostScreen(),
      const SearchUsersScreen(),
      const ExploreScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.create), label: 'Post'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
        ],
      ),
    );
  }
}
