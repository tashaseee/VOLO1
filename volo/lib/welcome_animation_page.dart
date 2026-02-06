import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'home_page.dart';

class WelcomeAnimationPage extends StatefulWidget {
  const WelcomeAnimationPage({super.key});
  @override State<WelcomeAnimationPage> createState() => _WelcomeAnimationPageState();
}

class _WelcomeAnimationPageState extends State<WelcomeAnimationPage>
    with TickerProviderStateMixin {
  late final AnimationController _flashController;
  bool _hasTapped = false;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  }

  void _onTap() {
    if (_hasTapped) return;
    _hasTapped = true;
    _flashController.forward().then((_) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomePage(),
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        ),
        (route) => false,
      );
    });
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: _onTap,
        child: Stack(
          children: [
            // Небо
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF87CEEB), Color(0xFFE8F4FF), Colors.white],
                  stops: [0.0, 0.4, 1.0],
                ),
              ),
            ),

            // ОБЛАКА — 100% НЕПРОЗРАЧНЫЕ, БЕЛЫЕ, КРАСИВЫЕ
            Lottie.asset(
              'assets/animation/cloud.json',  // ← этот файл по ссылке выше
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              repeat: true,
            ),

            // Мальчик летит на переднем плане
            Positioned(
              bottom: -size.height * 1.15,
              left: 0,
              right: 0,
              child: Lottie.asset(
                'assets/animation/fly.json',
                width: size.width * 3.8,
                height: size.height * 3.2,
                fit: BoxFit.contain,
                repeat: true,
              ),
            ),

            // Текст
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 50, 60, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(flex: 2),
                    Text(
                      'МЕНЯЙ МИР\nВМЕСТЕ С НАМИ',
                      style: TextStyle(
                        fontSize: 58,
                        fontWeight: FontWeight.w800,
                        height: 0.92,
                        letterSpacing: -1.2,
                        color: const Color(0xFF983296),
                      ),
                    ),
                    const Spacer(flex: 8),
                  ],
                ),
              ),
            ),

            // Подсказка
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: Text(
                  'нажмите на экран, чтобы продолжить',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w300,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),

            // Белая вспышка при нажатии
            AnimatedBuilder(
              animation: _flashController,
              builder: (context, child) => Container(
                color: Color.lerp(Colors.transparent, Colors.white, _flashController.value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}