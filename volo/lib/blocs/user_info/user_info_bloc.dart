import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';

abstract class UserInfoEvent {}

class LoadUserInfo extends UserInfoEvent {}

class SaveUserInfo extends UserInfoEvent {
  final String fullName;
  final String phone;
  final String motivation;
  final String city;
  final String gender;
  final String experience;
  
  SaveUserInfo({
    required this.fullName,
    required this.phone,
    required this.motivation,
    required this.city,
    required this.gender,
    required this.experience,
  });
}

class ToggleCategory extends UserInfoEvent {
  final String type; // 'interest' or 'skill'
  final String item;
  ToggleCategory(this.type, this.item);
}

class RemoveCategory extends UserInfoEvent {
  final String type;
  final String item;
  RemoveCategory(this.type, this.item);
}

class UserInfoState {
  final bool isLoading;
  final bool isSaving;
  final bool isSuccessAction;
  final String? message;
  final bool isError;
  
  final Map<String, dynamic> rawProfile;
  final List<String> interests;
  final List<String> skills;
  final int certificatesCount;

  UserInfoState({
    this.isLoading = true,
    this.isSaving = false,
    this.isSuccessAction = false,
    this.message,
    this.isError = false,
    this.rawProfile = const {},
    this.interests = const [],
    this.skills = const [],
    this.certificatesCount = 0,
  });

  UserInfoState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isSuccessAction,
    String? message,
    bool? isError,
    Map<String, dynamic>? rawProfile,
    List<String>? interests,
    List<String>? skills,
    int? certificatesCount,
  }) {
    return UserInfoState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isSuccessAction: isSuccessAction ?? false,
      message: message,
      isError: isError ?? false,
      rawProfile: rawProfile ?? this.rawProfile,
      interests: interests ?? this.interests,
      skills: skills ?? this.skills,
      certificatesCount: certificatesCount ?? this.certificatesCount,
    );
  }
}

class UserInfoBloc extends Bloc<UserInfoEvent, UserInfoState> {
  final ApiService apiService;

  UserInfoBloc({required this.apiService}) : super(UserInfoState()) {
    on<LoadUserInfo>((event, emit) async {
      emit(state.copyWith(isLoading: true));

      final results = await Future.wait([
        apiService.getUserProfile(),
        apiService.getMyCertificates(),
      ]);

      final profileResult = results[0];
      final certsResult = results[1];

      Map<String, dynamic> resultProfile = {};
      List<String> interests = [];
      List<String> skills = [];
      int certsCount = 0;

      if (profileResult['success']) {
        final data = profileResult['data'];
        final profile = data['profile'] ?? {};
        
        resultProfile = {
          'full_name': profile['full_name'] ?? 'Не указано',
          'birth_date': profile['birth_date'] ?? 'Не указано',
          'gender': profile['gender'] ?? 'Не указано',
          'city': profile['city'] ?? 'Не указано',
          'phone': profile['phone'] ?? 'Не указано',
          'email': data['email'] ?? '',
          'avatar_url': profile['avatar_url'],
          'volo_hours': profile['volo_hours'] ?? 0,
          'events_done': profile['events_done'] ?? 0,
          'eco_score': profile['eco_score'] ?? 0,
          'social_score': profile['social_score'] ?? 0,
          'sport_score': profile['sport_score'] ?? 0,
          'cultural_score': profile['cultural_score'] ?? 0,
          'experience': profile['experience'] ?? 'Волонтёр',
          'motivation': profile['motivation'] ?? '',
        };

        if (data['interests'] != null) {
          interests = (data['interests'] as List).map((e) => e['name'] as String).toList();
        }
        if (data['skills'] != null) {
          skills = (data['skills'] as List).map((e) => e['name'] as String).toList();
        }
      }

      if (certsResult['success']) {
        final List certs = certsResult['data'];
        certsCount = certs.length;
      }

      emit(state.copyWith(
        isLoading: false,
        rawProfile: resultProfile,
        interests: interests,
        skills: skills,
        certificatesCount: certsCount,
      ));
    });

    on<ToggleCategory>((event, emit) {
      if (event.type == 'interest') {
        final List<String> current = List.from(state.interests);
        if (current.contains(event.item)) {
          current.remove(event.item);
        } else {
          current.add(event.item);
        }
        emit(state.copyWith(interests: current));
      } else if (event.type == 'skill') {
        final List<String> current = List.from(state.skills);
        if (current.contains(event.item)) {
          current.remove(event.item);
        } else {
          current.add(event.item);
        }
        emit(state.copyWith(skills: current));
      }
    });

    on<RemoveCategory>((event, emit) {
      if (event.type == 'interest') {
        final List<String> current = List.from(state.interests);
        current.remove(event.item);
        emit(state.copyWith(interests: current));
      } else if (event.type == 'skill') {
        final List<String> current = List.from(state.skills);
        current.remove(event.item);
        emit(state.copyWith(skills: current));
      }
    });

    on<SaveUserInfo>((event, emit) async {
      emit(state.copyWith(isSaving: true));

      final profileData = {
        'full_name': event.fullName,
        'phone': event.phone,
        'motivation': event.motivation,
        'interests': state.interests,
        'skills': state.skills,
        'city': event.city,
        'gender': event.gender,
        'experience': event.experience,
      };

      final result = await apiService.updateProfile(profileData);
      
      if (result['success']) {
        Map<String, dynamic> currentData = Map.from(state.rawProfile);
        currentData['full_name'] = event.fullName;
        currentData['phone'] = event.phone;
        currentData['motivation'] = event.motivation;
        currentData['city'] = event.city;
        currentData['gender'] = event.gender;
        currentData['experience'] = event.experience;

        emit(state.copyWith(
          isSaving: false,
          isSuccessAction: true,
          message: 'Данные успешно обновлены',
          rawProfile: currentData,
        ));
      } else {
        emit(state.copyWith(
          isSaving: false,
          isSuccessAction: true,
          isError: true,
          message: result['message'] ?? 'Ошибка сохранения',
        ));
      }
    });
  }
}
