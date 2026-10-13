// lib/event_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'main_screen.dart';
import 'package:volo/home_page.dart';
import 'package:volo/search_page.dart';
import 'package:volo/my_applications_page.dart';
import 'package:volo/profile_page.dart';
import 'package:volo/notifications_page.dart';
import 'package:volo/chats_page.dart';
import 'package:volo/application_confirmation_page.dart';
import 'bottom_nav_bar.dart';
import 'services/api_service.dart';
import 'organizer_event_applications_page.dart';
import 'chat_room_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'blocs/event_detail/event_detail_bloc.dart';

class EventDetailPage extends StatelessWidget {
  final String eventTitle;
  final String organizer;
  final String date;
  final String location;
  final String chatLink;
  final String description;
  final List<String> responsibilities;
  final List<String> benefits;
  final int eventId;
  final String? imageUrl; 
  final int minAge;
  final int? chatId;

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
    this.imageUrl, 
    this.minAge = 0,
    this.chatId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EventDetailBloc(apiService: ApiService())
        ..add(LoadEventDetails(eventId)),
      child: _EventDetailView(
        eventTitle: eventTitle,
        organizer: organizer,
        date: date,
        location: location,
        chatLink: chatLink,
        description: description,
        responsibilities: responsibilities,
        benefits: benefits,
        eventId: eventId,
        imageUrl: imageUrl,
        minAge: minAge,
        chatId: chatId,
      ),
    );
  }
}

class _EventDetailView extends StatefulWidget {
  final String eventTitle;
  final String organizer;
  final String date;
  final String location;
  final String chatLink;
  final String description;
  final List<String> responsibilities;
  final List<String> benefits;
  final int eventId;
  final String? imageUrl;
  final int minAge;
  final int? chatId;

  const _EventDetailView({
    required this.eventTitle,
    required this.organizer,
    required this.date,
    required this.location,
    required this.chatLink,
    required this.description,
    required this.responsibilities,
    required this.benefits,
    required this.eventId,
    this.imageUrl,
    this.minAge = 0,
    this.chatId,
  });

  @override
  State<_EventDetailView> createState() => _EventDetailViewState();
}

class _EventDetailViewState extends State<_EventDetailView> {
  int _selectedIndex = 2;

  Future<void> _openChat(BuildContext context) async {
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

  void _openInternalChat(BuildContext context, int? chatId) {
    if (chatId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomPage(
            chatId: chatId,
            chatName: widget.eventTitle,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Чат мероприятия еще не создан или недоступен')),
      );
    }
  }

  void _applyForEvent(BuildContext context, int userAge) {
    if (widget.minAge > 0) {
      if (userAge == 0) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Укажите возраст',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Для участия в мероприятиях с возрастными ограничениями необходимо указать дату рождения в профиле.',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'ОК',
                  style: GoogleFonts.poppins(color: const Color(0xFF983296), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
        return;
      }
      if (userAge < widget.minAge) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Ограничение по возрасту',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Это мероприятие имеет возрастное ограничение ${widget.minAge}+. К сожалению, ваш возраст ($userAge) не позволяет вам подать заявку.',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'ОК',
                  style: GoogleFonts.poppins(color: const Color(0xFF983296), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
        return;
      }
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        pageBuilder: (ctx, _, __) => ApplicationConfirmationPage(
          eventTitle: widget.eventTitle,
          organizer: widget.organizer,
          date: widget.date,
          location: widget.location,
          eventId: widget.eventId,
        ),
        transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ).then((result) {
      if (result == true) {
        context.read<EventDetailBloc>().add(SetAppliedStatus());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventDetailBloc, EventDetailState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Логотип + share
                      Row(
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              } else {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2)),
                                  (route) => false,
                                );}
                            },
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
                              color: Colors.transparent,
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 24,
                                color: Color(0xFF983296),
                              ),
                            ),
                          ),
                        const SizedBox(width: 12),
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
                          onPressed: () {},
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
                    if (widget.minAge > 0) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.child_care_rounded,
                            size: 18,
                            color: Color(0xFF983296),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Возрастное ограничение: ${widget.minAge}+',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Описание
                    Text('Описание', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(widget.description,
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700], height: 1.5)),
                    const SizedBox(height: 24),

                    // Обязанности
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
                                  color: const Color(0xFF983296).withValues(alpha: 0.1),
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

              // КНОПКА
              Positioned(
                left: 28,
                right: 28,
                bottom: 20,
                child: ElevatedButton(
                  onPressed: state.isLoading 
                    ? null 
                    : (state.isMyEvent 
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => OrganizerEventApplicationsPage(
                                eventId: widget.eventId,
                                eventTitle: widget.eventTitle,
                              ),
                            ),
                          ).then((_) => context.read<EventDetailBloc>().add(LoadEventDetails(widget.eventId)));
                        }
                      : (state.isApplied 
                          ? (state.applicationStatus == 'approved' 
                              ? () => _openInternalChat(context, state.chatId ?? widget.chatId) 
                              : null) 
                          : () => _applyForEvent(context, state.userAge))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (state.isApplied && state.applicationStatus == 'approved') 
                        ? const Color(0xFF0088CC) 
                        : const Color(0xFF983296),
                    disabledBackgroundColor: state.isApplied ? Colors.grey[400] : Colors.grey[400],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: state.isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        state.isMyEvent 
                          ? 'Управление заявками' 
                          : (state.isApplied 
                            ? (state.applicationStatus == 'approved' ? 'Вступить в чат 💬' : (state.applicationStatus == 'rejected' ? 'Заявка отклонена' : 'Заявка на рассмотрении')) 
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
        ),
          bottomNavigationBar: CustomBottomNavBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
          ),
        );
      },
    );
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const NotificationsPage(), transitionDuration: Duration.zero));
        break;
      case 1:
        Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const SearchPage(), transitionDuration: Duration.zero));
        break;
      case 2:
        Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const MainScreen(initialIndex: 2), transitionDuration: Duration.zero));
        break;
      case 3:
        Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => ChatsPage(), transitionDuration: Duration.zero));
        break;
      case 4:
        Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const ProfilePage(), transitionDuration: Duration.zero));
        break;
    }
  }
}