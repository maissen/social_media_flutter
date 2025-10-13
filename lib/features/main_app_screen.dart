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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLoggedInUserId();
  }

  Future<void> _loadLoggedInUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    // Debug: Print the user ID
    print('Loaded user_id from SharedPreferences: $userId');

    setState(() {
      _loggedInUserId = userId;
      _isLoading = false;
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while fetching user ID
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If user ID is still null after loading, show error
    if (_loggedInUserId == null || _loggedInUserId!.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to load user data'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadLoggedInUserId,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Build the current screen based on index
    Widget currentScreen;
    switch (_currentIndex) {
      case 0:
        currentScreen = const FeedScreen();
        break;
      case 1:
        currentScreen = ProfileScreen(
          key: ValueKey(
            'profile_$_loggedInUserId',
          ), // Unique key to force rebuild
          userId: _loggedInUserId!,
          onSharePostTapped: () {
            setState(() {
              _currentIndex = 2; // Switch to CreatePostScreen tab
            });
          },
        );
        break;
      case 2:
        currentScreen = const CreatePostScreen();
        break;
      case 3:
        currentScreen = const SearchUsersScreen();
        break;
      case 4:
        currentScreen = const ExploreScreen();
        break;
      default:
        currentScreen = const FeedScreen();
    }

    return Scaffold(
      body: currentScreen,
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
