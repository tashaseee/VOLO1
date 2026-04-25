import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';

// Events
abstract class ApplicationsEvent {}

class LoadApplications extends ApplicationsEvent {}

class ChangeApplicationTab extends ApplicationsEvent {
  final int tab;
  ChangeApplicationTab(this.tab);
}

// State
class ApplicationsState {
  final List<dynamic> applications;
  final bool isLoading;
  final int selectedTab;

  const ApplicationsState({
    this.applications = const [],
    this.isLoading = true,
    this.selectedTab = 0,
  });

  ApplicationsState copyWith({
    List<dynamic>? applications,
    bool? isLoading,
    int? selectedTab,
  }) {
    return ApplicationsState(
      applications: applications ?? this.applications,
      isLoading: isLoading ?? this.isLoading,
      selectedTab: selectedTab ?? this.selectedTab,
    );
  }
}

// Bloc
class ApplicationsBloc extends Bloc<ApplicationsEvent, ApplicationsState> {
  final ApiService apiService;

  ApplicationsBloc({required this.apiService}) : super(const ApplicationsState()) {
    on<LoadApplications>(_onLoad);
    on<ChangeApplicationTab>((event, emit) => emit(state.copyWith(selectedTab: event.tab)));
  }

  Future<void> _onLoad(LoadApplications event, Emitter<ApplicationsState> emit) async {
    emit(state.copyWith(isLoading: true));
    final result = await apiService.getMyApplications();
    if (result['success'] == true) {
      emit(state.copyWith(isLoading: false, applications: result['data']));
    } else {
      emit(state.copyWith(isLoading: false));
    }
  }
}
