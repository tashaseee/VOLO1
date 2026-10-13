import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'services/api_service.dart';
import 'blocs/chat/chat_bloc.dart';
import 'chat_room_page.dart';
import 'home_page.dart';
import 'search_page.dart';
import 'profile_page.dart';
import 'notifications_page.dart';
import 'bottom_nav_bar.dart';

class ChatsPage extends StatelessWidget {
  final bool showNavBar;
  const ChatsPage({super.key, this.showNavBar = true});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatListBloc(apiService: ApiService())..add(LoadChats()),
      child: _ChatsView(showNavBar: showNavBar),
    );
  }
}

class _ChatsView extends StatelessWidget {
  final bool showNavBar;
  const _ChatsView({required this.showNavBar});

  void _onItemTapped(BuildContext context, int index) {
    if (index == 3) return; // Мы уже здесь
    switch (index) {
      case 0: Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const NotificationsPage(), transitionDuration: Duration.zero)); break;
      case 1: Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const SearchPage(), transitionDuration: Duration.zero)); break;
      case 2: Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const HomePage(), transitionDuration: Duration.zero)); break;
      case 4: Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const ProfilePage(), transitionDuration: Duration.zero)); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatListBloc, ChatListState>(
      builder: (context, state) {
        final activeChats = state.chats.where((c) => c['is_archived'] != true).toList();
        final archivedChats = state.chats.where((c) => c['is_archived'] == true).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildSearch(),
                if (!state.isLoading && activeChats.isNotEmpty)
                  _buildActiveContacts(activeChats),
                _buildCategories(),
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF983296), strokeWidth: 3))
                      : state.chats.isEmpty
                          ? _buildEmpty()
                          : RefreshIndicator(
                              color: const Color(0xFF983296),
                              backgroundColor: Colors.white,
                              onRefresh: () async => context.read<ChatListBloc>().add(LoadChats()),
                              child: ListView(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                children: [
                                  ...activeChats.map((c) => _ChatTile(chat: c)),
                                  if (archivedChats.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(26, 24, 26, 12),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.archive_outlined, size: 16, color: Color(0xFF95969D)),
                                          const SizedBox(width: 8),
                                          Text(
                                            'АРХИВ',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF95969D),
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ...archivedChats.map((c) => Opacity(
                                      opacity: 0.7, 
                                      child: _ChatTile(chat: c),
                                    )),
                                  ]
                                ],
                              ),
                            ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: showNavBar 
              ? CustomBottomNavBar(
                  currentIndex: 3,
                  onTap: (i) => _onItemTapped(context, i),
                )
              : null,
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Center(
        child: Text(
          'Чаты',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0D0D26),
          ),
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6), // Мягкий серый цвет в стиле iOS
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: Color(0xFFA0A0AB), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF0D0D26), fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Поиск чатов...',
                  hintStyle: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFFA0A0AB), fontWeight: FontWeight.w400),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveContacts(List<dynamic> chats) {
    // Для "Активных контактов" берем первые несколько чатов и рисуем их в виде сторис
    return Container(
      height: 100,
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          final hasAvatar = chat['avatar_url'] != null && chat['avatar_url'].toString().isNotEmpty;
          final avatarUrl = hasAvatar
              ? (chat['avatar_url'].toString().startsWith('http') ? chat['avatar_url'] : '${ApiService.baseUrl}${chat['avatar_url']}')
              : null;
          final unread = (chat['unread_count'] ?? 0) as int;
          
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatRoomPage(
                  chatId: chat['id'] as int, 
                  chatName: chat['name'] as String, 
                  avatarUrl: avatarUrl,
                  isOrganizer: chat['is_organizer'] == true,
                ),
              ),
            ),
            child: Container(
              width: 72,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: unread > 0 ? const Color(0xFF983296) : Colors.transparent, 
                            width: 2.5
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: avatarUrl == null ? const Color(0xFF983296).withValues(alpha: 0.08) : Colors.grey[100],
                            image: avatarUrl != null ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover) : null,
                          ),
                          child: avatarUrl == null 
                              ? const Icon(Icons.groups_rounded, color: Color(0xFF983296), size: 28) 
                              : null,
                        ),
                      ),
                      Positioned(
                        right: 4, bottom: 4,
                        child: Container(
                          width: 14, height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00BFA5),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    chat['name'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0D0D26),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategories() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 8, 26, 8),
      child: Text(
        'ВСЕ ЧАТЫ',
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF95969D),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28), 
            decoration: BoxDecoration(
              color: const Color(0xFF983296).withValues(alpha: 0.06), 
              shape: BoxShape.circle
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded, size: 56, color: Color(0xFF983296)),
          ),
          const SizedBox(height: 24),
          Text(
            'Нет активных чатов',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0D0D26)),
          ),
          const SizedBox(height: 8),
          Text(
            'Присоединяйтесь к мероприятиям,\nчтобы начать общение с командой',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF95969D), height: 1.5),
          ),
        ],
      ),
    ),
  );
}

class _ChatTile extends StatelessWidget {
  final Map<String, dynamic> chat;
  const _ChatTile({required this.chat});

  @override
  Widget build(BuildContext context) {
    final hasAvatar = chat['avatar_url'] != null && chat['avatar_url'].toString().isNotEmpty;
    final avatarUrl = hasAvatar
        ? (chat['avatar_url'].toString().startsWith('http') ? chat['avatar_url'] : '${ApiService.baseUrl}${chat['avatar_url']}')
        : null;
    final unread = (chat['unread_count'] ?? 0) as int;
    final lastMsg = chat['last_message'] as String?;
    final time = chat['last_message_time'] as String?;
    final isOrganizer = chat['is_organizer'] == true;
    
    String timeStr = '';
    if (time != null) {
      final dt = DateTime.tryParse(time);
      if (dt != null) {
        final now = DateTime.now();
        if (now.day == dt.day && now.month == dt.month && now.year == dt.year) {
          timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        } else if (now.difference(dt).inDays < 7) {
          timeStr = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'][dt.weekday - 1];
        } else {
          timeStr = '${dt.day}.${dt.month}';
        }
      }
    }

    return Container(
      color: unread > 0 ? const Color(0xFF983296).withValues(alpha: 0.03) : Colors.white,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          highlightColor: Colors.black.withValues(alpha: 0.02),
          splashColor: Colors.black.withValues(alpha: 0.05),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatRoomPage(
                chatId: chat['id'] as int, 
                chatName: chat['name'] as String, 
                avatarUrl: avatarUrl,
                isOrganizer: isOrganizer,
              ),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: avatarUrl == null ? const Color(0xFF983296).withValues(alpha: 0.08) : Colors.grey[100],
                        image: avatarUrl != null ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover) : null,
                        border: Border.all(color: const Color(0xFFF1F0F5), width: 1),
                      ),
                      child: avatarUrl == null 
                          ? const Icon(Icons.groups_rounded, color: Color(0xFF983296), size: 26) 
                          : null,
                    ),
                    if (isOrganizer)
                      Positioned(
                        right: 0, bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00BFA5),
                            shape: BoxShape.circle, 
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.verified_rounded, color: Colors.white, size: 10),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              chat['name'] ?? '', 
                              style: GoogleFonts.poppins(
                                fontSize: 16, 
                                fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w600, 
                                color: const Color(0xFF0D0D26),
                                letterSpacing: -0.3,
                              ), 
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (timeStr.isNotEmpty) 
                            Text(
                              timeStr, 
                              style: GoogleFonts.poppins(
                                fontSize: 11, 
                                color: unread > 0 ? const Color(0xFF983296) : const Color(0xFF95969D), 
                                fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMsg ?? 'Напишите команде...', 
                              style: GoogleFonts.poppins(
                                fontSize: 13, 
                                color: unread > 0 ? const Color(0xFF0D0D26) : const Color(0xFF95969D), 
                                fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400
                              ), 
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unread > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF983296), Color(0xFFD644D2)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF983296).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '$unread', 
                                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
              ),
              // Разделительная линия
              Container(
                margin: const EdgeInsets.only(left: 96), // Отступ под аватаркой
                height: 1,
                color: const Color(0xFFF3F4F6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
