import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';

abstract class ProfileEvent {}

class LoadProfile extends ProfileEvent {}

class UpdateAvatar extends ProfileEvent {
  final String imagePath;
  UpdateAvatar(this.imagePath);
}

class RateEvent extends ProfileEvent {
  final String eventKey;
  RateEvent(this.eventKey);
}

class ProfileState {
  final bool isLoading;
  final String userName;
  final String userCity;
  final int voloHours;
  final int eventsDone;
  final int ecoScore;
  final int socialScore;
  final int sportScore;
  final List<dynamic> certificates;
  final List<dynamic> activeEvents;
  final List<dynamic> plannedEvents;
  final String? avatarUrl;
  final Map<String, bool> ratedEvents;
  final String? message;
  final bool isError;

  ProfileState({
    this.isLoading = true,
    this.userName = 'Загрузка...',
    this.userCity = 'Загрузка...',
    this.voloHours = 0,
    this.eventsDone = 0,
    this.ecoScore = 0,
    this.socialScore = 0,
    this.sportScore = 0,
    this.certificates = const [],
    this.activeEvents = const [],
    this.plannedEvents = const [],
    this.avatarUrl,
    this.ratedEvents = const {},
    this.message,
    this.isError = false,
  });

  ProfileState copyWith({
    bool? isLoading,
    String? userName,
    String? userCity,
    int? voloHours,
    int? eventsDone,
    int? ecoScore,
    int? socialScore,
    int? sportScore,
    List<dynamic>? certificates,
    List<dynamic>? activeEvents,
    List<dynamic>? plannedEvents,
    String? avatarUrl,
    Map<String, bool>? ratedEvents,
    String? message,
    bool? isError,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      userName: userName ?? this.userName,
      userCity: userCity ?? this.userCity,
      voloHours: voloHours ?? this.voloHours,
      eventsDone: eventsDone ?? this.eventsDone,
      ecoScore: ecoScore ?? this.ecoScore,
      socialScore: socialScore ?? this.socialScore,
      sportScore: sportScore ?? this.sportScore,
      certificates: certificates ?? this.certificates,
      activeEvents: activeEvents ?? this.activeEvents,
      plannedEvents: plannedEvents ?? this.plannedEvents,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      ratedEvents: ratedEvents ?? this.ratedEvents,
      message: message,
      isError: isError ?? false,
    );
  }
}

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ApiService apiService;

  ProfileBloc({required this.apiService}) : super(ProfileState()) {
    on<LoadProfile>((event, emit) async {
      emit(state.copyWith(isLoading: true));

      final results = await Future.wait([
        apiService.getUserProfile(),
        apiService.getMyApplications(),
        apiService.getMyCertificates(),
      ]);

      final profileResult = results[0];
      final appsResult = results[1];
      final certsResult = results[2];

      String userName = state.userName;
      String userCity = state.userCity;
      int voloHours = state.voloHours;
      int eventsDone = state.eventsDone;
      int ecoScore = state.ecoScore;
      int socialScore = state.socialScore;
      int sportScore = state.sportScore;
      String? avatarUrl = state.avatarUrl;
      List<dynamic> activeEvents = state.activeEvents;
      List<dynamic> plannedEvents = state.plannedEvents;
      List<dynamic> certificates = state.certificates;

      if (profileResult['success']) {
        final data = profileResult['data'];
        final profile = data['profile'];
        userName = profile?['full_name'] ?? 'Имя не указано';
        userCity = profile?['city'] ?? 'Город не указан';
        voloHours = profile?['volo_hours'] ?? 0;
        eventsDone = profile?['events_done'] ?? 0;
        ecoScore = profile?['eco_score'] ?? 0;
        socialScore = profile?['social_score'] ?? 0;
        sportScore = profile?['sport_score'] ?? 0;
        avatarUrl = profile?['avatar_url'];
      } else {
        userName = 'Ошибка загрузки';
        userCity = '';
      }

      if (appsResult['success']) {
        final apps = appsResult['data'] as List;
        activeEvents = apps.where((a) => a['status'] == 'approved' && a['status'] != 'completed').toList();
        plannedEvents = apps.where((a) => a['status'] == 'pending').toList();
      }

      if (certsResult['success']) {
        certificates = certsResult['data'];
      }

      emit(state.copyWith(
        isLoading: false,
        userName: userName,
        userCity: userCity,
        voloHours: voloHours,
        eventsDone: eventsDone,
        ecoScore: ecoScore,
        socialScore: socialScore,
        sportScore: sportScore,
        avatarUrl: avatarUrl,
        activeEvents: activeEvents,
        plannedEvents: plannedEvents,
        certificates: certificates,
      ));
    });

    on<UpdateAvatar>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      final result = await apiService.uploadAvatar(event.imagePath);
      if (result['success']) {
        emit(state.copyWith(
          isLoading: false,
          avatarUrl: result['data']['avatar_url'],
          message: 'Аватар обновлен',
          isError: false,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          message: result['message'] ?? 'Ошибка загрузки',
          isError: true,
        ));
      }
    });

    on<RateEvent>((event, emit) {
      final updatedRates = Map<String, bool>.from(state.ratedEvents);
      updatedRates[event.eventKey] = true;
      emit(state.copyWith(ratedEvents: updatedRates));
    });
  }
}
