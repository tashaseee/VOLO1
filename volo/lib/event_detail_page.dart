// lib/event_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:volo/home_page.dart';
import 'package:volo/search_page.dart';
import 'package:volo/my_applications_page.dart';
import 'package:volo/profile_page.dart';
import 'package:volo/notifications_page.dart';
import 'package:volo/application_confirmation_page.dart';
import 'bottom_nav_bar.dart';
import 'services/api_service.dart';
import 'organizer_event_applications_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class EventDetailPage extends StatefulWidget {
  final String eventTitle;
  final String organizer;
  final String date;
  final String location;
  final String chatLink;
  final String description;
  final List<String> responsibilities;
  final List<String> benefits;
  final int eventId;
  final String? imageUrl; // New field definition

  const EventDetailPage({
    super.key,
    required this.eventTitle,
    required this.organizer,
    required this.date,
    required this.location,
    required this.chatLink,
    required this.description,
    required this.responsibilities,
    required this.benefits,
    required this.eventId,
    this.imageUrl, // New field for proper image handling
  });

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final ApiService _apiService = ApiService();
  int _selectedIndex = 2;
  bool _isApplied = false;
  String _applicationStatus = '';
  String _userRole = 'volunteer';
  bool _isMyEvent = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role') ?? 'volunteer';
    
    setState(() {
      _userRole = role;
    });

    if (role == 'organizer') {
      final myEventsResult = await _apiService.getMyEvents();
      if (myEventsResult['success']) {
        final myEvents = myEventsResult['data'] as List;
        if (myEvents.any((e) => e['id'] == widget.eventId)) {
          setState(() => _isMyEvent = true);
        }
      }
    } else {
      final result = await _apiService.getMyApplications();
      if (result['success'] && mounted) {
        final myApps = result['data'] as List;
        final myApp = myApps.firstWhere(
          (a) => (a['event'] != null && a['event']['id'] == widget.eventId) || (a['event_id'] == widget.eventId),
          orElse: () => null
        );
        
        setState(() {
          if (myApp != null) {
            _isApplied = true;
            _applicationStatus = myApp['status'];
          } else {
            _isApplied = false;
            _applicationStatus = 'pending';
          }
        });
      }
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _openChat() async {
    final link = widget.chatLink;
    if (link.isEmpty) return;
    
    final Uri url = Uri.parse(link.startsWith('http') ? link : 'https://$link');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось открыть ссылку: $link')),
        );
      }
    }
  }

  /// Открывает экран подтверждения заявки
  void _applyForEvent() {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        pageBuilder: (context, _, __) => ApplicationConfirmationPage(
          eventTitle: widget.eventTitle,
          organizer: widget.organizer,
          date: widget.date,
          location: widget.location,
          eventId: widget.eventId,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ).then((result) {
      if (result == true) {
        setState(() => _isApplied = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ---------- Основной контент ----------
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Логотип + share
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/images/VOLO-2.svg',
                      height: 21,
                      colorFilter: const ColorFilter.mode(Color(0xFF983296), BlendMode.srcIn),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.share_rounded,
                        size: 20,
                        color: Color(0xFF983296),
                      ),
                      onPressed: () {
                        // TODO: поделиться
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Фото события
                Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                          ? NetworkImage(widget.imageUrl!.startsWith('http') 
                              ? widget.imageUrl! 
                              : '${ApiService.baseUrl}${widget.imageUrl!}') as ImageProvider
                          : const AssetImage('assets/images/photo.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Заголовок
                Text(
                  widget.eventTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.organizer,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),

                // Дата
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/images/calendar.svg',
                      width: 18,
                      height: 18,
                      colorFilter: const ColorFilter.mode(Color(0xFF983296), BlendMode.srcIn),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.date,
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Локация
                Row(
                  children: [
                    Image.asset('assets/images/org.png', width: 18, height: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.location,
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Описание
                Text('Описание', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(widget.description,
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700], height: 1.5)),
                const SizedBox(height: 24),

                // Обязанности (перенос текста)
                Text('Обязанности', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...widget.responsibilities.map((resp) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF983296),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              resp,
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                    )),

                const SizedBox(height: 24),

                // Бонусы
                Text('Бонусы', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.benefits
                      .map((ben) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF983296).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              ben,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF983296),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),

          // ---------- КНОПКА "ПОДАТЬ ЗАЯВКУ" (полная ширина, без чата) ----------
          Positioned(
            left: 28,
            right: 28,
            bottom: 20,
            child: ElevatedButton(
              onPressed: _isLoading 
                ? null 
                : (_isMyEvent 
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrganizerEventApplicationsPage(
                          eventId: widget.eventId,
                          eventTitle: widget.eventTitle,
                        ),
                      ),
                    ).then((_) => _checkStatus())
                  : (_isApplied 
                      ? (_applicationStatus == 'approved' ? _openChat : null) 
                      : _applyForEvent)),
              style: ElevatedButton.styleFrom(
                backgroundColor: (_isApplied && _applicationStatus == 'approved') 
                    ? const Color(0xFF0088CC) // Telegram Blue or nice Accent
                    : const Color(0xFF983296),
                disabledBackgroundColor: _isApplied ? Colors.grey[400] : Colors.grey[400],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    _isMyEvent 
                      ? 'Управление заявками' 
                      : (_isApplied 
                        ? (_applicationStatus == 'approved' ? 'Вступить в чат 💬' : (_applicationStatus == 'rejected' ? 'Заявка отклонена' : 'Заявка на рассмотрении')) 
                        : 'Подать заявку'),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacement(
            context,
            PageRouteBuilder(
                pageBuilder: (_, __, ___) => const NotificationsPage(),
                transitionDuration: Duration.zero));
        break;
      case 1:
        Navigator.pushReplacement(
            context,
            PageRouteBuilder(
                pageBuilder: (_, __, ___) => const SearchPage(),
                transitionDuration: Duration.zero));
        break;
      case 2:
        Navigator.pushReplacement(
            context,
            PageRouteBuilder(
                pageBuilder: (_, __, ___) => const HomePage(),
                transitionDuration: Duration.zero));
        break;
      case 3:
        Navigator.pushReplacement(
            context,
            PageRouteBuilder(
                pageBuilder: (_, __, ___) => MyApplicationsPage(),
                transitionDuration: Duration.zero));
        break;
      case 4:
        Navigator.pushReplacement(
            context,
            PageRouteBuilder(
                pageBuilder: (_, __, ___) => const ProfilePage(),
                transitionDuration: Duration.zero));
        break;
    }
  }
}