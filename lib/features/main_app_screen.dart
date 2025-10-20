import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/feed/screens/feed_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/posts/screens/create_post_screen.dart';
import '../features/profile/screens/search_users_screen.dart';
import '../features/feed/screens/explore_screen.dart';

class MainAppScreen extends StatefulWidget {
  final int initialIndex; // 0 = Feed, 1 = Profile

  const MainAppScreen({super.key, this.initialIndex = 0});

  @override
  State createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  late int _currentIndex;
  String? _loggedInUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadLoggedInUserId();
  }

  Future _loadLoggedInUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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

    Widget currentScreen;
    switch (_currentIndex) {
      case 0:
        currentScreen = const FeedScreen();
        break;
      case 1:
        currentScreen = ProfileScreen(
          key: ValueKey('profile_$_loggedInUserId'),
          userId: _loggedInUserId!,
          onSharePostTapped: () {
            setState(() {
              _currentIndex = 2;
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
      extendBody: true,
      bottomNavigationBar: _buildBeautifulNavBar(),
    );
  }

  Widget _buildBeautifulNavBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home_rounded, 'Feed', 0),
                  _buildNavItem(Icons.person_rounded, 'Profile', 1),
                  _buildCenterNavItem(Icons.add_rounded, 2),
                  _buildNavItem(Icons.search_rounded, 'Search', 3),
                  _buildNavItem(Icons.explore_rounded, 'Explore', 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => _onTabTapped(index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.deepPurple.withOpacity(0.8),
                    Colors.blue.withOpacity(0.8),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: isSelected ? 26 : 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCenterNavItem(IconData icon, int index) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => _onTabTapped(index),
      borderRadius: BorderRadius.circular(25),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [Colors.deepPurple, Colors.blue]
                : [
                    Colors.deepPurple.withOpacity(0.7),
                    Colors.blue.withOpacity(0.7),
                  ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isSelected ? Colors.deepPurple : Colors.blue).withOpacity(
                0.5,
              ),
              blurRadius: isSelected ? 20 : 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: isSelected ? 32 : 28),
      ),
    );
  }
}
