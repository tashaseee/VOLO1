import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'onboarding_page.dart'; // Для навигации
import 'sign_in_page.dart'; // Для навигации
import 'services/api_service.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  void _showChangeUrlDialog(BuildContext context) {
    final controller = TextEditingController(text: ApiService.baseUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Настройки сервера'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Введите адрес API сервера:'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: dotenv.env['BASE_URL'] ?? 'http://127.0.0.1:8080',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'IP берется из файла .env',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              String newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                ApiService.baseUrl = newUrl;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Адрес сервера изменен на: $newUrl')),
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF983296),
      body: Stack(
        children: [
          Positioned(
            top: 50,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () => _showChangeUrlDialog(context),
            ),
          ),
          Center(
            child: SvgPicture.asset(
              'assets/images/voloapp.svg',
              width: 159,
              height: 189,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                      children: const [
                        TextSpan(
                          text: 'VOLO — ',
                          style: TextStyle(
                            color: Color(0xFF983296),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(text: 'просто о волонтерстве.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OnboardingPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF983296),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Начнем!',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignInPage(),
                        ),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                        children: const [
                          TextSpan(text: 'Уже есть аккаунт? '),
                          TextSpan(
                            text: 'Войти',
                            style: TextStyle(
                              color: Color(0xFF983296),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}