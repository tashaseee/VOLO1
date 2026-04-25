import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';

// Events
abstract class HomeEvent {}

class LoadHomeData extends HomeEvent {}
class ChangeAdIndex extends HomeEvent {
  final int index;
  ChangeAdIndex(this.index);
}
class ChangeBottomNavIndex extends HomeEvent {
  final int index;
  ChangeBottomNavIndex(this.index);
}

// State
class HomeState {
  final List<dynamic> events;
  final bool isLoading;
  final String userName;
  final String? avatarUrl;
  final int voloHours;
  final int currentAdIndex;
  final int selectedNavIndex;

  const HomeState({
    this.events = const [],
    this.isLoading = true,
    this.userName = '',
    this.avatarUrl,
    this.voloHours = 0,
    this.currentAdIndex = 0,
    this.selectedNavIndex = 2,
  });

  HomeState copyWith({
    List<dynamic>? events,
    bool? isLoading,
    String? userName,
    String? avatarUrl,
    int? voloHours,
    int? currentAdIndex,
    int? selectedNavIndex,
  }) {
    return HomeState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      userName: userName ?? this.userName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      voloHours: voloHours ?? this.voloHours,
      currentAdIndex: currentAdIndex ?? this.currentAdIndex,
      selectedNavIndex: selectedNavIndex ?? this.selectedNavIndex,
    );
  }
}

// Bloc
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ApiService apiService;

  HomeBloc({required this.apiService}) : super(const HomeState()) {
    on<LoadHomeData>(_onLoad);
    on<ChangeAdIndex>((event, emit) => emit(state.copyWith(currentAdIndex: event.index)));
    on<ChangeBottomNavIndex>((event, emit) => emit(state.copyWith(selectedNavIndex: event.index)));
  }

  Future<void> _onLoad(LoadHomeData event, Emitter<HomeState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final profileResult = await apiService.getUserProfile();
      final eventsResult = await apiService.getEvents();

      String name = '';
      String? avatar;
      int hours = 0;

      if (profileResult['success'] == true) {
        final data = profileResult['data'];
        name = data['full_name'] ?? data['email'] ?? '';
        avatar = data['avatar_url'];
        hours = data['total_hours'] ?? 0;
      }

      List<dynamic> events = [];
      if (eventsResult['success'] == true) {
        events = eventsResult['data'];
      }

      emit(state.copyWith(
        isLoading: false,
        userName: name,
        avatarUrl: avatar,
        voloHours: hours,
        events: events,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }
}
