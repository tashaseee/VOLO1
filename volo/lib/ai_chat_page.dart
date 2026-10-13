import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:volo/services/api_service.dart';
import 'package:volo/event_detail_page.dart';
import 'blocs/ai_chat/ai_chat_bloc.dart';

class AiChatPage extends StatelessWidget {
  const AiChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AiChatBloc(),
      child: const _AiChatView(),
    );
  }
}

class _AiChatView extends StatefulWidget {
  const _AiChatView();
  @override
  State<_AiChatView> createState() => _AiChatViewState();
}

class _AiChatViewState extends State<_AiChatView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AiChatBloc, AiChatState>(
      listener: (context, state) => _scrollToBottom(),
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: AppBar(
            backgroundColor: Colors.white, elevation: 0, centerTitle: true,
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0D0D26), size: 20), onPressed: () => Navigator.pop(context)),
            title: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF983296), Color(0xFFC152B8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: const Color(0xFF983296).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 10),
              Text('VOLO Assistant', style: GoogleFonts.poppins(color: const Color(0xFF0D0D26), fontSize: 16, fontWeight: FontWeight.w600)),
            ]),
          ),
          body: Column(children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                itemCount: state.messages.length + (state.isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == state.messages.length && state.isTyping) return _buildTypingIndicator();
                  return _buildBubble(context, state.messages[index]);
                },
              ),
            ),
            _buildInputArea(context),
          ]),
        );
      },
    );
  }

  Widget _buildBubble(BuildContext context, ChatMessage message) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.end, children: [
        if (!isUser) ...[
          Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
            child: const Center(child: Icon(Icons.auto_awesome, color: Color(0xFF983296), size: 18))),
          const SizedBox(width: 12),
        ],
        Flexible(child: Column(crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isUser ? null : Colors.white,
              gradient: isUser ? const LinearGradient(colors: [Color(0xFF983296), Color(0xFFB856B8)], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
              boxShadow: isUser
                  ? [BoxShadow(color: const Color(0xFF983296).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))]
                  : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 14, offset: const Offset(0, 4))],
              borderRadius: BorderRadius.only(topLeft: const Radius.circular(24), topRight: const Radius.circular(24), bottomLeft: Radius.circular(isUser ? 24 : 6), bottomRight: Radius.circular(isUser ? 6 : 24)),
            ),
            child: Text(message.text, style: GoogleFonts.poppins(color: isUser ? Colors.white : const Color(0xFF1E1E2D), fontSize: 14, fontWeight: FontWeight.w500, height: 1.5)),
          ),
          if (!isUser && message.events != null && message.events!.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 12),
              child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: message.events!.map((e) => _buildEventCard(context, e)).toList()))),
        ])),
        if (isUser) const SizedBox(width: 48),
      ]),
    );
  }

  Widget _buildEventCard(BuildContext context, dynamic event) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailPage(
        eventTitle: event['title'] ?? '', organizer: event['organizer'] ?? 'Организатор', date: event['date_text'] ?? 'Скоро',
        location: event['location'] ?? 'Локация', chatLink: event['chat_link'] ?? '', description: event['description'] ?? '',
        responsibilities: (event['responsibilities'] as String? ?? 'Участие в мероприятии').split('\n'),
        benefits: (event['benefits'] as String? ?? 'Volo-часы').split('\n'),
        eventId: event['id'], imageUrl: event['image_url'],
        minAge: event['min_age'] ?? 0,
        chatId: event['chat_id'],
      ))),
      child: Container(
        width: 200, margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: const Color(0xFFF0F0F0))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 90, decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), color: Colors.grey[200],
            image: event['image_url'] != null && event['image_url'].toString().isNotEmpty
                ? DecorationImage(image: NetworkImage(event['image_url'].toString().startsWith('http') ? event['image_url'] : '${ApiService.baseUrl}${event['image_url']}'), fit: BoxFit.cover)
                : const DecorationImage(image: AssetImage('assets/images/photo.png'), fit: BoxFit.cover))),
          Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(event['title'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0D0D26), height: 1.2)),
            const SizedBox(height: 6),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF983296).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(event['date_text'] ?? '', style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF983296), fontWeight: FontWeight.w600))),
          ])),
        ]),
      ),
    );
  }

  Widget _buildTypingIndicator() => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
        child: const Center(child: Icon(Icons.auto_awesome, color: Color(0xFF983296), size: 18))),
      const SizedBox(width: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 14, offset: const Offset(0, 4))],
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24), bottomLeft: Radius.circular(6), bottomRight: Radius.circular(24))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [_buildDot(0), const SizedBox(width: 6), _buildDot(1), const SizedBox(width: 6), _buildDot(2)]),
      ),
    ]),
  );

  Widget _buildDot(int index) => TweenAnimationBuilder(
    tween: Tween<double>(begin: 0, end: 1),
    duration: const Duration(milliseconds: 600),
    curve: Interval(index * 0.2, 1.0, curve: Curves.easeInOut),
    builder: (context, double value, child) => Opacity(opacity: 0.3 + (value * 0.7),
      child: Transform.translate(offset: Offset(0, -4 * value),
        child: Container(width: 8, height: 8, decoration: BoxDecoration(color: const Color(0xFF983296).withValues(alpha: 0.5), shape: BoxShape.circle)))),
    onEnd: () {},
  );

  Widget _buildInputArea(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, -4))]),
    child: SafeArea(child: Row(children: [
      Expanded(child: Container(decoration: BoxDecoration(color: const Color(0xFFF5F6F8), borderRadius: BorderRadius.circular(28)),
        child: TextField(
          controller: _controller, cursorColor: const Color(0xFF983296),
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(hintText: 'Задайте вопрос ИИ...', hintStyle: GoogleFonts.poppins(color: const Color(0xFFA0A0AB), fontSize: 14, fontWeight: FontWeight.w400),
            border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
          onSubmitted: (_) {
            if (_controller.text.trim().isNotEmpty) {
              context.read<AiChatBloc>().add(SendMessage(_controller.text));
              _controller.clear();
            }
          },
        ))),
      const SizedBox(width: 12),
      GestureDetector(
        onTap: () {
          if (_controller.text.trim().isNotEmpty) {
            context.read<AiChatBloc>().add(SendMessage(_controller.text));
            _controller.clear();
          }
        },
        child: Container(width: 52, height: 52,
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF983296), Color(0xFFC152B8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF983296).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))]),
          child: const Center(child: Icon(Icons.send_rounded, color: Colors.white, size: 22))),
      ),
    ])),
  );
}
