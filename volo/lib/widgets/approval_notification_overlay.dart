import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../chat_room_page.dart';
import '../services/api_service.dart';

/// Вызов: ApprovalNotificationOverlay.show(context, chatId, eventTitle)
class ApprovalNotificationOverlay {
  static void show(BuildContext context, {required int chatId, required String eventTitle, String? avatarUrl}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) => _ApprovalDialog(
        chatId: chatId,
        eventTitle: eventTitle,
        avatarUrl: avatarUrl,
      ),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
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
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 340),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                  BoxShadow(
                    color: const Color(0xFF983296).withValues(alpha: 0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Celebration Graphic (Double-ring animated badge)
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (context, child) {
                      return Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF5E8F7),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF983296).withValues(alpha: 0.12 * _pulseCtrl.value),
                              blurRadius: 20,
                              spreadRadius: 6 * _pulseCtrl.value,
                            ),
                          ],
                        ),
                        child: Center(
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.96, end: 1.04).animate(
                              CurvedAnimation(
                                parent: _pulseCtrl,
                                curve: Curves.easeInOut,
                              ),
                            ),
                            child: const Text(
                              '🎉',
                              style: TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Title
                  Text(
                    'Вы в команде! 🎉',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0D0D26),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Description
                  Text(
                    'Поздравляем! Ваша заявка одобрена организатором. Вы официально добавлены в чат участников:',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF95969D),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  
                  // Event Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0xFFF5E8F7),
                          ),
                          child: widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    widget.avatarUrl!.startsWith('http')
                                        ? widget.avatarUrl!
                                        : '${ApiService.baseUrl}${widget.avatarUrl!}',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.event_available_rounded,
                                      color: Color(0xFF983296),
                                      size: 24,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.event_available_rounded,
                                  color: Color(0xFF983296),
                                  size: 24,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'МЕРОПРИЯТИЕ',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF95969D),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.eventTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0D0D26),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  Text(
                    'Начните общение с командой прямо сейчас! 💬',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF983296),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatRoomPage(
                              chatId: widget.chatId,
                              chatName: widget.eventTitle,
                              avatarUrl: widget.avatarUrl,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF983296),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_bubble_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Открыть чат',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Закрыть',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF95969D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
