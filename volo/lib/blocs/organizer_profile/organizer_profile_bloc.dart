import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

class UploadCertificateTemplate extends OrganizerProfileEvent {
  final String imagePath;
  UploadCertificateTemplate(this.imagePath);
}

class OrganizerProfileState {
  final bool isLoading;
  final String orgName;
  final String orgDesc;
  final String phone;
  final String website;
  final String bin;
  final String address;
  final int eventsCount;
  final int appsCount;
  final double rating;
  final String? avatarUrl;
  final String? certificateTemplateUrl;
  final bool isSaving;
  final bool isSuccessAction;
  final String? message;

  OrganizerProfileState({
    this.isLoading = true,
    this.orgName = 'Загрузка...',
    this.orgDesc = '',
    this.phone = '',
    this.website = '',
    this.bin = '',
    this.address = '',
    this.eventsCount = 0,
    this.appsCount = 0,
    this.rating = 0.0,
    this.avatarUrl,
    this.certificateTemplateUrl,
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
    String? bin,
    String? address,
    int? eventsCount,
    int? appsCount,
    double? rating,
    String? avatarUrl,
    String? certificateTemplateUrl,
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
      bin: bin ?? this.bin,
      address: address ?? this.address,
      eventsCount: eventsCount ?? this.eventsCount,
      appsCount: appsCount ?? this.appsCount,
      rating: rating ?? this.rating,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      certificateTemplateUrl: certificateTemplateUrl ?? this.certificateTemplateUrl,
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

      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedAvatar = prefs.getString('cached_org_avatar_url');
        if (cachedAvatar != null && state.avatarUrl == null) {
          emit(state.copyWith(avatarUrl: cachedAvatar));
        }
      } catch (_) {}

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
      String bin = state.bin;
      String address = state.address;
      String? avatarUrl = state.avatarUrl;
      String? certificateTemplateUrl = state.certificateTemplateUrl;
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
        bin = profile?['bin'] ?? '';
        address = profile?['address'] ?? '';
        avatarUrl = profile?['avatar_url'];
        certificateTemplateUrl = profile?['certificate_template_url'];
        
        if (avatarUrl != null) {
          SharedPreferences.getInstance().then((prefs) => prefs.setString('cached_org_avatar_url', avatarUrl!));
        }
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
        bin: bin,
        address: address,
        eventsCount: eventsCount,
        appsCount: appsCount,
        rating: rating,
        avatarUrl: avatarUrl,
        certificateTemplateUrl: certificateTemplateUrl,
      ));
    });

    on<UpdateOrganizerProfile>((event, emit) async {
      emit(state.copyWith(isSaving: true));
      final result = await apiService.updateOrgProfile(event.profileData);

      if (result['success'] == true) {
        emit(state.copyWith(
          isSaving: false,
          isSuccessAction: true,
          message: 'Профиль успешно обновлён',
          orgName: event.profileData['full_name'] ?? state.orgName,
          orgDesc: event.profileData['description'] ?? state.orgDesc,
          phone: event.profileData['phone'] ?? state.phone,
          website: event.profileData['website'] ?? state.website,
          bin: event.profileData['bin'] ?? state.bin,
          address: event.profileData['address'] ?? state.address,
          certificateTemplateUrl: event.profileData['certificate_template_url'] ?? state.certificateTemplateUrl,
        ));
      } else {
        emit(state.copyWith(
          isSaving: false,
          message: result['message'] ?? 'Ошибка сохранения',
        ));
      }
    });

    on<UpdateAvatar>((event, emit) async {
      final result = await apiService.uploadAvatar(event.imagePath);
      if (result['success'] == true) {
        emit(state.copyWith(
          isSuccessAction: true,
          message: 'Фото обновлено',
          avatarUrl: result['data']['avatar_url'],
        ));
      } else {
        emit(state.copyWith(message: result['message'] ?? 'Ошибка загрузки'));
      }
    });

    on<UploadCertificateTemplate>((event, emit) async {
      emit(state.copyWith(isSaving: true));
      final result = await apiService.uploadCertificateTemplate(event.imagePath);
      if (result['success'] == true) {
        emit(state.copyWith(
          isSaving: false,
          isSuccessAction: true,
          message: 'Шаблон сертификата сохранён',
          certificateTemplateUrl: result['data']['certificate_template_url'],
        ));
      } else {
        emit(state.copyWith(
          isSaving: false,
          message: result['message'] ?? 'Ошибка загрузки шаблона',
        ));
      }
    });
  }
}
