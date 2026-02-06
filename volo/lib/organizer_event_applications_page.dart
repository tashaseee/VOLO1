import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';
import 'services/api_service.dart';
import 'volunteer_profile_details_page.dart';

class OrganizerEventApplicationsPage extends StatefulWidget {
  final int eventId;
  final String eventTitle;

  const OrganizerEventApplicationsPage({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<OrganizerEventApplicationsPage> createState() => _OrganizerEventApplicationsPageState();
}

class _OrganizerEventApplicationsPageState extends State<OrganizerEventApplicationsPage> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<dynamic> _applications = [];
  Map<String, dynamic>? _event;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadApplications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    
    // Fetch applications and event details in parallel
    final results = await Future.wait([
      _apiService.getEventApplications(widget.eventId),
      _apiService.getMyEvents(), // To find the specific event and its chat link
    ]);

    final appsResult = results[0];
    final eventsResult = results[1];

    if (mounted) {
      setState(() {
        if (appsResult['success']) {
          _applications = appsResult['data'];
        }
        if (eventsResult['success']) {
          final events = eventsResult['data'] as List;
          _event = events.firstWhere((e) => e['id'] == widget.eventId, orElse: () => null);
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(int applicationId, String status, {Map<String, dynamic>? app}) async {
    final result = await _apiService.updateApplicationStatus(applicationId, status);
    if (result['success']) {
      await _loadApplications();
      if (mounted) {
        if (status == 'approved') {
          _showAcceptanceDialog(app?['user']);
        } else {
          _showSuccessSnackBar('Заявка отклонена ❌', Colors.red);
        }
      }
    } else {
      if (mounted) {
        _showErrorSnackBar('Ошибка: ${result['message']}');
      }
    }
  }

  Future<void> _finishEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Завершить ивент?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'Это действие начислит часы всем принятым волонтерам и закроет возможность подачи заявок. Вы уверены?',
          style: GoogleFonts.poppins(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Завершить', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      final result = await _apiService.finishEvent(widget.eventId);
      if (mounted) {
        setState(() => _isLoading = false);
        if (result['success']) {
          _showSuccessSnackBar(result['message'] ?? 'Ивент успешно завершен!', Colors.green);
        } else {
          _showErrorSnackBar(result['message'] ?? 'Ошибка завершения');
        }
      }
    }
  }

  void _showAcceptanceDialog(Map<String, dynamic>? user) {
    final profile = user?['profile'];
    final name = profile?['full_name'] ?? user?['email'] ?? 'Волонтер';
    final chatLinkStr = _event?['chat_link'] ?? 'https://t.me/volo_chat_example';

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF983296), Color(0xFFB856B8)]),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 60),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
                child: Column(
                  children: [
                    Text(
                      'Волонтер принят!',
                      style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0D0D26)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Вы успешно приняли $name для участия в ивенте. Мы отправили ему уведомление и ссылку на чат:',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF6B6B7B), height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.link_rounded, size: 18, color: Color(0xFF983296)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              chatLinkStr,
                              style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF983296), fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF983296),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                    ),
                    child: Text(
                      'ОТЛИЧНО',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  List<dynamic> get pendingApplications =>
      _applications.where((a) => a['status'] == 'pending').toList();
  
  List<dynamic> get approvedApplications =>
      _applications.where((a) => a['status'] == 'approved').toList();
  
  List<dynamic> get rejectedApplications =>
      _applications.where((a) => a['status'] == 'rejected').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          // Background Decorative Elements
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF983296).withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            left: -120,
            child: Container(
              width: 250,
              height: 250,
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
                _buildTabSection(),
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState()
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildApplicationsList(pendingApplications, 'pending'),
                            _buildApplicationsList(approvedApplications, 'approved'),
                            _buildApplicationsList(rejectedApplications, 'rejected'),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context, true),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF1F1F5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0D0D26), size: 18),
                ),
              ),
              Row(
                children: [
                   GestureDetector(
                    onTap: _finishEvent,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                      ),
                      child: const Icon(Icons.flag_rounded, color: Colors.redAccent, size: 20),
                    ),
                  ),
                  GestureDetector(
                    onTap: _loadApplications,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFF1F1F5)),
                      ),
                      child: const Icon(Icons.refresh_rounded, color: Color(0xFF0D0D26), size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'ЗАЯВКИ ',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0D0D26),
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: 'ВОЛОНТЕРОВ',
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
          const SizedBox(height: 6),
          Text(
            widget.eventTitle.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF95969D),
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28),
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F1F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFF983296), Color(0xFFB856B8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF983296).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF95969D),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.all(5),
        tabs: [
          _buildTabItem('Новые', pendingApplications.length),
          _buildTabItem('Приняты', approvedApplications.length),
          _buildTabItem('Отказ', rejectedApplications.length),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int count) {
    return Tab(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationsList(List<dynamic> applications, String status) {
    if (applications.isEmpty) {
      return _buildEmptyState(status);
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      color: const Color(0xFF983296),
      edgeOffset: 20,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100, top: 8),
        itemCount: applications.length,
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        itemBuilder: (context, index) {
          final app = applications[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VolunteerProfileDetailsPage(
                    volunteerData: app['user'],
                    applicationDate: app['created_at'] != null ? _formatDate(app['created_at']) : 'Сегодня',
                  ),
                ),
              );
            },
            child: _buildModernApplicationCard(app, status),
          );
        },
      ),
    );
  }

  Widget _buildModernApplicationCard(Map<String, dynamic> app, String status) {
    final user = app['user'];
    final profile = user?['profile'];
    final String name = profile?['full_name'] ?? user?['email'] ?? 'Аноним';
    final String avatarUrl = profile?['avatar_url'] ?? '';
    final String date = app['created_at'] != null ? _formatDate(app['created_at']) : 'Сегодня';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                // Premium Avatar
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF1F1F5)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: avatarUrl.isNotEmpty
                        ? Image.network(
                            avatarUrl.startsWith('http') ? avatarUrl : '${ApiService.baseUrl}$avatarUrl',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(name),
                          )
                        : _buildAvatarPlaceholder(name),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0D0D26),
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?['email'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF95969D),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF983296).withOpacity(0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF983296)),
                                const SizedBox(width: 4),
                                Text(
                                  date,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: const Color(0xFF983296),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (status != 'pending') 
                  _buildStatusPill(status),
              ],
            ),
            if (status == 'pending') ...[
              const SizedBox(height: 24),
              Container(height: 1, color: const Color(0xFFF1F1F5)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      'Отклонить',
                      const Color(0xFF95969D).withOpacity(0.05),
                      const Color(0xFF95969D),
                      () => _updateStatus(app['id'], 'rejected'),
                      icon: Icons.close_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      'Принять',
                      const Color(0xFF983296),
                      Colors.white,
                      () => _updateStatus(app['id'], 'approved', app: app),
                      icon: Icons.check_rounded,
                      isGradient: true,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String name) {
    return Center(
      child: Text(
        name[0].toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF983296),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    bool isApproved = status == 'approved';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (isApproved ? Colors.green : Colors.red).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isApproved ? Colors.green : Colors.red).withOpacity(0.1),
        ),
      ),
      child: Text(
        isApproved ? 'Принят' : 'Отказ',
        style: GoogleFonts.poppins(
          color: isApproved ? Colors.green : Colors.red,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Color bgColor, Color textColor, VoidCallback onTap, {IconData? icon, bool isGradient = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isGradient ? null : bgColor,
          gradient: isGradient ? const LinearGradient(
            colors: [Color(0xFF983296), Color(0xFFB856B8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ) : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isGradient ? [
            BoxShadow(
              color: const Color(0xFF983296).withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.poppins(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    IconData icon;
    String text;
    String subtext;
    switch (status) {
      case 'approved':
        icon = Icons.verified_user_rounded;
        text = 'НЕТ ПРИНЯТЫХ';
        subtext = 'Здесь появятся волонтеры, которых вы подтвердите для участия в ивенте';
        break;
      case 'rejected':
        icon = Icons.person_off_rounded;
        text = 'НЕТ ОТКЛОНЕННЫХ';
        subtext = 'Здесь будут отображаться заявки, которые не прошли отбор';
        break;
      default:
        icon = Icons.mail_rounded;
        text = 'НОВЫХ ЗАЯВОК НЕТ';
        subtext = 'Как только кто-то захочет присоединиться, вы увидите это здесь';
    }

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
              child: Icon(icon, size: 64, color: const Color(0xFF983296).withOpacity(0.5)),
            ),
            const SizedBox(height: 32),
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0D0D26),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtext,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF95969D),
                height: 1.5,
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

  String _formatDate(String dateStr) {
    try {
      // Force UTC interpretation if no timezone info is present, assuming server sends UTC
      DateTime date;
      if (!dateStr.endsWith('Z') && !dateStr.contains('+')) {
         date = DateTime.parse('${dateStr}Z').toLocal();
      } else {
         date = DateTime.parse(dateStr).toLocal();
      }
      
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inMinutes < 1) return 'Только что';
      if (diff.inMinutes < 60) return '${diff.inMinutes}м назад';
      if (diff.inHours < 24) return '${diff.inHours}ч назад';
      return '${date.day.toString().padLeft(2,'0')}.${date.month.toString().padLeft(2,'0')}.${date.year}';
    } catch (e) {
      return 'Сегодня';
    }
  }
}


