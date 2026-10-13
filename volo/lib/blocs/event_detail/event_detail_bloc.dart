import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

// --- EVENTS ---
abstract class EventDetailEvent {}

class LoadEventDetails extends EventDetailEvent {
  final int eventId;
  LoadEventDetails(this.eventId);
}

class SetAppliedStatus extends EventDetailEvent {}

// --- STATE ---
class EventDetailState {
  final bool isLoading;
  final String userRole;
  final bool isMyEvent;
  final bool isApplied;
  final String applicationStatus;
  final int userAge;
  final int? chatId;

  EventDetailState({
    this.isLoading = true,
    this.userRole = 'volunteer',
    this.isMyEvent = false,
    this.isApplied = false,
    this.applicationStatus = 'pending',
    this.userAge = 0,
    this.chatId,
  });

  EventDetailState copyWith({
    bool? isLoading,
    String? userRole,
    bool? isMyEvent,
    bool? isApplied,
    String? applicationStatus,
    int? userAge,
    int? chatId,
  }) {
    return EventDetailState(
      isLoading: isLoading ?? this.isLoading,
      userRole: userRole ?? this.userRole,
      isMyEvent: isMyEvent ?? this.isMyEvent,
      isApplied: isApplied ?? this.isApplied,
      applicationStatus: applicationStatus ?? this.applicationStatus,
      userAge: userAge ?? this.userAge,
      chatId: chatId ?? this.chatId,
    );
  }
}

// --- BLOC ---
class EventDetailBloc extends Bloc<EventDetailEvent, EventDetailState> {
  final ApiService apiService;

  EventDetailBloc({required this.apiService}) : super(EventDetailState()) {
    on<LoadEventDetails>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('role') ?? 'volunteer';
      
      bool isMyEvent = false;
      bool isApplied = false;
      String applicationStatus = 'pending';
      int userAge = 0;
      int? chatId;

      if (role == 'organizer') {
        final myEventsResult = await apiService.getMyEvents();
        if (myEventsResult['success']) {
          final myEvents = myEventsResult['data'] as List;
          final myEvent = myEvents.firstWhere(
            (e) => e['id'] == event.eventId,
            orElse: () => null
          );
          if (myEvent != null) {
            isMyEvent = true;
            chatId = myEvent['chat_id'] as int?;
          }
        }
      } else {
        // Fetch user profile to get age
        final profileResult = await apiService.getUserProfile();
        if (profileResult['success']) {
          final profileData = profileResult['data']['profile'];
          if (profileData != null && profileData['birth_date'] != null) {
            try {
              final birthDate = DateTime.parse(profileData['birth_date']);
              final today = DateTime.now();
              int age = today.year - birthDate.year;
              if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
                age--;
              }
              userAge = age;
            } catch (_) {}
          }
        }

        final result = await apiService.getMyApplications();
        if (result['success']) {
          final myApps = result['data'] as List;
          final myApp = myApps.firstWhere(
            (a) => (a['event'] != null && a['event']['id'] == event.eventId) || (a['event_id'] == event.eventId),
            orElse: () => null
          );
          
          if (myApp != null) {
            isApplied = true;
            applicationStatus = myApp['status']?.toString() ?? 'pending';
            if (myApp['event'] != null) {
              chatId = myApp['event']['chat_id'] as int?;
            }
          } else {
            isApplied = false;
            applicationStatus = 'pending';
          }
        }
      }
      
      emit(state.copyWith(
        isLoading: false,
        userRole: role,
        isMyEvent: isMyEvent,
        isApplied: isApplied,
        applicationStatus: applicationStatus,
        userAge: userAge,
        chatId: chatId,
      ));
    });

    on<SetAppliedStatus>((event, emit) {
      emit(state.copyWith(isApplied: true));
    });
  }
}
