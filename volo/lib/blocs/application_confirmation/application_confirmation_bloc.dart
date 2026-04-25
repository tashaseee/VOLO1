import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';

// --- EVENTS ---
abstract class ApplicationConfirmationEvent {}

class SubmitApplication extends ApplicationConfirmationEvent {
  final int eventId;
  SubmitApplication(this.eventId);
}

class ToggleAgreement extends ApplicationConfirmationEvent {}

// --- STATE ---
class ApplicationConfirmationState {
  final bool isSubmitting;
  final bool isSuccess;
  final bool agreed;
  final String? errorMessage;

  ApplicationConfirmationState({
    this.isSubmitting = false,
    this.isSuccess = false,
    this.agreed = false,
    this.errorMessage,
  });

  ApplicationConfirmationState copyWith({
    bool? isSubmitting,
    bool? isSuccess,
    bool? agreed,
    String? errorMessage,
  }) {
    return ApplicationConfirmationState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      agreed: agreed ?? this.agreed,
      errorMessage: errorMessage,
    );
  }
}

// --- BLOC ---
class ApplicationConfirmationBloc extends Bloc<ApplicationConfirmationEvent, ApplicationConfirmationState> {
  final ApiService apiService;

  ApplicationConfirmationBloc({required this.apiService}) : super(ApplicationConfirmationState()) {
    on<ToggleAgreement>((event, emit) {
      emit(state.copyWith(agreed: !state.agreed));
    });

    on<SubmitApplication>((event, emit) async {
      emit(state.copyWith(isSubmitting: true));

      await Future.delayed(const Duration(milliseconds: 600));
      final result = await apiService.applyToEvent(event.eventId);

      if (result['success']) {
        emit(state.copyWith(
          isSubmitting: false,
          isSuccess: true,
        ));
      } else {
        emit(state.copyWith(
          isSubmitting: false,
          errorMessage: result['message'] ?? 'Ошибка при подаче заявки',
        ));
      }
    });
  }
}
