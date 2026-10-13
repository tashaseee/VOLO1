import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/nav/nav_bloc.dart';
import 'organizer_home_page.dart';
import 'organizer_events_page.dart';
import 'organizer_profile_page.dart';
import 'chats_page.dart';

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
              OrganizerHomePage(onTabChange: (index) {
                context.read<NavBloc>().add(ChangeNavIndex(index));
              }),
              const SizedBox.shrink(), // Placeholder for Add Event
              const ChatsPage(showNavBar: false),
              const OrganizerEventsPage(),
              const OrganizerProfilePage(),
            ],
          ),
          bottomNavigationBar: Container(
            height: 80,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFF1F0F5), width: 1.5),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(context, 0, 'assets/images/home.svg', state.selectedIndex),
                _buildNavItemIcon(context, 2, Icons.chat_bubble_outline_rounded, state.selectedIndex),
                _buildPlusItem(context),
                _buildNavItem(context, 3, 'assets/images/ivents.svg', state.selectedIndex),
                _buildNavItem(context, 4, 'assets/images/name.svg', state.selectedIndex),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(BuildContext context, int index, String svgPath, int selectedIndex) {
    final bool isSelected = selectedIndex == index;
    return InkWell(
      onTap: () => context.read<NavBloc>().add(ChangeNavIndex(index)),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 50,
        height: 50,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              svgPath,
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(
                isSelected ? const Color(0xFF983296) : const Color(0xFFA0A0AB),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF983296) : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItemIcon(BuildContext context, int index, IconData icon, int selectedIndex) {
    final bool isSelected = selectedIndex == index;
    return InkWell(
      onTap: () => context.read<NavBloc>().add(ChangeNavIndex(index)),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 50,
        height: 50,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? const Color(0xFF983296) : const Color(0xFFA0A0AB),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF983296) : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlusItem(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/add_event'),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF983296),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF983296).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}