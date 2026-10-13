import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'services/api_service.dart';
import 'blocs/organizer_home/organizer_home_bloc.dart';
import 'notifications_page.dart';
import 'organizer_event_applications_page.dart';

class OrganizerHomePage extends StatelessWidget {
  final Function(int)? onTabChange;
  const OrganizerHomePage({super.key, this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OrganizerHomeBloc(apiService: ApiService())..add(LoadOrganizerHomeData()),
      child: _OrganizerHomeView(onTabChange: onTabChange),
    );
  }
}

class _OrganizerHomeView extends StatefulWidget {
  final Function(int)? onTabChange;
  const _OrganizerHomeView({this.onTabChange});
  @override
  State<_OrganizerHomeView> createState() => _OrganizerHomeViewState();
}

class _OrganizerHomeViewState extends State<_OrganizerHomeView> {
  final PageController _adController = PageController();
  final List<String> adImages = ['assets/images/zhar.png', 'assets/images/don.png'];
  final Set<int> _updatingAppIds = {};

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), _autoScrollAds);
  }

  void _autoScrollAds() {
    if (!mounted) return;
    final bloc = context.read<OrganizerHomeBloc>();
    final nextPage = (bloc.state.currentAdIndex + 1) % adImages.length;
    _adController.animateToPage(nextPage, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    Future.delayed(const Duration(seconds: 4), _autoScrollAds);
  }

  @override
  void dispose() {
    _adController.dispose();
    super.dispose();
  }

  String _getCurrentFormattedDate() {
    final now = DateTime.now();
    final weekdays = ['Воскресенье', 'Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота'];
    final months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    return '${weekdays[now.weekday % 7]}, ${now.day} ${months[now.month - 1]}';
  }

  Future<void> _updateAppStatus(int appId, String status) async {
    if (_updatingAppIds.contains(appId)) return;
    setState(() {
      _updatingAppIds.add(appId);
    });
    final result = await ApiService().updateApplicationStatus(appId, status);
    if (mounted) {
      setState(() {
        _updatingAppIds.remove(appId);
      });
    }
    if (result['success'] == true) {
      if (mounted) {
        context.read<OrganizerHomeBloc>().add(LoadOrganizerHomeData());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'approved' ? 'Заявка успешно принята!' : 'Заявка отклонена.',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: status == 'approved' ? const Color(0xFF00BFA5) : Colors.grey[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            margin: const EdgeInsets.all(20),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка обновления статуса: ${result['error'] ?? 'Неизвестная ошибка'}', style: GoogleFonts.poppins()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            margin: const EdgeInsets.all(20),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrganizerHomeBloc, OrganizerHomeState>(
      builder: (context, state) {
        final orgName = state.userData?['org_profile']?['full_name'] ?? 'Организация';
        final avatarUrl = state.userData?['org_profile']?['avatar_url'];
        final activeEvents = state.myEvents.where((e) => e['is_active'] == true).toList();
        final totalApps = state.myEvents.fold<int>(0, (sum, e) => sum + (e['applications_count'] as int? ?? 0));

        return Scaffold(
          backgroundColor: Colors.white,
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF983296), strokeWidth: 3))
              : RefreshIndicator(
                  onRefresh: () async => context.read<OrganizerHomeBloc>().add(LoadOrganizerHomeData()),
                  color: const Color(0xFF983296),
                  backgroundColor: Colors.white,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 44),
                        // Logo & Notification Header
                        Row(
                          children: [
                            SvgPicture.asset(
                              'assets/images/VOLO-2.svg',
                              height: 22,
                              colorFilter: const ColorFilter.mode(Color(0xFF983296), BlendMode.srcIn),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NotificationsPage(showNavBar: false, showBackButton: true),
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
                                ),
                                child: SvgPicture.asset(
                                  'assets/images/notifi.svg',
                                  width: 20,
                                  height: 20,
                                  colorFilter: const ColorFilter.mode(Color(0xFF0D0D26), BlendMode.srcIn),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        // Greeting Header with Live Date
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_outlined, 
                                        size: 10, 
                                        color: Color(0xFF95969D),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _getCurrentFormattedDate().toUpperCase(),
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF95969D),
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    orgName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0D0D26),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () => widget.onTabChange?.call(4),
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFF5F5F8),
                                  border: Border.all(color: const Color(0xFFF1F0F5), width: 2),
                                ),
                                child: ClipOval(
                                  child: avatarUrl != null && avatarUrl.isNotEmpty
                                      ? Image.network(
                                          '${ApiService.baseUrl}$avatarUrl',
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Image.asset(
                                            'assets/images/org.png',
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            orgName.isNotEmpty ? orgName[0].toUpperCase() : 'O',
                                            style: GoogleFonts.poppins(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF983296),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Unified Premium Metrics Container
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0D0D26).withValues(alpha: 0.015),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              _buildUnifiedMetricItem(
                                'Ивенты', 
                                state.myEvents.length.toString(), 
                                'Активные в сети', 
                                Icons.event_note_rounded, 
                                const Color(0xFF983296), 
                                () => widget.onTabChange?.call(3),
                              ),
                              _buildVerticalDivider(),
                              _buildUnifiedMetricItem(
                                'Рейтинг', 
                                '4.8', 
                                'Отличные отзывы', 
                                Icons.star_rounded, 
                                const Color(0xFFFF9C00), 
                                () {},
                              ),
                              _buildVerticalDivider(),
                              _buildUnifiedMetricItem(
                                'Заявки', 
                                totalApps.toString(), 
                                'Ожидают ответа', 
                                Icons.people_alt_rounded, 
                                const Color(0xFF00BFA5), 
                                () => widget.onTabChange?.call(3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Ad carousel
                        Container(
                          height: 96,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
                          ),
                          child: Stack(
                            children: [
                              PageView.builder(
                                controller: _adController,
                                onPageChanged: (i) => context.read<OrganizerHomeBloc>().add(ChangeOrganizerAdIndex(i)),
                                itemCount: adImages.length,
                                itemBuilder: (_, index) => ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.asset(
                                    adImages[index],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 96,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 10,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    adImages.length,
                                    (i) => AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      width: state.currentAdIndex == i ? 16 : 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(3),
                                        color: state.currentAdIndex == i ? const Color(0xFF983296) : Colors.white.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Asymmetrical Action Grid
                        Text(
                          'Быстрые действия',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0D0D26),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildAsymmetricalGrid(context),
                        const SizedBox(height: 28),
                        // Event List
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ваши события',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0D0D26),
                                letterSpacing: -0.3,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => widget.onTabChange?.call(3),
                              child: Text(
                                'Все',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF983296),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 215,
                          child: activeEvents.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: activeEvents.length,
                                  physics: const BouncingScrollPhysics(),
                                  itemBuilder: (context, index) => _buildEventCard(activeEvents[index]),
                                ),
                        ),
                        // Rich-Data Recent Applications
                        if (state.recentApplications.isNotEmpty) ...[
                          const SizedBox(height: 28),
                          Text(
                            'Недавние заявки',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0D0D26),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: state.recentApplications.length,
                            itemBuilder: (context, index) {
                              final app = state.recentApplications[index];
                              return _buildRecentAppTile(app);
                            },
                          ),
                        ],
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildUnifiedMetricItem(String label, String value, String subtext, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0D0D26),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0D0D26),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtext,
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF95969D),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1.5,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F0F5),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildAsymmetricalGrid(BuildContext context) {
    return Column(
      children: [
        // Spotlight primary card (Создать ивент) - Double width
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/add_event').then((_) => context.read<OrganizerHomeBloc>().add(LoadOrganizerHomeData())),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF983296).withValues(alpha: 0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF983296).withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF983296).withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Color(0xFF983296),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Создать ивент',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0D0D26),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Пригласите волонтеров на новое событие',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF95969D),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF983296),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Secondary side-by-side tiles
        Row(
          children: [
            _buildSecondaryActionTile(
              'Чаты команды',
              'Связь в реальном времени',
              Icons.chat_bubble_outline_rounded,
              const Color(0xFF4B68FF),
              () => widget.onTabChange?.call(2),
            ),
            const SizedBox(width: 12),
            _buildSecondaryActionTile(
              'История ивентов',
              'Архив ваших событий',
              Icons.history_rounded,
              const Color(0xFFFF9C00),
              () => widget.onTabChange?.call(3),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecondaryActionTile(String title, String description, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 110,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D0D26).withValues(alpha: 0.01),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0D0D26),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF95969D),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(dynamic event) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrganizerEventApplicationsPage(
              eventId: event['id'],
              eventTitle: event['title'] ?? 'Ивент',
            ),
          ),
        ).then((_) => context.read<OrganizerHomeBloc>().add(LoadOrganizerHomeData()));
      },
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D0D26).withValues(alpha: 0.015),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18.5)),
              child: SizedBox(
                height: 105,
                width: double.infinity,
                child: event['image_url'] != null
                    ? Image.network(
                        '${ApiService.baseUrl}${event['image_url']}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/photo.png',
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset('assets/images/photo.png', fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['title'] ?? 'Без названия',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0D0D26),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF983296)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event['date_text'] ?? 'Скоро',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF983296),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.people_outline_rounded, size: 12, color: Color(0xFF95969D)),
                      const SizedBox(width: 6),
                      Text(
                        '${event['applications_count'] ?? 0} заявок',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF95969D),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAppTile(dynamic app) {
    final user = app['user'] ?? {};
    final profile = user['profile'] ?? {};
    final String volunteerName = profile['full_name'] ?? user['email'] ?? 'Волонтер';
    final String avatarUrl = profile['avatar_url'] ?? '';
    final String eventTitle = app['event_title'] ?? 'Мероприятие';
    
    final int hours = profile['volo_hours'] ?? 0;
    final String experienceTag = hours > 0 ? '$hours ч опыта' : 'Новичок';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D0D26).withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFFF5F5F8),
              border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: avatarUrl.isNotEmpty
                  ? Image.network(
                      avatarUrl.startsWith('http') ? avatarUrl : '${ApiService.baseUrl}$avatarUrl',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildInitials(volunteerName),
                    )
                  : _buildInitials(volunteerName),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        volunteerName,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0D0D26),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF983296).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        experienceTag,
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF983296),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  eventTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF95969D),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildRecentAppActionOrStatus(app),
        ],
      ),
    );
  }

  Widget _buildRecentAppActionOrStatus(dynamic app) {
    final int appId = app['id'] as int;
    final String status = app['status'] as String? ?? 'pending';

    if (_updatingAppIds.contains(appId)) {
      return const SizedBox(
        width: 44,
        height: 24,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF983296)),
            ),
          ),
        ),
      );
    }

    if (status == 'approved') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF00BFA5).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'Принят',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF00BFA5),
          ),
        ),
      );
    } else if (status == 'rejected') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'Отклонён',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFEF4444),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _updateAppStatus(appId, 'rejected'),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
            ),
            child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF95969D)),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _updateAppStatus(appId, 'approved'),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF00BFA5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildInitials(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'V',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF983296),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF983296).withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              color: Color(0xFF983296),
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Нет активных ивентов',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0D0D26),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Нажмите «Создать ивент», чтобы начать',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF95969D),
            ),
          ),
        ],
      ),
    );
  }
}
