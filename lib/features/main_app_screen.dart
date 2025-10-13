import 'package:flutter/material.dart';
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

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild screens to pass the callback to ProfileScreen
    final List<Widget> screens = [
      const FeedScreen(),
      ProfileScreen(
        onSharePostTapped: () {
          // Switch to CreatePostScreen tab
          setState(() {
            _currentIndex = 2;
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
        currentIndex: _currentIndex, // active tab index
        onTap: _onTabTapped, // switch tab on tap
        type: BottomNavigationBarType.fixed, // fixed type for multiple items
        selectedItemColor: Colors.blue, // highlight active tab
        unselectedItemColor: Colors.grey, // inactive tab color
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
