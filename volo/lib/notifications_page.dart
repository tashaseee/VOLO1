import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:volo/home_page.dart';
import 'package:volo/search_page.dart';
import 'package:volo/my_applications_page.dart';
import 'package:volo/profile_page.dart';
import 'bottom_nav_bar.dart';
import 'services/api_service.dart';
import 'blocs/notifications/notifications_bloc.dart';
import 'widgets/approval_notification_overlay.dart';
import 'chat_room_page.dart';

class NotificationsPage extends StatelessWidget {
  final bool showNavBar;
  const NotificationsPage({super.key, this.showNavBar = true});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationsBloc(apiService: ApiService())..add(LoadNotifications()),
      child: _NotificationsView(showNavBar: showNavBar),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  final bool showNavBar;
  const _NotificationsView({required this.showNavBar});

  void _onItemTapped(BuildContext context, int index) {
    if (index == 0) return;
    switch (index) {
      case 1: Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const SearchPage(), transitionDuration: Duration.zero)); break;
      case 2: Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const HomePage(), transitionDuration: Duration.zero)); break;
      case 3: Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const MyApplicationsPage(), transitionDuration: Duration.zero)); break;
      case 4: Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const ProfilePage(), transitionDuration: Duration.zero)); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsBloc, NotificationsState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, state),
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF983296)))
                      : state.notifications.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: () async => context.read<NotificationsBloc>().add(LoadNotifications()),
                              color: const Color(0xFF983296),
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(vertical: 0),
                                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                itemCount: state.notifications.length,
                                separatorBuilder: (context, index) => Padding(
                                  padding: const EdgeInsets.only(left: 76, right: 24),
                                  child: Container(height: 1, color: Colors.grey[100]),
                                ),
                                itemBuilder: (context, index) => _buildNotificationCard(context, state.notifications[index]),
                              ),
                            ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: showNavBar
              ? CustomBottomNavBar(currentIndex: 0, onTap: (i) => _onItemTapped(context, i))
              : null,
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, NotificationsState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SvgPicture.asset('assets/images/VOLO-2.svg', height: 20,
                colorFilter: const ColorFilter.mode(Color(0xFF983296), BlendMode.srcIn)),
              if (state.unreadCount > 0)
                TextButton(
                  onPressed: () => context.read<NotificationsBloc>().add(MarkAllRead()),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6)),
                  child: Text('Отметить все', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF983296), fontWeight: FontWeight.w500)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Уведомления', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF0D0D26), letterSpacing: -0.5)),
              if (state.unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF983296), borderRadius: BorderRadius.circular(20)),
                  child: Text('${state.unreadCount}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, Map<String, dynamic> notification) {
    final isRead = notification['is_read'] == true;
    final type = notification['type'] ?? 'info';
    final typeColor = _getTypeColor(type);
    final typeIcon = _getTypeIcon(type);

    return Dismissible(
      key: Key(notification['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        color: const Color(0xFFFF4B4B),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
      ),
      onDismissed: (direction) => context.read<NotificationsBloc>().add(DeleteNotification(notification['id'])),
      child: GestureDetector(
        onTap: () {
          if (!isRead) context.read<NotificationsBloc>().add(MarkAsRead(notification['id']));
          // Если это уведомление о принятии — показываем красивый overlay с переходом в чат
          if (type == 'approved' && notification['related_id'] != null) {
            ApprovalNotificationOverlay.show(
              context,
              chatId: notification['related_id'] as int,
              eventTitle: notification['title'] ?? 'Мероприятие',
            );
          } else {
            Navigator.pushReplacement(context, PageRouteBuilder(
              pageBuilder: (_, __, ___) => const MyApplicationsPage(),
              transitionDuration: Duration.zero,
            ));
          }
        },
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: typeColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Center(child: Icon(typeIcon, color: typeColor, size: 18)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'] ?? '',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: isRead ? FontWeight.w500 : FontWeight.w600, color: const Color(0xFF0D0D26), height: 1.2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(_formatDate(notification['created_at']), style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w400, color: const Color(0xFF95969D))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(notification['message'] ?? '', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF7A7B82), height: 1.4, fontWeight: FontWeight.w400)),
                  ],
                ),
              ),
              if (!isRead)
                Container(
                  margin: const EdgeInsets.only(left: 10, top: 2),
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: Color(0xFF983296), shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
            child: Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text('Нет уведомлений', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Здесь будут появляться уведомления\nо ваших заявках', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'success': return Colors.green;
      case 'approved': return const Color(0xFF983296);
      case 'error': return Colors.red;
      case 'warning': return Colors.orange;
      default: return const Color(0xFF983296);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'success': return Icons.check_circle;
      case 'approved': return Icons.celebration_rounded;
      case 'error': return Icons.cancel;
      case 'warning': return Icons.warning;
      default: return Icons.info;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      DateTime date;
      if (!dateStr.endsWith('Z') && !dateStr.contains('+')) {
        date = DateTime.parse('${dateStr}Z').toLocal();
      } else {
        date = DateTime.parse(dateStr).toLocal();
      }
      final now = DateTime.now();
      final difference = now.difference(date);
      if (difference.inMinutes < 1) return 'Только что';
      if (difference.inHours < 1) return '${difference.inMinutes} мин назад';
      if (difference.inDays < 1) return '${difference.inHours} ч назад';
      if (difference.inDays < 7) return '${difference.inDays} д назад';
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (_) {
      return '';
    }
  }
}