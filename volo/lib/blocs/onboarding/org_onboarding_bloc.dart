import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';

abstract class OrgOnboardingEvent {}

class SubmitOrgOnboarding extends OrgOnboardingEvent {
  final String description;
  final String website;
  final String address;
  final String phone;

  SubmitOrgOnboarding({
    required this.description,
    required this.website,
    required this.address,
    required this.phone,
  });
}

class OrgOnboardingState {
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;

  OrgOnboardingState({
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  OrgOnboardingState copyWith({
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return OrgOnboardingState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
    );
  }
}

class OrgOnboardingBloc extends Bloc<OrgOnboardingEvent, OrgOnboardingState> {
  final ApiService apiService;

  OrgOnboardingBloc({required this.apiService}) : super(OrgOnboardingState()) {
    on<SubmitOrgOnboarding>((event, emit) async {
      emit(state.copyWith(isSubmitting: true));

      final result = await apiService.updateOrgProfile({
        'description': event.description,
        'website': event.website,
        'address': event.address,
        'phone': event.phone,
      });

      if (result['success']) {
        emit(state.copyWith(isSubmitting: false, isSuccess: true));
      } else {
        emit(state.copyWith(
          isSubmitting: false,
          errorMessage: result['message'] ?? 'Ошибка сохранения',
        ));
      }
    });
  }
}
