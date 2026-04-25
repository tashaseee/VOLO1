import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final List<dynamic>? events;
  const ChatMessage({required this.text, required this.isUser, this.events});
}

// Events
abstract class AiChatEvent {}
class SendMessage extends AiChatEvent {
  final String text;
  SendMessage(this.text);
}

// State
class AiChatState {
  final List<ChatMessage> messages;
  final bool isTyping;

  const AiChatState({
    this.messages = const [],
    this.isTyping = false,
  });

  AiChatState copyWith({List<ChatMessage>? messages, bool? isTyping}) {
    return AiChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

// Bloc
class AiChatBloc extends Bloc<AiChatEvent, AiChatState> {
  AiChatBloc() : super(AiChatState(messages: [
    const ChatMessage(text: "Привет! Я твой ИИ-помощник ✨\nРасскажи, чем увлекаешься, и я подберу для тебя топ-ивенты на этой неделе!", isUser: false),
  ])) {
    on<SendMessage>(_onSend);
  }

  Future<void> _onSend(SendMessage event, Emitter<AiChatState> emit) async {
    final userMsg = ChatMessage(text: event.text, isUser: true);
    final withUser = [...state.messages, userMsg];
    emit(state.copyWith(messages: withUser, isTyping: true));

    final history = withUser.map((m) => {"role": m.isUser ? "user" : "assistant", "content": m.text}).toList();

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/ai/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': event.text, 'history': history}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        emit(state.copyWith(
          isTyping: false,
          messages: [...withUser, ChatMessage(text: data['reply'] ?? "Ошибка получения ответа", isUser: false, events: data['events'])],
        ));
      } else {
        emit(state.copyWith(
          isTyping: false,
          messages: [...withUser, ChatMessage(text: "Ошибка сервера (Код: ${response.statusCode})", isUser: false)],
        ));
      }
    } catch (_) {
      emit(state.copyWith(
        isTyping: false,
        messages: [...withUser, const ChatMessage(text: "Ошибка подключения к сети. Проверьте интернет.", isUser: false)],
      ));
    }
  }
}
