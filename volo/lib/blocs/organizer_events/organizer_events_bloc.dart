import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';

// --- EVENTS ---
abstract class OrganizerEventsEvent {}

class LoadEvents extends OrganizerEventsEvent {}

class UpdateFilter extends OrganizerEventsEvent {
  final String filter;
  UpdateFilter(this.filter);
}

class UpdateSearchQuery extends OrganizerEventsEvent {
  final String query;
  UpdateSearchQuery(this.query);
}

class ToggleEventStatusEvent extends OrganizerEventsEvent {
  final int eventId;
  ToggleEventStatusEvent(this.eventId);
}

class FinishEventEvent extends OrganizerEventsEvent {
  final int eventId;
  FinishEventEvent(this.eventId);
}

// --- STATE ---
class OrganizerEventsState {
  final bool isLoading;
  final List<dynamic> events;
  final String filter; // 'all', 'active', 'inactive'
  final String searchQuery;
  final bool isSuccessAction;
  final String? successMessage;
  final String? errorMessage;

  OrganizerEventsState({
    this.isLoading = true,
    this.events = const [],
    this.filter = 'all',
    this.searchQuery = '',
    this.isSuccessAction = false,
    this.successMessage,
    this.errorMessage,
  });

  List<dynamic> get filteredEvents {
    List<dynamic> filtered = events;
    
    if (filter == 'active') {
      filtered = filtered.where((e) => e['is_active'] == true).toList();
    } else if (filter == 'inactive') {
      filtered = filtered.where((e) => e['is_active'] == false).toList();
    }

    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((e) => 
        (e['title'] ?? '').toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
        (e['location'] ?? '').toString().toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
    }
    
    return filtered;
  }

  OrganizerEventsState copyWith({
    bool? isLoading,
    List<dynamic>? events,
    String? filter,
    String? searchQuery,
    bool? isSuccessAction,
    String? successMessage,
    String? errorMessage,
  }) {
    return OrganizerEventsState(
      isLoading: isLoading ?? this.isLoading,
      events: events ?? this.events,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      isSuccessAction: isSuccessAction ?? false,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }
}

// --- BLOC ---
class OrganizerEventsBloc extends Bloc<OrganizerEventsEvent, OrganizerEventsState> {
  final ApiService apiService;

  OrganizerEventsBloc({required this.apiService}) : super(OrganizerEventsState()) {
    on<LoadEvents>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      final result = await apiService.getMyEvents();
      if (result['success']) {
        emit(state.copyWith(isLoading: false, events: result['data']));
      } else {
        emit(state.copyWith(isLoading: false, errorMessage: 'Failed to load events'));
      }
    });

    on<UpdateFilter>((event, emit) {
      emit(state.copyWith(filter: event.filter));
    });

    on<UpdateSearchQuery>((event, emit) {
      emit(state.copyWith(searchQuery: event.query));
    });

    on<ToggleEventStatusEvent>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      final result = await apiService.toggleEventStatus(event.eventId);
      
      if (result['success']) {
        emit(state.copyWith(
          isSuccessAction: true, 
          successMessage: 'Статус ивента обновлен!'
        ));
        add(LoadEvents()); // Reload events after changing status
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: "Ошибка: ${result['message']}"
        ));
      }
    });

    on<FinishEventEvent>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      final result = await apiService.finishEvent(event.eventId);
      
      if (result['success']) {
        emit(state.copyWith(
          isSuccessAction: true, 
          successMessage: 'Ивент успешно завершен! 🎉\\nЧасы начислены волонтерам.'
        ));
        add(LoadEvents());
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: "Ошибка: ${result['message']}"
        ));
      }
    });
  }
}
