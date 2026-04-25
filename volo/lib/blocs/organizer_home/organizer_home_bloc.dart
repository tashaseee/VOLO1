import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';

// Events
abstract class OrganizerHomeEvent {}

class LoadOrganizerHomeData extends OrganizerHomeEvent {}
class ChangeOrganizerAdIndex extends OrganizerHomeEvent {
  final int index;
  ChangeOrganizerAdIndex(this.index);
}

// State
class OrganizerHomeState {
  final Map<String, dynamic>? userData;
  final List<dynamic> myEvents;
  final List<dynamic> recentApplications;
  final bool isLoading;
  final int currentAdIndex;

  const OrganizerHomeState({
    this.userData,
    this.myEvents = const [],
    this.recentApplications = const [],
    this.isLoading = true,
    this.currentAdIndex = 0,
  });

  OrganizerHomeState copyWith({
    Map<String, dynamic>? userData,
    List<dynamic>? myEvents,
    List<dynamic>? recentApplications,
    bool? isLoading,
    int? currentAdIndex,
  }) {
    return OrganizerHomeState(
      userData: userData ?? this.userData,
      myEvents: myEvents ?? this.myEvents,
      recentApplications: recentApplications ?? this.recentApplications,
      isLoading: isLoading ?? this.isLoading,
      currentAdIndex: currentAdIndex ?? this.currentAdIndex,
    );
  }
}

// Bloc
class OrganizerHomeBloc extends Bloc<OrganizerHomeEvent, OrganizerHomeState> {
  final ApiService apiService;

  OrganizerHomeBloc({required this.apiService}) : super(const OrganizerHomeState()) {
    on<LoadOrganizerHomeData>(_onLoad);
    on<ChangeOrganizerAdIndex>((event, emit) => emit(state.copyWith(currentAdIndex: event.index)));
  }

  Future<void> _onLoad(LoadOrganizerHomeData event, Emitter<OrganizerHomeState> emit) async {
    emit(state.copyWith(isLoading: true));
    final userResult = await apiService.getUserProfile();
    final eventsResult = await apiService.getMyEvents();

    Map<String, dynamic>? userData;
    List<dynamic> events = [];

    if (userResult['success'] == true) userData = userResult['data'];
    if (eventsResult['success'] == true) events = eventsResult['data'];

    List<dynamic> allApplications = [];
    for (var e in events) {
      final appsResult = await apiService.getEventApplications(e['id']);
      if (appsResult['success'] == true) allApplications.addAll(appsResult['data']);
    }
    allApplications.sort((a, b) => b['created_at'].compareTo(a['created_at']));

    emit(state.copyWith(
      isLoading: false,
      userData: userData,
      myEvents: events,
      recentApplications: allApplications.take(5).toList(),
    ));
  }
}
