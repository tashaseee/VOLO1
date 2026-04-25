import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../chat_room_page.dart';

/// Вызов: ApprovalNotificationOverlay.show(context, chatId, eventTitle)
class ApprovalNotificationOverlay {
  static void show(BuildContext context, {required int chatId, required String eventTitle, String? avatarUrl}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (ctx, anim1, anim2) => _ApprovalDialog(
        chatId: chatId,
        eventTitle: eventTitle,
        avatarUrl: avatarUrl,
      ),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curved = CurvedAnimation(parent: anim1, curve: Curves.elasticOut);
        return ScaleTransition(scale: curved, child: FadeTransition(opacity: anim1, child: child));
      },
    );
  }
}

class _ApprovalDialog extends StatefulWidget {
  final int chatId;
  final String eventTitle;
  final String? avatarUrl;
  const _ApprovalDialog({required this.chatId, required this.eventTitle, this.avatarUrl});

  @override
  State<_ApprovalDialog> createState() => _ApprovalDialogState();
}

class _ApprovalDialogState extends State<_ApprovalDialog> with SingleTickerProviderStateMixin {
  late AnimationController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF983296), Color(0xFF6A1B8A)],
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF983296).withOpacity(0.6), blurRadius: 40, spreadRadius: 4, offset: const Offset(0, 12)),
                ],
              ),
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Верхние звёзды
                _buildStars(),
                const SizedBox(height: 20),
                // Иконка
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                  child: const Center(child: Text('🎉', style: TextStyle(fontSize: 44))),
                ),
                const SizedBox(height: 24),
                // Заголовок
                Text('Вы приняты!', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 10),
                Text('Поздравляем! 🌟 Вы стали волонтёром мероприятия:', textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.white.withOpacity(0.85), height: 1.4)),
                const SizedBox(height: 12),
                // Название ивента
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.25))),
                  child: Text(widget.eventTitle, textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
                const SizedBox(height: 8),
                Text('Вас добавили в командный чат 💬', textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.white.withOpacity(0.7))),
                const SizedBox(height: 28),
                // Кнопки
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatRoomPage(chatId: widget.chatId, chatName: widget.eventTitle, avatarUrl: widget.avatarUrl)));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF983296),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.chat_bubble_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text('Открыть чат', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Закрыть', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white.withOpacity(0.7))),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStars() {
    return AnimatedBuilder(
      animation: _confettiCtrl,
      builder: (context, child) {
        return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (int i = 0; i < 5; i++) ...[
            Transform.translate(
              offset: Offset(0, -6 * (((_confettiCtrl.value + i * 0.2) % 1.0) < 0.5 ? (_confettiCtrl.value + i * 0.2) % 1.0 : 1.0 - (_confettiCtrl.value + i * 0.2) % 1.0)),
              child: Opacity(
                opacity: 0.4 + 0.6 * (((_confettiCtrl.value + i * 0.2) % 1.0) < 0.5 ? (_confettiCtrl.value + i * 0.2) % 1.0 * 2 : (1.0 - (_confettiCtrl.value + i * 0.2) % 1.0) * 2),
                child: Text(['⭐', '✨', '🌟', '⭐', '✨'][i], style: const TextStyle(fontSize: 18)),
              ),
            ),
            if (i < 4) const SizedBox(width: 6),
          ]
        ]);
      },
    );
  }
}
