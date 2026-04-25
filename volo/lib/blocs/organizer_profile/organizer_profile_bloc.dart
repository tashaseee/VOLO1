import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';

abstract class OrganizerProfileEvent {}

class LoadOrganizerProfile extends OrganizerProfileEvent {}

class UpdateOrganizerProfile extends OrganizerProfileEvent {
  final Map<String, dynamic> profileData;
  UpdateOrganizerProfile(this.profileData);
}

class UpdateAvatar extends OrganizerProfileEvent {
  final String imagePath;
  UpdateAvatar(this.imagePath);
}

class OrganizerProfileState {
  final bool isLoading;
  final String orgName;
  final String orgDesc;
  final String phone;
  final String website;
  final int eventsCount;
  final int appsCount;
  final double rating;
  final String? avatarUrl;
  final bool isSaving;
  final bool isSuccessAction;
  final String? message;

  OrganizerProfileState({
    this.isLoading = true,
    this.orgName = 'Загрузка...',
    this.orgDesc = '',
    this.phone = '',
    this.website = '',
    this.eventsCount = 0,
    this.appsCount = 0,
    this.rating = 0.0,
    this.avatarUrl,
    this.isSaving = false,
    this.isSuccessAction = false,
    this.message,
  });

  OrganizerProfileState copyWith({
    bool? isLoading,
    String? orgName,
    String? orgDesc,
    String? phone,
    String? website,
    int? eventsCount,
    int? appsCount,
    double? rating,
    String? avatarUrl,
    bool? isSaving,
    bool? isSuccessAction,
    String? message,
  }) {
    return OrganizerProfileState(
      isLoading: isLoading ?? this.isLoading,
      orgName: orgName ?? this.orgName,
      orgDesc: orgDesc ?? this.orgDesc,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      eventsCount: eventsCount ?? this.eventsCount,
      appsCount: appsCount ?? this.appsCount,
      rating: rating ?? this.rating,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isSaving: isSaving ?? false,
      isSuccessAction: isSuccessAction ?? false,
      message: message,
    );
  }
}

class OrganizerProfileBloc extends Bloc<OrganizerProfileEvent, OrganizerProfileState> {
  final ApiService apiService;

  OrganizerProfileBloc({required this.apiService}) : super(OrganizerProfileState()) {
    on<LoadOrganizerProfile>((event, emit) async {
      emit(state.copyWith(isLoading: true));

      final results = await Future.wait([
        apiService.getUserProfile(),
        apiService.getMyEvents()
      ]);

      final result = results[0];
      final eventsResult = results[1];

      String orgName = state.orgName;
      String orgDesc = state.orgDesc;
      String phone = state.phone;
      String website = state.website;
      String? avatarUrl = state.avatarUrl;
      int eventsCount = state.eventsCount;
      int appsCount = state.appsCount;
      double rating = state.rating;

      if (result['success']) {
        final data = result['data'];
        final profile = data['org_profile'];
        orgName = profile?['full_name'] ?? 'Организация';
        orgDesc = profile?['description'] ?? '';
        phone = profile?['phone'] ?? '';
        website = profile?['website'] ?? '';
        avatarUrl = profile?['avatar_url'];
      }

      if (eventsResult['success']) {
        final events = eventsResult['data'] as List;
        eventsCount = events.length;
        appsCount = events.fold(0, (sum, e) => sum + (e['applications_count'] as int? ?? 0));
        rating = 4.8;
      }

      emit(state.copyWith(
        isLoading: false,
        orgName: orgName,
        orgDesc: orgDesc,
        phone: phone,
        website: website,
        eventsCount: eventsCount,
        appsCount: appsCount,
        rating: rating,
        avatarUrl: avatarUrl,
      ));
    });

    on<UpdateOrganizerProfile>((event, emit) async {
      emit(state.copyWith(isSaving: true));
      // Replace with actual API call when implemented
      // final result = await apiService.updateOrgProfile(event.profileData);
      await Future.delayed(const Duration(milliseconds: 500)); 
      
      emit(state.copyWith(
        isSaving: false,
        isSuccessAction: true,
        message: 'Профиль успешно обновлен',
        orgName: event.profileData['full_name'] ?? state.orgName,
        orgDesc: event.profileData['description'] ?? state.orgDesc,
        phone: event.profileData['phone'] ?? state.phone,
        website: event.profileData['website'] ?? state.website,
      ));
      // add(LoadOrganizerProfile());
    });

    on<UpdateAvatar>((event, emit) async {
      emit(state.copyWith(isSuccessAction: true, message: 'Функция загрузки фото в разработке'));
    });
  }
}
