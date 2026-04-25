import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:volo/home_page.dart';
import 'package:volo/search_page.dart';
import 'package:volo/profile_page.dart';
import 'package:volo/notifications_page.dart';
import 'package:volo/chats_page.dart';
import 'bottom_nav_bar.dart';
import 'package:volo/event_detail_page.dart';
import 'services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'blocs/applications/applications_bloc.dart';

class MyApplicationsPage extends StatelessWidget {
  const MyApplicationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ApplicationsBloc(apiService: ApiService())..add(LoadApplications()),
      child: const _MyApplicationsView(),
    );
  }
}

class _MyApplicationsView extends StatelessWidget {
  const _MyApplicationsView();

  void _onItemTapped(BuildContext context, int index) {
    if (index == 3) { Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const ChatsPage(), transitionDuration: Duration.zero)); return; }
    switch (index) {
      case 0: Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const NotificationsPage(), transitionDuration: Duration.zero)); break;
      case 1: Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const SearchPage(), transitionDuration: Duration.zero)); break;
      case 2: Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const HomePage(), transitionDuration: Duration.zero)); break;
      case 4: Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const ProfilePage(), transitionDuration: Duration.zero)); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ApplicationsBloc, ApplicationsState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              Positioned(
                top: -50, right: -50,
                child: Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF983296).withOpacity(0.03),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    _buildTabSection(context, state),
                    Expanded(
                      child: state.isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF983296)))
                        : RefreshIndicator(
                            onRefresh: () async => context.read<ApplicationsBloc>().add(LoadApplications()),
                            color: const Color(0xFF983296),
                            child: state.selectedTab == 0
                              ? _buildList(context, state.applications.where((a) => a['status'] != 'completed' && a['status'] != 'rejected').toList(), 'Нет активных заявок')
                              : _buildList(context, state.applications.where((a) => a['status'] == 'completed' || a['status'] == 'rejected').toList(), 'Нет архивных заявок'),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: CustomBottomNavBar(
            currentIndex: 3,
            onTap: (i) => _onItemTapped(context, i),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SvgPicture.asset('assets/images/VOLO-2.svg', height: 24,
                colorFilter: const ColorFilter.mode(Color(0xFF983296), BlendMode.srcIn)),
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: const Icon(Icons.tune_rounded, color: Color(0xFF0D0D26), size: 20),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Мои ивенты', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700, color: const Color(0xFF0D0D26), letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text('Отслеживайте статус ваших заявок', style: GoogleFonts.poppins(fontSize: 15, color: const Color(0xFF95969D), fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }

  Widget _buildTabSection(BuildContext context, ApplicationsState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildTabChip(context, state, 'Активные', 0),
          const SizedBox(width: 12),
          _buildTabChip(context, state, 'Архивные', 1),
        ],
      ),
    );
  }

  Widget _buildTabChip(BuildContext context, ApplicationsState state, String title, int index) {
    final isActive = state.selectedTab == index;
    return GestureDetector(
      onTap: () => context.read<ApplicationsBloc>().add(ChangeApplicationTab(index)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF983296) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive ? [BoxShadow(color: const Color(0xFF983296).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
          border: Border.all(color: isActive ? const Color(0xFF983296) : Colors.grey[200]!),
        ),
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? Colors.white : const Color(0xFF95969D),
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<dynamic> apps, String emptyMessage) {
    if (apps.isEmpty) return _buildEmptyState(emptyMessage);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      itemCount: apps.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, i) => _buildCard(context, apps[i]),
    );
  }

  Widget _buildCard(BuildContext context, dynamic app) {
    final event = app['event'];
    final status = app['status'];
    final String title = event['title'] ?? 'Без названия';
    final String org = event['organizer'] ?? 'Организатор';
    final String date = event['date_text'] ?? 'Скоро';
    final String? imageUrl = event['image_url'];

    Color statusColor;
    String statusText;
    switch (status) {
      case 'approved': statusColor = Colors.green; statusText = 'Принята'; break;
      case 'rejected': statusColor = Colors.red; statusText = 'Отклонена'; break;
      case 'completed': statusColor = Colors.grey; statusText = 'Завершена'; break;
      default: statusColor = Colors.orange; statusText = 'На рассмотрении';
    }

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => EventDetailPage(
          eventTitle: title, organizer: org, date: date,
          location: event['location'] ?? 'Локация', chatLink: '',
          description: event['description'] ?? '',
          responsibilities: const ['Участие в мероприятии'],
          benefits: ['${event['hours'] ?? 0} часов волонтерства'],
          eventId: event['id'],
        ),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: SizedBox(
                    height: 140, width: double.infinity,
                    child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network('http://127.0.0.1:8080$imageUrl', fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder())
                      : _buildPlaceholder(),
                  ),
                ),
                Positioned(
                  top: 12, left: 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: statusColor.withOpacity(0.3)),
                        ),
                        child: Text(statusText, style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0D0D26)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(org, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF95969D), fontWeight: FontWeight.w500)),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Align(alignment: Alignment.centerLeft, child: _buildInfoItem(Icons.calendar_today_outlined, date))),
                      const SizedBox(width: 8),
                      Expanded(child: Align(alignment: Alignment.centerRight, child: _buildInfoItem(Icons.location_on_outlined, event['location'] ?? 'Онлайн'))),
                    ],
                  ),
                  if (status == 'approved' && event['chat_link'] != null && event['chat_link'].isNotEmpty) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final link = event['chat_link'];
                          if (link != null && link.isNotEmpty) {
                            final Uri url = Uri.parse(link.startsWith('http') ? link : 'https://$link');
                            if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error launching $link')));
                            }
                          }
                        },
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                        label: const Text('Перейти в чат'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF983296).withOpacity(0.1),
                          foregroundColor: const Color(0xFF983296),
                          elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF983296), Color(0xFFB856B8)])),
      child: Center(child: Opacity(opacity: 0.1, child: SvgPicture.asset('assets/images/mask.svg', fit: BoxFit.cover))),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF983296)),
        const SizedBox(width: 6),
        Flexible(child: Text(text, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF0D0D26), fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: const Color(0xFF983296).withOpacity(0.05), shape: BoxShape.circle),
            child: const Icon(Icons.event_note_outlined, size: 80, color: Color(0xFF983296)),
          ),
          const SizedBox(height: 24),
          Text(message, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF0D0D26))),
          const SizedBox(height: 8),
          Text('Найдите интересное событие прямо сейчас!', style: GoogleFonts.poppins(color: const Color(0xFF95969D), fontSize: 14)),
        ],
      ),
    );
  }
}