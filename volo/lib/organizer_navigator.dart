import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/nav/nav_bloc.dart';
import 'organizer_home_page.dart';
import 'add_event_page.dart';
import 'organizer_events_page.dart';
import 'organizer_profile_page.dart';
import 'notifications_page.dart';

class OrganizerNavigator extends StatelessWidget {
  const OrganizerNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NavBloc(),
      child: const _OrganizerNavigatorView(),
    );
  }
}

class _OrganizerNavigatorView extends StatelessWidget {
  const _OrganizerNavigatorView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavBloc, NavState>(
      builder: (context, state) {
        return Scaffold(
          body: IndexedStack(
            index: state.selectedIndex,
            children: [
              const NotificationsPage(showNavBar: false),
              const SizedBox.shrink(),
              OrganizerHomePage(onTabChange: (index) {
                if (index == 1) {
                  Navigator.pushNamed(context, '/add_event');
                } else {
                  context.read<NavBloc>().add(ChangeNavIndex(index));
                }
              }),
              const OrganizerEventsPage(),
              const OrganizerProfilePage(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            currentIndex: state.selectedIndex,
            selectedItemColor: const Color(0xFF983296),
            unselectedItemColor: Colors.grey[400],
            onTap: (index) {
              if (index == 1) {
                Navigator.pushNamed(context, '/add_event');
              } else {
                context.read<NavBloc>().add(ChangeNavIndex(index));
              }
            },
            items: [
              BottomNavigationBarItem(
                icon: SvgPicture.asset('assets/images/notifi.svg', width: 20, height: 20,
                  colorFilter: ColorFilter.mode(state.selectedIndex == 0 ? const Color(0xFF983296) : Colors.grey[400]!, BlendMode.srcIn)),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset('assets/images/plus.svg', width: 32, height: 32,
                  colorFilter: ColorFilter.mode(state.selectedIndex == 1 ? const Color(0xFF983296) : const Color(0xFF983296).withOpacity(0.7), BlendMode.srcIn)),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset('assets/images/home.svg', width: 20, height: 20,
                  colorFilter: ColorFilter.mode(state.selectedIndex == 2 ? const Color(0xFF983296) : Colors.grey[400]!, BlendMode.srcIn)),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset('assets/images/ivents.svg', width: 20, height: 20,
                  colorFilter: ColorFilter.mode(state.selectedIndex == 3 ? const Color(0xFF983296) : Colors.grey[400]!, BlendMode.srcIn)),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset('assets/images/name.svg', width: 20, height: 20,
                  colorFilter: ColorFilter.mode(state.selectedIndex == 4 ? const Color(0xFF983296) : Colors.grey[400]!, BlendMode.srcIn)),
                label: '',
              ),
            ],
          ),
        );
      },
    );
  }
}