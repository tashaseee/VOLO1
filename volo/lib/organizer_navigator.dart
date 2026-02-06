import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'organizer_home_page.dart';
import 'add_event_page.dart';
import 'organizer_events_page.dart';
import 'organizer_profile_page.dart';
import 'notifications_page.dart';

class OrganizerNavigator extends StatefulWidget {
  const OrganizerNavigator({super.key});

  @override
  State<OrganizerNavigator> createState() => _OrganizerNavigatorState();
}

class _OrganizerNavigatorState extends State<OrganizerNavigator> {
  int _selectedIndex = 2; // Default to Home for organizers as well

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Notifications (Index 0)
          const NotificationsPage(showNavBar: false),
          // Add Event (Index 1) - Placeholder as we push this route
          const SizedBox.shrink(),
          // Home (Index 2)
          OrganizerHomePage(onTabChange: (index) {
            if (index == 1) {
              Navigator.pushNamed(context, '/add_event');
            } else {
              setState(() => _selectedIndex = index);
            }
          }),
          // Events List (Index 3)
          const OrganizerEventsPage(),
          // Profile (Index 4)
          const OrganizerProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF983296),
        unselectedItemColor: Colors.grey[400],
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/add_event');
          } else {
            setState(() => _selectedIndex = index);
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/images/notifi.svg',
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                _selectedIndex == 0 ? const Color(0xFF983296) : Colors.grey[400]!,
                BlendMode.srcIn,
              ),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/images/plus.svg',
              width: 32,
              height: 32,
              colorFilter: ColorFilter.mode(
                _selectedIndex == 1 ? const Color(0xFF983296) : const Color(0xFF983296).withOpacity(0.7), // Always purplish but bolder
                BlendMode.srcIn,
              ),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/images/home.svg',
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                _selectedIndex == 2 ? const Color(0xFF983296) : Colors.grey[400]!,
                BlendMode.srcIn,
              ),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/images/ivents.svg',
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                _selectedIndex == 3 ? const Color(0xFF983296) : Colors.grey[400]!,
                BlendMode.srcIn,
              ),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/images/name.svg',
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                _selectedIndex == 4 ? const Color(0xFF983296) : Colors.grey[400]!,
                BlendMode.srcIn,
              ),
            ),
            label: '',
          ),
        ],
      ),
    );
  }
}