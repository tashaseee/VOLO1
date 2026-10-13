import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:ui';
import 'package:flutter_svg/flutter_svg.dart';
import 'services/api_service.dart';

// ==========================================
// 1. НАСТРОЙКИ УВЕДОМЛЕНИЙ
// ==========================================
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool pushEnabled = true;
  bool emailEnabled = true;
  bool updatesEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0D0D26)),
        centerTitle: true,
        title: const SizedBox(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildPremiumSwitchTile(
            title: 'Push-уведомления',
            subtitle: 'Мгновенные оповещения о новых заявках и важных событиях',
            icon: Icons.notifications_active_rounded,
            value: pushEnabled,
            onChanged: (val) => setState(() => pushEnabled = val),
          ),
          const SizedBox(height: 16),
          _buildPremiumSwitchTile(
            title: 'Email-рассылка',
            subtitle: 'Получать ежемесячные дайджесты и советы на почту',
            icon: Icons.email_rounded,
            value: emailEnabled,
            onChanged: (val) => setState(() => emailEnabled = val),
          ),
          const SizedBox(height: 16),
          _buildPremiumSwitchTile(
            title: 'Обновления VOLO',
            subtitle: 'Новости о новых функциях и акциях платформы',
            icon: Icons.system_update_rounded,
            value: updatesEnabled,
            onChanged: (val) => setState(() => updatesEnabled = val),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF983296).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: value ? const Color(0xFF983296).withValues(alpha: 0.1) : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: value ? const Color(0xFF983296) : Colors.grey[400], size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF0D0D26)),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF95969D)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF983296),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 2. ПОМОЩЬ, FAQ и ИИ-ПОДДЕРЖКА
// ==========================================
class HelpFAQPage extends StatefulWidget {
  const HelpFAQPage({super.key});

  @override
  State<HelpFAQPage> createState() => _HelpFAQPageState();
}

class _HelpFAQPageState extends State<HelpFAQPage> {
  final List<Map<String, dynamic>> faqs = [
    {
      'question': 'Как начисляются Volo-часы?',
      'answer': 'Часы начисляются автоматически после того, как организатор мероприятия подтвердит ваше участие и завершит заявку в системе.',
      'expanded': false,
    },
    {
      'question': 'Как получить электронный сертификат?',
      'answer': 'Сертификаты генерируются автоматически после успешного завершения мероприятия организатором. Найти их можно в разделе "Мои сертификаты" в вашем профиле.',
      'expanded': false,
    },
    {
      'question': 'Что делать, если заявку отклонили?',
      'answer': 'Организаторы выбирают волонтеров по своим критериям. Не расстраивайтесь! Найдите другое интересное мероприятие в ленте и подайте заявку.',
      'expanded': false,
    },
    {
      'question': 'Как изменить данные профиля?',
      'answer': 'В личном кабинете нажмите кнопку "Личная информация" или иконку карандаша возле аватара. Там вы можете обновить свои контакты и фото.',
      'expanded': false,
    },
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0D0D26)),
        centerTitle: true,
        title: const SizedBox(),
      ),
      body: ListView(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 100),
        physics: const BouncingScrollPhysics(),
        children: [
          Text(
            'Частые вопросы',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0D0D26)),
          ),
          const SizedBox(height: 16),
          ...faqs.map((faq) => _buildAccordion(faq)).toList(),
        ],
      ),
    );
  }

  Widget _buildAccordion(Map<String, dynamic> faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: const Color(0xFF983296),
          collapsedIconColor: Colors.grey[400],
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          title: Text(
            faq['question'],
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0D0D26),
            ),
          ),
          onExpansionChanged: (expanded) {
            setState(() {
              faq['expanded'] = expanded;
            });
          },
          children: [
            Text(
              faq['answer'],
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.6,
                color: const Color(0xFF5D5E67),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------
// Бот ИИ-Поддержки (BottomSheet)
// ------------------------------------------
class AISupportBottomSheet extends StatefulWidget {
  const AISupportBottomSheet({super.key});

  @override
  State<AISupportBottomSheet> createState() => _AISupportBottomSheetState();
}

class _AISupportBottomSheetState extends State<AISupportBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [
    {
      "role": "assistant",
      "content": "Привет! 👋 Я ИИ-помощник службы поддержки VOLO.\nЗадайте мне любой вопрос по работе приложения, и я помогу вам за пару секунд!"
    }
  ];
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "content": text});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/ai/support'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': text,
          'history': _messages.sublist(0, _messages.length - 1).map((m) => {
                'role': m['role'],
                'content': m['content']
              }).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['success'] == true) {
          setState(() {
            _messages.add({"role": "assistant", "content": data['reply']});
          });
        } else {
          setState(() {
            _messages.add({"role": "assistant", "content": data['reply'] ?? "Ошибка сервера"});
          });
        }
      } else {
        setState(() {
          _messages.add({"role": "assistant", "content": "Простите, сервер не отвечает. 😔 Попробуйте позже."});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({"role": "assistant", "content": "Ошибка связи с сервером. Проверьте подключение к интернету."});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB).withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, -5),
              )
            ],
          ),
          child: Column(
            children: [
              // Premium Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF0D0D26).withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    // Grabber
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF983296), Color(0xFF6B21A8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF983296).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ИИ-Поддержка VOLO',
                                style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF0D0D26), letterSpacing: -0.3),
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 8, height: 8,
                                    decoration: const BoxDecoration(color: Color(0xFF00BFA5), shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Всегда онлайн',
                                    style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF5D5E67), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(color: const Color(0xFFF1F0F5), shape: BoxShape.circle),
                          child: IconButton(
                            icon: const Icon(Icons.close_rounded, color: Color(0xFF5D5E67), size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Chat History
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(24),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isUser = msg['role'] == 'user';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isUser) ...[
                            Container(
                              width: 32, height: 32,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF983296), Color(0xFF6B21A8)]),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                            ),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              decoration: BoxDecoration(
                                color: isUser ? const Color(0xFF983296) : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                                  bottomRight: Radius.circular(isUser ? 4 : 20),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isUser ? const Color(0xFF983296).withValues(alpha: 0.2) : const Color(0xFF0D0D26).withValues(alpha: 0.04),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                                border: isUser ? null : Border.all(color: const Color(0xFFF1F0F5)),
                              ),
                              child: Text(
                                msg['content'] ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: isUser ? Colors.white : const Color(0xFF0D0D26),
                                  height: 1.6,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          if (isUser) ...[
                            Container(
                              width: 32, height: 32,
                              margin: const EdgeInsets.only(left: 12),
                              decoration: const BoxDecoration(
                                color: Color(0xFF0D0D26),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_rounded, color: Colors.white, size: 16),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16, left: 24),
                  child: Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF983296), Color(0xFF6B21A8)]),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFF1F0F5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12, height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2, color: const Color(0xFF983296)),
                            ),
                            const SizedBox(width: 8),
                            Text('Генерирует ответ...', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF95969D), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Premium Input Field
              Container(
                padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 24 + MediaQuery.of(context).viewInsets.bottom),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF0D0D26).withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, -5)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F8),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: TextField(
                          controller: _controller,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF0D0D26), fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: 'Задайте вопрос ИИ...',
                            hintStyle: GoogleFonts.poppins(color: const Color(0xFFA0A0AB), fontWeight: FontWeight.w400),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF983296), Color(0xFFD644D2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF983296).withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 3. О ПРИЛОЖЕНИИ VOLO
// ==========================================
class AboutVoloPage extends StatelessWidget {
  const AboutVoloPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0D0D26)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Minimalist Logo Header
            const SizedBox(height: 20),
            Center(
              child: SvgPicture.asset(
                'assets/images/VOLO-2.svg',
                height: 48,
                colorFilter: const ColorFilter.mode(Color(0xFF983296), BlendMode.srcIn),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Версия 1.0.0',
                style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF8E8E93), fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 32),
            
            Text(
              'Развиваем волонтерство в Казахстане. VOLO — это мост между инициативными людьми и ответственными организациями, созданный для масштабных и добрых дел.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 15, color: const Color(0xFF5D5E67), height: 1.6),
            ),
            const SizedBox(height: 40),

            _buildLinkTile(Icons.policy_rounded, 'Политика конфиденциальности'),
            const SizedBox(height: 12),
            _buildLinkTile(Icons.description_rounded, 'Пользовательское соглашение'),
            const SizedBox(height: 12),
            _buildLinkTile(Icons.language_rounded, 'Официальный веб-сайт (volo.kz)'),
            
            const SizedBox(height: 40),
            Text(
              'Сделано с ❤️ в 2026',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400], fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkTile(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF983296), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0D0D26)),
            ),
          ),
          const Icon(Icons.open_in_new_rounded, color: Colors.grey, size: 18),
        ],
      ),
    );
  }
}
