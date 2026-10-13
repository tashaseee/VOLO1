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
  final bool isOrganizer;

  const ChatRoomPage({
    super.key,
    required this.chatId,
    required this.chatName,
    this.isOrganizer = false,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatRoomBloc(apiService: ApiService())..add(LoadMessages(chatId)),
      child: _ChatRoomView(chatId: chatId, chatName: chatName, avatarUrl: avatarUrl, isOrganizer: isOrganizer),
    );
  }
}

class _ChatRoomView extends StatefulWidget {
  final int chatId;
  final String chatName;
  final String? avatarUrl;
  final bool isOrganizer;
  const _ChatRoomView({required this.chatId, required this.chatName, this.avatarUrl, this.isOrganizer = false});
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
      listener: (ctx, state) {},
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF4F5F7), // Soft background for chat
          appBar: _buildAppBar(),
          body: Column(
            children: [
              Expanded(
                child: state.isLoading && state.messages.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF983296), strokeWidth: 3))
                    : state.messages.isEmpty
                        ? _buildEmpty()
                        : _buildMessageList(state.messages),
              ),
              _buildInput(context),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      leadingWidth: 44,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      scrolledUnderElevation: 4,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0D0D26), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.avatarUrl == null ? const Color(0xFF983296).withValues(alpha: 0.08) : Colors.grey[100],
                  image: widget.avatarUrl != null ? DecorationImage(image: NetworkImage(widget.avatarUrl!), fit: BoxFit.cover) : null,
                ),
                child: widget.avatarUrl == null ? const Icon(Icons.groups_rounded, color: Color(0xFF983296), size: 20) : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BFA5),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chatName,
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0D0D26), letterSpacing: -0.3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Активность: Только что',
                  style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF00BFA5), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F8),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF0D0D26), size: 20),
            onPressed: () => _showParticipants(context),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageList(List<Map<String, dynamic>> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      itemCount: messages.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (ctx, i) {
        final msg = messages[i];
        final prevMsg = i > 0 ? messages[i - 1] : null;
        final nextMsg = i < messages.length - 1 ? messages[i + 1] : null;
        
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

        final bool isFirstInGroup = prevMsg == null || prevMsg['sender_id'] != msg['sender_id'];
        final bool isLastInGroup = nextMsg == null || nextMsg['sender_id'] != msg['sender_id'];

        return Column(
          children: [
            if (showDate) _buildDateSeparator(dateStr),
            _buildBubble(msg, isFirstInGroup, isLastInGroup),
          ],
        );
      },
    );
  }

  Widget _buildDateSeparator(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF95969D)),
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg, bool isFirst, bool isLast) {
    final isMine = msg['is_mine'] == true || msg['sender_id'] == _myUserId;
    final senderName = msg['sender_name'] as String? ?? '';
    final text = msg['text'] as String? ?? '';
    final time = msg['created_at'] as String?;
    final isOrg = msg['sender_role'] == 'organizer';
    
    String timeStr = '';
    if (time != null) {
      final dt = DateTime.tryParse(time);
      if (dt != null) timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 16 : 4),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            if (isLast)
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isOrg ? const LinearGradient(colors: [Color(0xFF983296), Color(0xFF6B21A8)]) : null,
                  color: isOrg ? null : const Color(0xFFE5E7EB),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Center(
                  child: Text(
                    senderName.isNotEmpty ? senderName[0].toUpperCase() : '?', 
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: isOrg ? Colors.white : const Color(0xFF4B5563)),
                  ),
                ),
              )
            else
              const SizedBox(width: 34),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMine && isFirst)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 4),
                    child: Text(
                      senderName,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isOrg ? const Color(0xFF983296) : const Color(0xFF95969D),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                GestureDetector(
                  onLongPress: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                    decoration: BoxDecoration(
                      gradient: isMine
                          ? const LinearGradient(
                              colors: [Color(0xFF983296), Color(0xFFB856B8)],
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                            )
                          : null,
                      color: isMine ? null : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMine ? 18 : (isFirst ? 18 : (isLast ? 4 : 18))),
                        bottomRight: Radius.circular(isMine ? (isFirst ? 18 : (isLast ? 4 : 18)) : 18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMine && isOrg && isFirst)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF983296).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ОРГАНИЗАТОР',
                              style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w800, color: const Color(0xFF983296), letterSpacing: 0.5),
                            ),
                          ),
                        Text(
                          text,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: isMine ? Colors.white : const Color(0xFF0D0D26),
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              timeStr,
                              style: GoogleFonts.poppins(fontSize: 10, color: isMine ? Colors.white.withValues(alpha: 0.7) : const Color(0xFFA0A0AB), fontWeight: FontWeight.w500),
                            ),
                            if (isMine) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.done_all_rounded, size: 14, color: Colors.white),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isOrganizer) _buildQuickTemplates(),
        Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, -5)),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.add_rounded, color: Color(0xFF8E8E93), size: 24),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _controller,
                      cursorColor: const Color(0xFF983296),
                      maxLines: 5,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(context),
                      style: GoogleFonts.poppins(fontSize: 15, color: const Color(0xFF0D0D26), fontWeight: FontWeight.w400),
                      decoration: InputDecoration(
                        hintText: 'Сообщение',
                        hintStyle: GoogleFonts.poppins(fontSize: 15, color: const Color(0xFF8E8E93), fontWeight: FontWeight.w400),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _send(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFF983296),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickTemplates() {
    final templates = [
      'Привет всем! 👋',
      'Напоминаю о завтрашнем сборе.',
      'Где вы сейчас?',
      'Спасибо за работу! ❤️',
      'Нужна помощь?',
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.only(bottom: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: templates.length,
        itemBuilder: (context, i) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              backgroundColor: Colors.white,
              elevation: 0,
              side: BorderSide(color: const Color(0xFFF1F0F5), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              label: Text(
                templates[i],
                style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF983296), fontWeight: FontWeight.w700),
              ),
              onPressed: () {
                _controller.text = templates[i];
                _send(context);
              },
            ),
          );
        },
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
                width: 100,
                height: 100,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF983296).withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.forum_outlined, size: 48, color: Color(0xFF983296)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Начните общение',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0D0D26)),
              ),
              const SizedBox(height: 12),
              Text(
                'Здесь вы можете обсудить детали мероприятия с организаторами и другими волонтерами',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF95969D), height: 1.5),
              ),
            ],
          ),
        ),
      );

  void _send(BuildContext context) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<ChatRoomBloc>().add(SendMessage(widget.chatId, text));
    _controller.clear();
    _scrollToBottom();
  }

  void _showParticipants(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text('Участники', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0D0D26))),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFF983296).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                    child: Text('Члены чата', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF983296))),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder(
                  future: ApiService().getChatParticipants(widget.chatId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF983296), strokeWidth: 3));
                    if (!snapshot.hasData || snapshot.data!['success'] == false) return const Text('Ошибка загрузки участников');
                    
                    final participants = snapshot.data!['data'] as List<dynamic>;
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: participants.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, i) {
                        final p = participants[i];
                        final isOrg = p['role'] == 'organizer';
                        final avatar = p['avatar_url'];
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: isOrg ? const Color(0xFF983296) : const Color(0xFFF5F5F8),
                                backgroundImage: avatar != null ? NetworkImage('${ApiService.baseUrl}$avatar') : null,
                                child: avatar == null ? Icon(isOrg ? Icons.business_center_rounded : Icons.person_rounded, color: isOrg ? Colors.white : const Color(0xFF95969D), size: 18) : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(p['name'] ?? 'Без имени', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0D0D26))),
                                        if (isOrg) ...[
                                          const SizedBox(width: 6),
                                          const Icon(Icons.verified_rounded, color: Color(0xFF983296), size: 14),
                                        ],
                                      ],
                                    ),
                                    Text(isOrg ? 'Организатор' : 'Волонтер', style: GoogleFonts.poppins(fontSize: 11, color: isOrg ? const Color(0xFF983296) : const Color(0xFF95969D), fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF983296)),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
