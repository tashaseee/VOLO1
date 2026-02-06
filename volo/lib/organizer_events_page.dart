import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';
import 'services/api_service.dart';
import 'organizer_event_applications_page.dart';
import 'event_reviews_page.dart';

class OrganizerEventsPage extends StatefulWidget {
  const OrganizerEventsPage({super.key});

  @override
  State<OrganizerEventsPage> createState() => _OrganizerEventsPageState();
}

class _OrganizerEventsPageState extends State<OrganizerEventsPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _events = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, active, inactive
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    final result = await _apiService.getMyEvents();
    if (mounted) {
      setState(() {
        if (result['success']) {
          _events = result['data'];
        }
        _isLoading = false;
      });
    }
  }

  List<dynamic> get filteredEvents {
    List<dynamic> filtered = _events;
    
    // Filter by status
    if (_filter == 'active') {
      filtered = filtered.where((e) => e['is_active'] == true).toList();
    } else if (_filter == 'inactive') {
      filtered = filtered.where((e) => e['is_active'] == false).toList();
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((e) => 
        (e['title'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (e['location'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    return filtered;
  }

  Future<void> _toggleStatus(int eventId) async {
    final result = await _apiService.toggleEventStatus(eventId);
    if (result['success']) {
      _loadEvents();
      if (mounted) {
        _showSuccessSnackBar('Статус ивента обновлен!', const Color(0xFF983296));
      }
    } else {
      if (mounted) {
        _showErrorSnackBar('Ошибка: ${result['message']}');
      }
    }
  }

  Future<void> _finishEvent(int eventId) async {
    final result = await _apiService.finishEvent(eventId);
    if (result['success']) {
      _loadEvents();
      if (mounted) {
        _showSuccessSnackBar('Ивент успешно завершен! 🎉\nЧасы начислены волонтерам.', const Color(0xFF00BFA5));
      }
    } else {
      if (mounted) {
        _showErrorSnackBar('Ошибка: ${result['message']}');
      }
    }
  }

  Future<void> _showFinishDialog(int eventId, String title) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Завершить ивент?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Вы уверены, что хотите завершить "$title"?', style: GoogleFonts.poppins(fontSize: 14)),
            const SizedBox(height: 12),
            _buildCheckItem('Все APPROVED волонтеры получат часы'),
            const SizedBox(height: 8),
            _buildCheckItem('Отправятся уведомления о сертификатах'),
            const SizedBox(height: 8),
            _buildCheckItem('Ивент перейдет в архив'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _finishEvent(eventId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Завершить', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: Color(0xFF00BFA5), size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]))),
      ],
    );
  }

  void _showSuccessSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    _showSuccessSnackBar(message, Colors.redAccent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          // Background Decorative Elements
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF983296).withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF983296).withOpacity(0.02),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildSearchBar(),
                _buildFilters(),
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState()
                      : filteredEvents.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _loadEvents,
                              color: const Color(0xFF983296),
                              edgeOffset: 20,
                              child: ListView.builder(
                                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100),
                                itemCount: filteredEvents.length,
                                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                itemBuilder: (context, index) {
                                  final event = filteredEvents[index];
                                  return _buildModernEventCard(event, index);
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _isLoading ? null : _buildFAB(),
    );
  }

  Widget _buildFAB() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20, right: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF983296), Color(0xFFB856B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF983296).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/add_event').then((_) => _loadEvents()),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Создать ивент',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SvgPicture.asset(
                'assets/images/VOLO-2.svg',
                height: 24,
                colorFilter: const ColorFilter.mode(Color(0xFF983296), BlendMode.srcIn),
              ),
              GestureDetector(
                onTap: () => _loadEvents(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.refresh_rounded, color: Color(0xFF0D0D26), size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'МОИ ',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0D0D26),
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: 'ИВЕНТЫ',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF983296),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Управление вашими мероприятиями',
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: const Color(0xFF95969D),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildModernEventCard(Map<String, dynamic> event, int index) {
    final bool isActive = event['is_active'] == true;
    final String title = event['title'] ?? 'Без названия';
    final String location = event['location'] ?? 'Локация не указана';
    final String date = event['date_text'] ?? 'Дата не указана';
    final String? imageUrl = event['image_url'];
    final int hours = event['hours'] ?? 0;
    
    return GestureDetector(
      onTap: () {
        if (isActive) {
          _navigateToApplications(event);
        } else {
          _navigateToReviews(event);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F1F5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Container(
                    height: 190,
                    width: double.infinity,
                    color: const Color(0xFFF5F5F5),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            'http://127.0.0.1:8000$imageUrl',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                          )
                        : _buildPlaceholderImage(),
                  ),
                ),
                // Gradient Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                  ),
                ),
                // Status Badge
                Positioned(
                  top: 16,
                  left: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (isActive ? Colors.green : Colors.orange).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (isActive ? Colors.green : Colors.orange).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isActive ? Colors.green : Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isActive ? 'Активен' : 'В архиве',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Toggle Status Button (Close Recruitment)
                if (isActive)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => _showFinishDialog(event['id'], event['title'] ?? 'Ивент'),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00BFA5).withOpacity(0.9), // Greenish for Finish
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline_rounded, size: 14, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  'ЗАВЕРШИТЬ',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Date Pill
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      date,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF983296),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                // Rating Badge for Archived Events
                if (!isActive)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBC05),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            (event['rating'] ?? 4.8).toString(),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Hours Badge
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF983296),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '+$hours ч',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Content Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0D0D26),
                      letterSpacing: -0.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isActive) ...[
                    const SizedBox(height: 16),
                    _buildRecruitmentProgress(event['approved_count'] ?? 0, event['volunteer_count'] ?? 10),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF95969D)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          location,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF95969D),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(height: 1, color: const Color(0xFFF1F1F5)),
                  const SizedBox(height: 16),
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem(
                        isActive ? Icons.people_outline_rounded : Icons.star_outline_rounded,
                        isActive ? 'Заявки' : 'Отзывы',
                        isActive ? 'Управление' : (event['reviews_count'] ?? 12).toString() + ' отзывов',
                      ),
                      Row(
                        children: [
                          if (!isActive)
                            GestureDetector(
                              onTap: () => _toggleStatus(event['id']),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F1F5),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF983296), size: 18),
                              ),
                            ),
                          _buildActionButton(isActive ? 'Смотреть' : 'Отзывы'),
                        ],
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

  Widget _buildRecruitmentProgress(int approved, int total) {
    double progress = total > 0 ? (approved / total).clamp(0.0, 1.0) : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Набрано волонтеров',
              style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF95969D), fontWeight: FontWeight.w500),
            ),
            Text(
              '$approved / $total',
              style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF0D0D26), fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: const Color(0xFFF1F1F5),
            color: progress >= 1.0 ? Colors.green : const Color(0xFF983296),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF983296), Color(0xFFB856B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Opacity(
          opacity: 0.1,
          child: SvgPicture.asset(
            'assets/images/mask.svg',
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF983296)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF95969D),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0D0D26),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF983296), Color(0xFFB856B8)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF983296).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF983296).withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_note_rounded,
                size: 80,
                color: Color(0xFF983296),
              ),
            ),
            const SizedBox(height: 40),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'НЕТ ',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0D0D26),
                    ),
                  ),
                  TextSpan(
                    text: 'ИВЕНТОВ',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF983296),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Создайте свое первое мероприятие и пригласите волонтеров прямо сейчас!',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: const Color(0xFF95969D),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/add_event').then((_) => _loadEvents()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF983296), Color(0xFFB856B8)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF983296).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Text(
                  'Создать первый ивент',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF983296),
        strokeWidth: 3,
      ),
    );
  }

  Future<void> _navigateToApplications(Map<String, dynamic> event) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrganizerEventApplicationsPage(
          eventId: event['id'],
          eventTitle: event['title'],
        ),
      ),
    );
    if (result == true) {
      _loadEvents();
    }
  }

  void _navigateToReviews(Map<String, dynamic> event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventReviewsPage(
          eventTitle: event['title'] ?? 'Без названия',
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF1F1F5)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF0D0D26)),
          decoration: InputDecoration(
            hintText: 'Поиск...',
            hintStyle: GoogleFonts.poppins(color: const Color(0xFF95969D), fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF95969D), size: 18),
            suffixIcon: _searchQuery.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF95969D)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 0), // Centered vertically
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final filters = [
      {'label': 'Все', 'value': 'all'},
      {'label': 'Активные', 'value': 'active'},
      {'label': 'Архив', 'value': 'inactive'}, // inactive mapped to Archive logic
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          final isSelected = _filter == f['value'];
          return GestureDetector(
            onTap: () => setState(() => _filter = f['value']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF983296) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? const Color(0xFF983296) : const Color(0xFFF1F1F5),
                  width: 1,
                ),
              ),
              child: Text(
                f['label']!,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF95969D),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}



