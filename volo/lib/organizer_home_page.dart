import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import 'services/api_service.dart';

class OrganizerHomePage extends StatefulWidget {
  final Function(int)? onTabChange;

  const OrganizerHomePage({super.key, this.onTabChange});

  @override
  State<OrganizerHomePage> createState() => _OrganizerHomePageState();
}

class _OrganizerHomePageState extends State<OrganizerHomePage> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _userData;
  List<dynamic> _myEvents = [];
  bool _isLoading = true;
  
  final PageController _adController = PageController();
  int _currentAdIndex = 0;
  final List<String> adImages = [
    'assets/images/zhar.png', // Используем те же баннеры
    'assets/images/don.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    Future.delayed(const Duration(seconds: 4), _autoScrollAds);
  }

  void _autoScrollAds() {
    if (!mounted) return;
    final nextPage = (_currentAdIndex + 1) % adImages.length;
    _adController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    Future.delayed(const Duration(seconds: 4), _autoScrollAds);
  }

  @override
  void dispose() {
    _adController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final userResult = await _apiService.getUserProfile();
    final eventsResult = await _apiService.getMyEvents();
    
    if (mounted) {
      if (userResult['success']) {
        _userData = userResult['data'];
      }
      if (eventsResult['success']) {
        _myEvents = eventsResult['data'];
      }
      
      List<dynamic> allApplications = [];
      for (var event in _myEvents) {
        final appsResult = await _apiService.getEventApplications(event['id']);
        if (appsResult['success']) {
          allApplications.addAll(appsResult['data']);
        }
      }
      allApplications.sort((a, b) => b['created_at'].compareTo(a['created_at']));
      _recentApplications = allApplications.take(5).toList();

      setState(() => _isLoading = false);
    }
  }

  List<dynamic> _recentApplications = [];

  @override
  Widget build(BuildContext context) {
    final orgName = _userData?['org_profile']?['full_name'] ?? 'Организация';
    final avatarUrl = _userData?['org_profile']?['avatar_url'];
    final activeEvents = _myEvents.where((e) => e['is_active'] == true).toList();
    final totalApps = _myEvents.fold<int>(0, (sum, event) => sum + (event['applications_count'] as int? ?? 0));

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF983296)))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF983296),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    // Header Logo
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/images/VOLO-2.svg',
                          height: 21,
                          colorFilter: const ColorFilter.mode(Color(0xFF983296), BlendMode.srcIn),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Welcome & Avatar
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Добро пожаловать!', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w300, color: const Color(0xFF95969D))),
                              const SizedBox(height: 4),
                              Text(orgName, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w500, color: const Color(0xFF0D0D26))),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => widget.onTabChange?.call(4),
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                              border: Border.all(color: const Color(0xFFF1F1F5)),
                            ),
                            child: ClipOval(
                              child: avatarUrl != null && avatarUrl.isNotEmpty
                                  ? Image.network(
                                      'http://127.0.0.1:8000$avatarUrl',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_,__,___) => Image.asset('assets/images/org.png', fit: BoxFit.cover),
                                    )
                                  : Center(
                                      child: Text(
                                        orgName.isNotEmpty ? orgName[0].toUpperCase() : 'O',
                                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF983296)),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Main Stats Block (Gradient)
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF983296), Color(0xFFB856B8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF983296).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Stack(
                        children: [
                          // Decorative circles
                          Positioned(right: -20, top: -20, child: CircleAvatar(radius: 40, backgroundColor: Colors.white.withOpacity(0.1))),
                          Positioned(left: -30, bottom: -30, child: CircleAvatar(radius: 50, backgroundColor: Colors.white.withOpacity(0.1))),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Активные ивенты', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white70)),
                                  Text(activeEvents.length.toString(), style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w600, color: Colors.white)),
                                ],
                              ),
                              Container(
                                width: 1, height: 40, color: Colors.white24,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Всего заявок', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white70)),
                                  Text(totalApps.toString(), style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w600, color: Colors.white)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Banner Carousel
                    SizedBox(
                      height: 93,
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: _adController,
                            onPageChanged: (i) => setState(() => _currentAdIndex = i),
                            itemCount: adImages.length,
                            itemBuilder: (context, index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(adImages[index], fit: BoxFit.cover, width: double.infinity, height: 93),
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
                                decoration: BoxDecoration(shape: BoxShape.circle, color: _currentAdIndex == i ? const Color(0xFF983296) : Colors.grey[400]),
                              )),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Quick Actions
                    Text('Быстрые действия', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF0D0D26))),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildQuickActionCard('Создать\nивент', Icons.add_circle_outline, () => Navigator.pushNamed(context, '/add_event'), const Color(0xFF983296), isPrimary: true),
                        const SizedBox(width: 12),
                        _buildQuickActionCard('Все\nзаявки', Icons.people_outline, () {}, const Color(0xFF4B68FF)), 
                        const SizedBox(width: 12),
                        _buildQuickActionCard('История\nивентов', Icons.history, () {}, const Color(0xFFFF9C00)),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Active Events List (Horizontal)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Ваши события', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF0D0D26))),
                        GestureDetector(
                          onTap: () => widget.onTabChange?.call(3),
                          child: Text('Все', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF983296))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    SizedBox(
                      height: 210, // Высота карточки
                      child: activeEvents.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: activeEvents.length,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) => _buildEventCard(activeEvents[index]),
                          ),
                    ),
                    
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, VoidCallback onTap, Color color, {bool isPrimary = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: isPrimary ? const Color(0xFF983296) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isPrimary ? null : Border.all(color: const Color(0xFFF1F1F5)),
            boxShadow: [
              BoxShadow(
                color: isPrimary ? const Color(0xFF983296).withOpacity(0.3) : Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPrimary ? Colors.white.withOpacity(0.2) : color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: isPrimary ? Colors.white : color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12, // slightly smaller font
                  fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
                  color: isPrimary ? Colors.white : const Color(0xFF0D0D26),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(dynamic event) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F1F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SizedBox(
              height: 100,
              width: double.infinity,
              child: event['image_url'] != null
                  ? Image.network(
                      'http://127.0.0.1:8000${event['image_url']}',
                      fit: BoxFit.cover,
                      errorBuilder: (_,__,___) => Image.asset('assets/images/photo.png', fit: BoxFit.cover),
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
                  event['title'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0D0D26)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 12, color: Color(0xFF983296)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event['date_text'] ?? 'Скоро',
                        style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF983296)),
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.people, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${event['applications_count'] ?? 0} заявок', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F1F5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/home.svg', // Используем что-то тематическое или иконку
            height: 40,
            colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
          ),
          const SizedBox(height: 8),
          Text('Нет активных ивентов', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
