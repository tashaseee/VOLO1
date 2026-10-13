// lib/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:volo/profile_page.dart';
import 'package:volo/event_detail_page.dart';
import 'package:volo/search_page.dart';
import 'package:volo/notifications_page.dart';
import 'package:volo/ai_chat_page.dart';
import 'package:volo/chats_page.dart';
import 'bottom_nav_bar.dart';
import 'services/api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/home/home_bloc.dart';

class HomePage extends StatelessWidget {
  final bool? showNavBar;
  const HomePage({super.key, this.showNavBar});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc(apiService: ApiService())..add(LoadHomeData()),
      child: HomeView(showNavBar: showNavBar ?? true),
    );
  }
}

class HomeView extends StatefulWidget {
  final bool showNavBar;
  const HomeView({super.key, required this.showNavBar});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {

  final PageController _pageController = PageController(viewportFraction: 1.0);
  int _currentPage = 0;

  final PageController _adController = PageController();
  final List<String> adImages = [
    'assets/images/zhar.png',
    'assets/images/don.png',
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() => _currentPage = next);
      }
    });
    Future.delayed(const Duration(seconds: 4), _autoScrollAds);
  }

  void _autoScrollAds() {
    if (!mounted) return;
    final nextPage = (context.read<HomeBloc>().state.currentAdIndex + 1) % adImages.length;
    _adController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    Future.delayed(const Duration(seconds: 4), _autoScrollAds);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _adController.dispose();
    super.dispose();
  }

  String _formatDate(String date) {
    return date
        .replaceAll('Октября', 'Окт')
        .replaceAll('Ноября', 'Ноя')
        .replaceAll('Декабря', 'Дек');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          SvgPicture.asset('assets/images/VOLO-2.svg', height: 21,
                            colorFilter: const ColorFilter.mode(Color(0xFF983296), BlendMode.srcIn)),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Добро пожаловать!', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w300, color: const Color(0xFF95969D))),
                                const SizedBox(height: 4),
                                Text(state.userName, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w500, color: const Color(0xFF0D0D26))),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 54, height: 54,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                              image: state.avatarUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        state.avatarUrl!.startsWith('http')
                                            ? state.avatarUrl!
                                            : '${ApiService.baseUrl}${state.avatarUrl!}',
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: state.avatarUrl == null
                                ? ClipOval(child: Image.asset('assets/images/us.png', width: 54, height: 54, fit: BoxFit.cover))
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Volo-часы
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF983296), Color(0xFFB856B8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Твои Volo-часы:', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white70)),
                                Text(state.voloHours.toString(), style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w600, color: Colors.white)),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, '/volo_history'),
                              child: Container(
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Text('История', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF983296))),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // VOLO AI banner
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AiChatPage())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE5E5E5)),
                            boxShadow: [BoxShadow(color: const Color(0xFF983296).withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF983296), Color(0xFFC152B8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: const Color(0xFF983296).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Спроси VOLO AI', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0D0D26))),
                                    Text('Умный подбор мероприятий', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w400, color: const Color(0xFF95969D))),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFD1D1D6), size: 16),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      // Ad carousel
                      SizedBox(
                        height: 93,
                        child: Stack(
                          children: [
                            PageView.builder(
                              controller: _adController,
                              onPageChanged: (i) => context.read<HomeBloc>().add(ChangeAdIndex(i)),
                              itemCount: adImages.length,
                              itemBuilder: (context, index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(adImages[index], fit: BoxFit.cover, width: double.infinity, height: 93,
                                    errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: Center(child: Text('Ошибка', style: GoogleFonts.poppins(color: Colors.red))))),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8, left: 0, right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(adImages.length, (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: state.currentAdIndex == i ? const Color(0xFF983296) : Colors.grey[400]),
                                )),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      Text('Интересные предложения', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                      const SizedBox(height: 12),

                      SizedBox(
                        height: 200,
                        child: state.events.isEmpty
                            ? _buildEmptyOffersPlaceholder()
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.only(top: 8, bottom: 8),
                                itemCount: state.events.length > 5 ? 5 : state.events.length,
                                itemBuilder: (context, index) {
                                  final event = state.events[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: GestureDetector(
                                      onTap: () => _navigateToEventDetail(event),
                                      child: _buildEventCard(
                                        event['date_text'] ?? 'Скоро',
                                        event['title'],
                                        event['organizer'] ?? 'Организатор',
                                        true,
                                        event['image_url'],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),

                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Text('Больше ивентов', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const SearchPage(), transitionDuration: Duration.zero)),
                            child: Text('Смотреть больше', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF983296))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (state.events.isNotEmpty)
                        ...state.events.map((event) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () => _navigateToEventDetail(event),
                            child: _buildEventListItem(event['title'], event['organizer'] ?? 'Организатор', event['date_text'] ?? 'Скоро', event['image_url']),
                          ),
                        ))
                      else
                        _buildNoEventsState(),
                    ],
                  ),
                ),
              ),
              if (widget.showNavBar)
                CustomBottomNavBar(currentIndex: state.selectedNavIndex, onTap: (i) => _onItemTapped(i, state)),
            ],
          ),
        );
      },
    );
  }

  void _onItemTapped(int index, HomeState state) {
    context.read<HomeBloc>().add(ChangeBottomNavIndex(index));
    switch (index) {
      case 0: Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const NotificationsPage(), transitionDuration: Duration.zero)); break;
      case 1: Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const SearchPage(), transitionDuration: Duration.zero)); break;
      case 2: break;
      case 3: Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => ChatsPage(), transitionDuration: Duration.zero)); break;
      case 4: Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const ProfilePage(), transitionDuration: Duration.zero)); break;
    }
  }

  // КАРТОЧКА ИВЕНТА — ИЗМЕНЕНИЯ ЗДЕСЬ
  Widget _buildEventCard(String date, String title, String org, bool isPaid, String? imageUrl) {
    return Container(
      width: 280,
      height: 170, // Уменьшена высота с 186 до 170
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: const Color(0xFF983296)),
      child: Stack(
        children: [
          Positioned.fill(child: SvgPicture.asset('assets/images/mask.svg', fit: BoxFit.cover)),
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF662265)),
              child: Center(child: SvgPicture.asset('assets/images/Shape.svg', width: 16, height: 16, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ДАТА
                Center(
                  child: Container(
                    width: 107,
                    height: 22,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Center(
                      child: Text(
                        _formatDate(date),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ТЕКСТ (заголовок + организатор)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: imageUrl != null && imageUrl.isNotEmpty
                              ? NetworkImage(imageUrl.startsWith('http') ? imageUrl : '${ApiService.baseUrl}$imageUrl') as ImageProvider
                              : const AssetImage('assets/images/photo.png'), 
                          fit: BoxFit.cover
                         ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: GoogleFonts.poppins(fontSize: 14, height: 1.2, fontWeight: FontWeight.w600, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(org, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8), // Уменьшено расстояние до бенефитов

                // БЕНЕФИТЫ — ПОДНЯТЫ ВЫШЕ
                Wrap(
                  alignment: WrapAlignment.start,
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _benefitChip(isPaid ? 'Оплачиваемо' : 'Без опыта'),
                    _benefitChip('Трансфер'),
                    _benefitChip('2 дня'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Вспомогательный чип
  Widget _benefitChip(String text) {
    return Container(
      width: 107,
      height: 22,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Text(text, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w400, color: Colors.white), textAlign: TextAlign.center),
    );
  }

  // Обычные ивенты — НЕ ТРОГАЕМ
  Widget _buildEventListItem(String title, String org, String date, String? imageUrl) {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[300], 
              borderRadius: BorderRadius.circular(8), 
              image: DecorationImage(
                image: imageUrl != null && imageUrl.isNotEmpty
                    ? NetworkImage(imageUrl.startsWith('http') ? imageUrl : '${ApiService.baseUrl}$imageUrl') as ImageProvider
                    : const AssetImage('assets/images/photo.png'),
                fit: BoxFit.cover
              )
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
                const SizedBox(height: 4),
                Text(org, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(date, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF983296))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEventDetail(dynamic event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailPage(
          eventTitle: event['title'],
          organizer: event['organizer'] ?? 'Организатор',
          date: event['date_text'] ?? 'Скоро',
          location: event['location'] ?? 'Локация',
          chatLink: event['chat_link'] ?? '',
          description: event['description'] ?? '',
          responsibilities: (event['responsibilities'] as String? ?? 'Участие в мероприятии').split('\n'),
          benefits: (event['benefits'] as String? ?? 'Volo-часы').split('\n'),
          eventId: event['id'],
          imageUrl: event['image_url'], // Pass to detail page
        ),
      ),
    );
  }

  Widget _buildEmptyOffersPlaceholder() {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_note_rounded, color: Colors.grey, size: 30),
            const SizedBox(height: 8),
            Text('Ждем новых ивентов!', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoEventsState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Text('Ивентов пока нет', style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 16)),
            const SizedBox(height: 8),
            Text('Загляните позже!', style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 14)),
          ],
        ),
      ),
    );
  }
}