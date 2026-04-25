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

  EventDetailState({
    this.isLoading = true,
    this.userRole = 'volunteer',
    this.isMyEvent = false,
    this.isApplied = false,
    this.applicationStatus = 'pending',
  });

  EventDetailState copyWith({
    bool? isLoading,
    String? userRole,
    bool? isMyEvent,
    bool? isApplied,
    String? applicationStatus,
  }) {
    return EventDetailState(
      isLoading: isLoading ?? this.isLoading,
      userRole: userRole ?? this.userRole,
      isMyEvent: isMyEvent ?? this.isMyEvent,
      isApplied: isApplied ?? this.isApplied,
      applicationStatus: applicationStatus ?? this.applicationStatus,
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

      if (role == 'organizer') {
        final myEventsResult = await apiService.getMyEvents();
        if (myEventsResult['success']) {
          final myEvents = myEventsResult['data'] as List;
          if (myEvents.any((e) => e['id'] == event.eventId)) {
            isMyEvent = true;
          }
        }
      } else {
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
      ));
    });

    on<SetAppliedStatus>((event, emit) {
      emit(state.copyWith(isApplied: true));
    });
  }
}
