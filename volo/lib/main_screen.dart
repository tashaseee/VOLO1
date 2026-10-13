import 'package:flutter/material.dart';
import 'home_page.dart';
import 'search_page.dart';
import 'chats_page.dart';
import 'profile_page.dart';
import 'notifications_page.dart';
import 'bottom_nav_bar.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 2}); // 2 - Главная (Home) по умолчанию

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  // Индексы:
  // 0: NotificationsPage
  // 1: SearchPage
  // 2: HomePage
  // 3: ChatsPage
  // 4: ProfilePage
  final List<Widget> _pages = [
    const NotificationsPage(showNavBar: false),
    const SearchPage(showNavBar: false),
    const HomePage(showNavBar: false),
    const ChatsPage(showNavBar: false),
    const ProfilePage(showNavBar: false),
  ];

  void _onItemTapped(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
