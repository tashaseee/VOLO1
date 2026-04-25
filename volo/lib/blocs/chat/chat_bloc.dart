// lib/blocs/chat/chat_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';

// ─── Events ──────────────────────────────────────────────────────────────────
abstract class ChatListEvent {}
class LoadChats extends ChatListEvent {}

abstract class ChatRoomEvent {}
class LoadMessages extends ChatRoomEvent { final int chatId; LoadMessages(this.chatId); }
class SendMessage extends ChatRoomEvent { final int chatId; final String text; SendMessage(this.chatId, this.text); }

// ─── States ───────────────────────────────────────────────────────────────────
class ChatListState {
  final List<Map<String, dynamic>> chats;
  final bool isLoading;
  const ChatListState({this.chats = const [], this.isLoading = true});
  ChatListState copyWith({List<Map<String, dynamic>>? chats, bool? isLoading}) =>
      ChatListState(chats: chats ?? this.chats, isLoading: isLoading ?? this.isLoading);
}

class ChatRoomState {
  final List<Map<String, dynamic>> messages;
  final bool isLoading;
  final bool isSending;
  const ChatRoomState({this.messages = const [], this.isLoading = true, this.isSending = false});
  ChatRoomState copyWith({List<Map<String, dynamic>>? messages, bool? isLoading, bool? isSending}) =>
      ChatRoomState(messages: messages ?? this.messages, isLoading: isLoading ?? this.isLoading, isSending: isSending ?? this.isSending);
}

// ─── BLoCs ───────────────────────────────────────────────────────────────────
class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  final ApiService apiService;
  ChatListBloc({required this.apiService}) : super(const ChatListState()) {
    on<LoadChats>(_onLoad);
  }

  Future<void> _onLoad(LoadChats event, Emitter<ChatListState> emit) async {
    emit(state.copyWith(isLoading: true));
    final result = await apiService.getMyChats();
    if (result['success'] == true) {
      final data = result['data'] as List<dynamic>;
      emit(state.copyWith(isLoading: false, chats: data.cast<Map<String, dynamic>>()));
    } else {
      emit(state.copyWith(isLoading: false));
    }
  }
}

class ChatRoomBloc extends Bloc<ChatRoomEvent, ChatRoomState> {
  final ApiService apiService;
  ChatRoomBloc({required this.apiService}) : super(const ChatRoomState()) {
    on<LoadMessages>(_onLoad);
    on<SendMessage>(_onSend);
  }

  Future<void> _onLoad(LoadMessages event, Emitter<ChatRoomState> emit) async {
    emit(state.copyWith(isLoading: true));
    final result = await apiService.getChatMessages(event.chatId);
    if (result['success'] == true) {
      final data = result['data'] as List<dynamic>;
      emit(state.copyWith(isLoading: false, messages: data.cast<Map<String, dynamic>>()));
    } else {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onSend(SendMessage event, Emitter<ChatRoomState> emit) async {
    if (event.text.trim().isEmpty) return;
    emit(state.copyWith(isSending: true));
    final result = await apiService.sendChatMessage(event.chatId, event.text);
    if (result['success'] == true) {
      final newMsg = Map<String, dynamic>.from(result['data'] as Map);
      emit(state.copyWith(isSending: false, messages: [...state.messages, newMsg]));
    } else {
      emit(state.copyWith(isSending: false));
    }
  }
}
