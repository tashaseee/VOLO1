import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';

// Events
abstract class NotificationsEvent {}

class LoadNotifications extends NotificationsEvent {}

class MarkAsRead extends NotificationsEvent {
  final int id;
  MarkAsRead(this.id);
}

class MarkAllRead extends NotificationsEvent {}

class DeleteNotification extends NotificationsEvent {
  final int id;
  DeleteNotification(this.id);
}

// State
class NotificationsState {
  final List<dynamic> notifications;
  final bool isLoading;
  final int unreadCount;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = true,
    this.unreadCount = 0,
  });

  NotificationsState copyWith({
    List<dynamic>? notifications,
    bool? isLoading,
    int? unreadCount,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

// Bloc
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final ApiService apiService;

  NotificationsBloc({required this.apiService}) : super(const NotificationsState()) {
    on<LoadNotifications>(_onLoad);
    on<MarkAsRead>(_onMarkAsRead);
    on<MarkAllRead>(_onMarkAll);
    on<DeleteNotification>(_onDelete);
  }

  Future<void> _onLoad(LoadNotifications event, Emitter<NotificationsState> emit) async {
    emit(state.copyWith(isLoading: true));
    final notifResult = await apiService.getNotifications();
    final countResult = await apiService.getUnreadCount();

    emit(state.copyWith(
      isLoading: false,
      notifications: notifResult['success'] == true ? notifResult['data'] : [],
      unreadCount: countResult['success'] == true ? (countResult['data']['count'] ?? 0) : 0,
    ));
  }

  Future<void> _onMarkAsRead(MarkAsRead event, Emitter<NotificationsState> emit) async {
    await apiService.markNotificationAsRead(event.id);
    add(LoadNotifications());
  }

  Future<void> _onMarkAll(MarkAllRead event, Emitter<NotificationsState> emit) async {
    await apiService.markAllNotificationsAsRead();
    add(LoadNotifications());
  }

  Future<void> _onDelete(DeleteNotification event, Emitter<NotificationsState> emit) async {
    await apiService.deleteNotification(event.id);
    add(LoadNotifications());
  }
}
