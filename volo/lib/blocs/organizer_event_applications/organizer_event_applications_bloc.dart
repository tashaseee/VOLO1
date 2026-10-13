import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';

// --- EVENTS ---
abstract class OrganizerEventAppsEvent {}

class LoadEventApps extends OrganizerEventAppsEvent {
  final int eventId;
  LoadEventApps(this.eventId);
}

class UpdateAppStatus extends OrganizerEventAppsEvent {
  final int eventId;
  final int applicationId;
  final String status;
  final Map<String, dynamic>? appData;

  UpdateAppStatus({
    required this.eventId,
    required this.applicationId,
    required this.status,
    this.appData,
  });
}

class FinishEvent extends OrganizerEventAppsEvent {
  final int eventId;
  FinishEvent(this.eventId);
}

// --- STATE ---
class OrganizerEventAppsState {
  final bool isLoading;
  final List<dynamic> applications;
  final Map<String, dynamic>? event;
  final bool isSuccessAction;
  final String? successMessage;
  final String? errorMessage;
  final bool showAcceptanceDialog;
  final Map<String, dynamic>? acceptedUser;

  OrganizerEventAppsState({
    this.isLoading = true,
    this.applications = const [],
    this.event,
    this.isSuccessAction = false,
    this.successMessage,
    this.errorMessage,
    this.showAcceptanceDialog = false,
    this.acceptedUser,
  });

  OrganizerEventAppsState copyWith({
    bool? isLoading,
    List<dynamic>? applications,
    Map<String, dynamic>? event,
    bool? isSuccessAction,
    String? successMessage,
    String? errorMessage,
    bool? showAcceptanceDialog,
    Map<String, dynamic>? acceptedUser,
  }) {
    return OrganizerEventAppsState(
      isLoading: isLoading ?? this.isLoading,
      applications: applications ?? this.applications,
      event: event ?? this.event,
      isSuccessAction: isSuccessAction ?? false,
      successMessage: successMessage,
      errorMessage: errorMessage,
      showAcceptanceDialog: showAcceptanceDialog ?? false,
      acceptedUser: acceptedUser,
    );
  }
}

// --- BLOC ---
class OrganizerEventAppsBloc extends Bloc<OrganizerEventAppsEvent, OrganizerEventAppsState> {
  final ApiService apiService;

  OrganizerEventAppsBloc({required this.apiService}) : super(OrganizerEventAppsState()) {
    on<LoadEventApps>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      
      final results = await Future.wait([
        apiService.getEventApplications(event.eventId),
        apiService.getMyEvents(),
      ]);

      final appsResult = results[0];
      final eventsResult = results[1];

      List<dynamic> apps = state.applications;
      Map<String, dynamic>? ev = state.event;

      if (appsResult['success']) apps = appsResult['data'];
      if (eventsResult['success']) {
        final events = eventsResult['data'] as List;
        ev = events.firstWhere((e) => e['id'] == event.eventId, orElse: () => null);
      }

      emit(state.copyWith(
        isLoading: false,
        applications: apps,
        event: ev,
      ));
    });

    on<UpdateAppStatus>((event, emit) async {
      final result = await apiService.updateApplicationStatus(event.applicationId, event.status);
      
      if (result['success']) {
        if (event.status == 'approved') {
          emit(state.copyWith(
            showAcceptanceDialog: true,
            acceptedUser: event.appData?['user'],
          ));
        } else {
          emit(state.copyWith(
            isSuccessAction: true,
            successMessage: 'Заявка отклонена ❌',
          ));
        }
        if (!isClosed) add(LoadEventApps(event.eventId));
      } else {
        emit(state.copyWith(
          errorMessage: "Ошибка: ${result['message']}"
        ));
      }
    });

    on<FinishEvent>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      final result = await apiService.finishEvent(event.eventId);
      
      if (result['success']) {
        emit(state.copyWith(
          isLoading: false,
          isSuccessAction: true,
          successMessage: result['message'] ?? 'Ивент успешно завершен!',
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Ошибка завершения',
        ));
      }
    });
  }
}
