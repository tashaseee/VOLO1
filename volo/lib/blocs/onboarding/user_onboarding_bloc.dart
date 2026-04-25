import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';

abstract class UserOnboardingEvent {}

class UpdateField extends UserOnboardingEvent {
  final String field;
  final dynamic value;
  UpdateField(this.field, this.value);
}

class ToggleListField extends UserOnboardingEvent {
  final String field; // 'interests' or 'skills'
  final String item;
  ToggleListField(this.field, this.item);
}

class SubmitOnboarding extends UserOnboardingEvent {}

class UserOnboardingState {
  final String firstName;
  final String lastName;
  final DateTime? birthDate;
  final String gender;
  final String city;
  final String phone;
  final List<String> interests;
  final List<String> skills;
  final String experience;
  final String motivation;
  
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;

  UserOnboardingState({
    this.firstName = '',
    this.lastName = '',
    this.birthDate,
    this.gender = '',
    this.city = '',
    this.phone = '',
    this.interests = const [],
    this.skills = const [],
    this.experience = '',
    this.motivation = '',
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  UserOnboardingState copyWith({
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    String? gender,
    String? city,
    String? phone,
    List<String>? interests,
    List<String>? skills,
    String? experience,
    String? motivation,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return UserOnboardingState(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      interests: interests ?? this.interests,
      skills: skills ?? this.skills,
      experience: experience ?? this.experience,
      motivation: motivation ?? this.motivation,
      isSubmitting: isSubmitting ?? false,
      isSuccess: isSuccess ?? false,
      errorMessage: errorMessage,
    );
  }
}

class UserOnboardingBloc extends Bloc<UserOnboardingEvent, UserOnboardingState> {
  final ApiService apiService;

  UserOnboardingBloc({required this.apiService}) : super(UserOnboardingState()) {
    on<UpdateField>((event, emit) {
      if (event.field == 'firstName') emit(state.copyWith(firstName: event.value));
      if (event.field == 'lastName') emit(state.copyWith(lastName: event.value));
      if (event.field == 'birthDate') emit(state.copyWith(birthDate: event.value as DateTime));
      if (event.field == 'gender') emit(state.copyWith(gender: event.value));
      if (event.field == 'city') emit(state.copyWith(city: event.value));
      if (event.field == 'phone') emit(state.copyWith(phone: event.value));
      if (event.field == 'experience') emit(state.copyWith(experience: event.value));
      if (event.field == 'motivation') emit(state.copyWith(motivation: event.value));
    });

    on<ToggleListField>((event, emit) {
      if (event.field == 'interests') {
        final list = List<String>.from(state.interests);
        list.contains(event.item) ? list.remove(event.item) : list.add(event.item);
        emit(state.copyWith(interests: list));
      } else if (event.field == 'skills') {
        final list = List<String>.from(state.skills);
        list.contains(event.item) ? list.remove(event.item) : list.add(event.item);
        emit(state.copyWith(skills: list));
      }
    });

    on<SubmitOnboarding>((event, emit) async {
      emit(state.copyWith(isSubmitting: true));

      final profileData = {
        'full_name': '${state.firstName} ${state.lastName}'.trim(),
        'birth_date': state.birthDate?.toIso8601String().split('T')[0],
        'gender': state.gender,
        'city': state.city,
        'phone': state.phone,
        'interests': state.interests,
        'skills': state.skills,
        'experience': state.experience,
        'motivation': state.motivation,
      };

      final result = await apiService.updateProfile(profileData);
      
      if (result['success']) {
        emit(state.copyWith(isSubmitting: false, isSuccess: true));
      } else {
        emit(state.copyWith(
          isSubmitting: false, 
          errorMessage: result['message'] ?? 'Ошибка сохранения'
        ));
      }
    });
  }
}
