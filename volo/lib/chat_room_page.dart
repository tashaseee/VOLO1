import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'blocs/chat/chat_bloc.dart';

class ChatRoomPage extends StatelessWidget {
  final int chatId;
  final String chatName;
  final String? avatarUrl;

  const ChatRoomPage({
    super.key,
    required this.chatId,
    required this.chatName,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatRoomBloc(apiService: ApiService())..add(LoadMessages(chatId)),
      child: _ChatRoomView(chatId: chatId, chatName: chatName, avatarUrl: avatarUrl),
    );
  }
}

class _ChatRoomView extends StatefulWidget {
  final int chatId;
  final String chatName;
  final String? avatarUrl;
  const _ChatRoomView({required this.chatId, required this.chatName, this.avatarUrl});
  @override
  State<_ChatRoomView> createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends State<_ChatRoomView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollingTimer;
  int? _myUserId;

  @override
  void initState() {
    super.initState();
    _loadMyId();
    // Запускаем опрос сервера каждые 3 секунды для имитации реального времени
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        context.read<ChatRoomBloc>().add(LoadMessages(widget.chatId));
      }
    });
  }

  Future<void> _loadMyId() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      final result = await ApiService().getUserProfile();
      if (result['success'] == true && mounted) {
        setState(() => _myUserId = result['data']['id']);
      }
    }
  }

  void _scrollToBottom() {
    // Скроллим только если пользователь и так внизу или отправил сообщение
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatRoomBloc, ChatRoomState>(
      listener: (ctx, state) {
        // Мы могли бы добавить авто-скролл здесь, но при поллинге это может мешать чтению истории
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FA),
          appBar: _buildAppBar(),
          body: Column(children: [
            Expanded(
              child: state.isLoading && state.messages.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF983296)))
                  : state.messages.isEmpty
                      ? _buildEmpty()
                      : _buildMessageList(state.messages),
            ),
            _buildInput(context),
          ]),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      leadingWidth: 40,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0D0D26), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle, 
            gradient: const LinearGradient(colors: [Color(0xFF983296), Color(0xFFB856B8)]),
            image: widget.avatarUrl != null ? DecorationImage(image: NetworkImage(widget.avatarUrl!), fit: BoxFit.cover) : null,
            boxShadow: [BoxShadow(color: const Color(0xFF983296).withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: widget.avatarUrl == null ? const Icon(Icons.groups_rounded, color: Colors.white, size: 20) : null,
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.chatName, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0D0D26)), maxLines: 1, overflow: TextOverflow.ellipsis),
          Row(children: [
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('В сети', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
          ]),
        ])),
      ]),
    );
  }

  Widget _buildMessageList(List<Map<String, dynamic>> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: messages.length,
      itemBuilder: (ctx, i) {
        final msg = messages[i];
        final prevMsg = i > 0 ? messages[i - 1] : null;
        
        bool showDate = false;
        String dateStr = '';
        
        if (msg['created_at'] != null) {
          final dt = DateTime.tryParse(msg['created_at']);
          if (dt != null) {
            if (prevMsg == null) {
              showDate = true;
            } else {
              final prevDt = DateTime.tryParse(prevMsg['created_at']);
              if (prevDt != null && (dt.day != prevDt.day || dt.month != prevDt.month)) {
                showDate = true;
              }
            }
            
            final now = DateTime.now();
            if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
              dateStr = 'Сегодня';
            } else if (dt.day == now.day - 1 && dt.month == now.month && dt.year == now.year) {
              dateStr = 'Вчера';
            } else {
              dateStr = '${dt.day}.${dt.month}.${dt.year}';
            }
          }
        }

        return Column(children: [
          if (showDate) _buildDateSeparator(dateStr),
          _buildBubble(msg),
        ]);
      },
    );
  }

  Widget _buildDateSeparator(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(children: [
        const Expanded(child: Divider(color: Color(0xFFE0E0E0), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[400], letterSpacing: 0.5)),
        ),
        const Expanded(child: Divider(color: Color(0xFFE0E0E0), thickness: 1)),
      ]),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg) {
    final isMine = msg['is_mine'] == true || msg['sender_id'] == _myUserId;
    final senderName = msg['sender_name'] as String? ?? '';
    final text = msg['text'] as String? ?? '';
    final time = msg['created_at'] as String?;
    String timeStr = '';
    if (time != null) {
      final dt = DateTime.tryParse(time);
      if (dt != null) timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Colors.grey[300]!, Colors.grey[400]!]),
              ),
              child: Center(child: Text(senderName.isNotEmpty ? senderName[0].toUpperCase() : '?', 
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white))),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
              if (!isMine) Padding(padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Text(senderName, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF983296).withOpacity(0.8)))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                decoration: BoxDecoration(
                  gradient: isMine 
                    ? const LinearGradient(colors: [Color(0xFF983296), Color(0xFFB856B8)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                    : null,
                  color: isMine ? null : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20), topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isMine ? 20 : 4),
                    bottomRight: Radius.circular(isMine ? 4 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isMine ? const Color(0xFF983296).withOpacity(0.2) : Colors.black.withOpacity(0.04),
                      blurRadius: 10, offset: const Offset(0, 4)
                    )
                  ],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(text, style: GoogleFonts.poppins(fontSize: 14, color: isMine ? Colors.white : const Color(0xFF0D0D26), height: 1.5)),
                  const SizedBox(height: 4),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(timeStr, style: GoogleFonts.poppins(fontSize: 10, color: isMine ? Colors.white70 : Colors.grey[400], fontWeight: FontWeight.w500)),
                    if (isMine) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.done_all_rounded, size: 14, color: Colors.white70),
                    ],
                  ]),
                ]),
              ),
            ]),
          ),
          if (isMine) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 25, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6F8), 
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: TextField(
                controller: _controller,
                cursorColor: const Color(0xFF983296),
                maxLines: 4, minLines: 1,
                textInputAction: TextInputAction.newline,
                style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF0D0D26)),
                decoration: InputDecoration(
                  hintText: 'Написать команде...',
                  hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _send(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50, height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF983296), Color(0xFFC152B8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFF983296).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: const Color(0xFF983296).withOpacity(0.05), shape: BoxShape.circle),
        child: const Icon(Icons.chat_bubble_outline_rounded, size: 40, color: Color(0xFF983296)),
      ),
      const SizedBox(height: 16),
      Text('Здесь пока нет сообщений', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF0D0D26))),
      const SizedBox(height: 4),
      Text('Будьте первым, кто напишет команде!', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500])),
    ]),
  );

  void _send(BuildContext context) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<ChatRoomBloc>().add(SendMessage(widget.chatId, text));
    _controller.clear();
    _scrollToBottom();
  }
}
