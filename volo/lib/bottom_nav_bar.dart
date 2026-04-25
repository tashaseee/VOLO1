import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      currentIndex: currentIndex,
      selectedItemColor: const Color(0xFF983296),
      unselectedItemColor: Colors.grey[400],
      onTap: onTap,
      items: [
        // 0: Уведомления
        BottomNavigationBarItem(
          icon: SvgPicture.asset('assets/images/notifi.svg', width: 20, height: 20,
            colorFilter: ColorFilter.mode(currentIndex == 0 ? const Color(0xFF983296) : Colors.grey[400]!, BlendMode.srcIn)),
          label: '',
        ),
        // 1: Поиск
        BottomNavigationBarItem(
          icon: SvgPicture.asset('assets/images/ivents.svg', width: 20, height: 20,
            colorFilter: ColorFilter.mode(currentIndex == 1 ? const Color(0xFF983296) : Colors.grey[400]!, BlendMode.srcIn)),
          label: '',
        ),
        // 2: Главная
        BottomNavigationBarItem(
          icon: SvgPicture.asset('assets/images/home.svg', width: 20, height: 20,
            colorFilter: ColorFilter.mode(currentIndex == 2 ? const Color(0xFF983296) : Colors.grey[400]!, BlendMode.srcIn)),
          label: '',
        ),
        // 3: Чаты (новая вкладка)
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline_rounded, size: 22,
            color: currentIndex == 3 ? const Color(0xFF983296) : Colors.grey[400]),
          label: '',
        ),
        // 4: Профиль
        BottomNavigationBarItem(
          icon: SvgPicture.asset('assets/images/name.svg', width: 20, height: 20,
            colorFilter: ColorFilter.mode(currentIndex == 4 ? const Color(0xFF983296) : Colors.grey[400]!, BlendMode.srcIn)),
          label: '',
        ),
      ],
    );
  }
}