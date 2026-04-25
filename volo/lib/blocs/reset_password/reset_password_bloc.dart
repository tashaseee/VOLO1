import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';

abstract class ResetPasswordEvent {}

class ResendCodeRequested extends ResetPasswordEvent {
  final String email;
  ResendCodeRequested(this.email);
}

class ResetPasswordRequested extends ResetPasswordEvent {
  final String email;
  final String code;
  final String password;
  ResetPasswordRequested(this.email, this.code, this.password);
}

class TogglePasswordVisibility extends ResetPasswordEvent {}
class ToggleConfirmPasswordVisibility extends ResetPasswordEvent {}

class ResetPasswordState {
  final bool isLoading;
  final bool isSuccess;
  final String? successMessage;
  final String? errorMessage;
  final bool showPassword;
  final bool showConfirmPassword;

  const ResetPasswordState({
    this.isLoading = false,
    this.isSuccess = false,
    this.successMessage,
    this.errorMessage,
    this.showPassword = false,
    this.showConfirmPassword = false,
  });

  ResetPasswordState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? successMessage,
    String? errorMessage,
    bool? showPassword,
    bool? showConfirmPassword,
  }) {
    return ResetPasswordState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      successMessage: successMessage,
      errorMessage: errorMessage,
      showPassword: showPassword ?? this.showPassword,
      showConfirmPassword: showConfirmPassword ?? this.showConfirmPassword,
    );
  }
}

class ResetPasswordBloc extends Bloc<ResetPasswordEvent, ResetPasswordState> {
  final ApiService apiService;

  ResetPasswordBloc({required this.apiService}) : super(const ResetPasswordState()) {
    on<TogglePasswordVisibility>((event, emit) {
      emit(state.copyWith(
        showPassword: !state.showPassword,
        errorMessage: null,
        successMessage: null,
      ));
    });

    on<ToggleConfirmPasswordVisibility>((event, emit) {
      emit(state.copyWith(
        showConfirmPassword: !state.showConfirmPassword,
        errorMessage: null,
        successMessage: null,
      ));
    });

    on<ResendCodeRequested>((event, emit) async {
      emit(state.copyWith(isLoading: true, errorMessage: null, successMessage: null));
      try {
        final result = await apiService.forgotPassword(event.email);
        if (result['success'] == true) {
          emit(state.copyWith(isLoading: false, successMessage: 'Код отправлен повторно'));
        } else {
          emit(state.copyWith(isLoading: false, errorMessage: result['message'] ?? 'Ошибка отправки'));
        }
      } catch (e) {
        emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      }
    });

    on<ResetPasswordRequested>((event, emit) async {
      emit(state.copyWith(isLoading: true, errorMessage: null, successMessage: null));
      try {
        final result = await apiService.resetPassword(event.email, event.code, event.password);
        if (result['success'] == true) {
          emit(state.copyWith(isLoading: false, isSuccess: true, successMessage: 'Пароль успешно изменен'));
        } else {
          emit(state.copyWith(isLoading: false, errorMessage: result['message'] ?? 'Ошибка сброса пароля'));
        }
      } catch (e) {
        emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      }
    });
  }
}
