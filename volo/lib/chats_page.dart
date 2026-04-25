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
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatListBloc(apiService: ApiService())..add(LoadChats()),
      child: const _ChatsView(),
    );
  }
}

class _ChatsView extends StatelessWidget {
  const _ChatsView();

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
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text('Чаты', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF0D0D26))),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF983296)),
                onPressed: () => context.read<ChatListBloc>().add(LoadChats()),
              ),
            ],
          ),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF983296)))
              : state.chats.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      color: const Color(0xFF983296),
                      onRefresh: () async => context.read<ChatListBloc>().add(LoadChats()),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: state.chats.length,
                        itemBuilder: (context, i) => _ChatTile(chat: state.chats[i]),
                      ),
                    ),
          bottomNavigationBar: CustomBottomNavBar(
            currentIndex: 3,
            onTap: (i) => _onItemTapped(context, i),
          ),
        );
      },
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(28), decoration: BoxDecoration(color: const Color(0xFF983296).withOpacity(0.06), shape: BoxShape.circle),
        child: const Icon(Icons.chat_bubble_outline_rounded, size: 56, color: Color(0xFF983296))),
      const SizedBox(height: 20),
      Text('Чаты пока пусты', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF0D0D26))),
      const SizedBox(height: 8),
      Text('Когда вас примут на мероприятие,\nвас добавят в чат команды', textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500])),
    ]),
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
    String timeStr = '';
    if (time != null) {
      final dt = DateTime.tryParse(time);
      if (dt != null) {
        final now = DateTime.now();
        if (now.difference(dt).inDays == 0) {
          timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        } else {
          timeStr = '${dt.day}.${dt.month}';
        }
      }
    }

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ChatRoomPage(chatId: chat['id'] as int, chatName: chat['name'] as String, avatarUrl: avatarUrl))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          // Аватар
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: avatarUrl == null ? const LinearGradient(colors: [Color(0xFF983296), Color(0xFFB856B8)]) : null,
              color: avatarUrl != null ? Colors.grey[200] : null,
              image: avatarUrl != null ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover) : null,
              boxShadow: [
                BoxShadow(
                  color: (avatarUrl == null ? const Color(0xFF983296) : Colors.black).withOpacity(0.12),
                  blurRadius: 10, offset: const Offset(0, 4)
                )
              ],
            ),
            child: avatarUrl == null ? const Icon(Icons.groups_rounded, color: Colors.white, size: 28) : null,
          ),
          const SizedBox(width: 14),
          // Информация
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(chat['name'] ?? '', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF0D0D26)), maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (timeStr.isNotEmpty) Text(timeStr, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400])),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(child: Text(lastMsg ?? 'Нет сообщений', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500], fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.normal), maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (unread > 0)
                Container(width: 20, height: 20, decoration: const BoxDecoration(color: Color(0xFF983296), shape: BoxShape.circle),
                  child: Center(child: Text('$unread', style: GoogleFonts.poppins(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)))),
            ]),
          ])),
        ]),
      ),
    );
  }
}
