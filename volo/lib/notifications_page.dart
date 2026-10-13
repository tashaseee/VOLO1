import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:volo/home_page.dart';
import 'package:volo/search_page.dart';
import 'package:volo/my_applications_page.dart';
import 'package:volo/profile_page.dart';
import 'package:volo/chats_page.dart';
import 'bottom_nav_bar.dart';
import 'services/api_service.dart';
import 'blocs/notifications/notifications_bloc.dart';
import 'widgets/approval_notification_overlay.dart';

class NotificationsPage extends StatelessWidget {
  final bool? showNavBar;
  final bool showBackButton;
  const NotificationsPage({super.key, this.showNavBar, this.showBackButton = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationsBloc(apiService: ApiService())..add(LoadNotifications()),
      child: _NotificationsView(
        showNavBar: showNavBar ?? true,
        showBackButton: showBackButton,
      ),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  final bool showNavBar;
  final bool showBackButton;
  const _NotificationsView({required this.showNavBar, this.showBackButton = false});

  void _onItemTapped(BuildContext context, int index) {
    if (index == 0) return;
    switch (index) {
      case 1: Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const SearchPage(), transitionDuration: Duration.zero)); break;
      case 2: Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const HomePage(), transitionDuration: Duration.zero)); break;
      case 3: Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => ChatsPage(), transitionDuration: Duration.zero)); break;
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
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Левая часть
          if (showBackButton)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0D0D26), size: 16),
              ),
            )
          else
            const SizedBox(width: 32),

          // Центр
          Row(
            children: [
              Text(
                'Уведомления',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0D0D26),
                ),
              ),
              if (state.unreadCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF983296), borderRadius: BorderRadius.circular(10)),
                  child: Text('${state.unreadCount}', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),

          // Правая часть
          if (state.unreadCount > 0)
            GestureDetector(
              onTap: () => context.read<NotificationsBloc>().add(MarkAllRead()),
              child: const Icon(Icons.checklist_rtl_rounded, color: Color(0xFF983296), size: 24),
            )
          else
            const SizedBox(width: 32),
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
      child: Material(
        color: isRead ? Colors.transparent : const Color(0xFF983296).withValues(alpha: 0.03),
        child: InkWell(
          highlightColor: Colors.black.withValues(alpha: 0.02),
          splashColor: Colors.black.withValues(alpha: 0.05),
          onTap: () {
            if (!isRead) context.read<NotificationsBloc>().add(MarkAsRead(notification['id']));
            if (type == 'approved' && notification['related_id'] != null) {
              String eventTitle = 'Мероприятие';
              final msg = notification['message'] as String? ?? '';
              final regExp = RegExp(r'[«“"](.*?)[»”"]');
              final match = regExp.firstMatch(msg);
              if (match != null && match.groupCount >= 1) {
                eventTitle = match.group(1) ?? 'Мероприятие';
              }
              ApprovalNotificationOverlay.show(
                context,
                chatId: notification['related_id'] as int,
                eventTitle: eventTitle,
              );
            } else if (showNavBar) {
              Navigator.pushReplacement(context, PageRouteBuilder(
                pageBuilder: (_, __, ___) => const MyApplicationsPage(),
                transitionDuration: Duration.zero,
              ));
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Center(child: Icon(typeIcon, color: typeColor, size: 24)),
                ),
                const SizedBox(width: 16),
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
                              style: GoogleFonts.poppins(fontSize: 15, fontWeight: isRead ? FontWeight.w600 : FontWeight.w700, color: const Color(0xFF0D0D26), height: 1.2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(_formatDate(notification['created_at']), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF95969D))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(notification['message'] ?? '', style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF6B7280), height: 1.4, fontWeight: FontWeight.w400)),
                    ],
                  ),
                ),
                if (!isRead)
                  Container(
                    margin: const EdgeInsets.only(left: 12, top: 4),
                    width: 10, height: 10,
                    decoration: const BoxDecoration(color: Color(0xFF983296), shape: BoxShape.circle),
                  ),
              ],
            ),
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