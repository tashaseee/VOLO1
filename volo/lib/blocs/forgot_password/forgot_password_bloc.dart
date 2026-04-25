import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'forgot_password_event.dart';
import 'forgot_password_state.dart';

class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final ApiService apiService;

  ForgotPasswordBloc({required this.apiService}) : super(const ForgotPasswordState()) {
    on<SendCodeRequested>((event, emit) async {
      final email = event.email.trim();
      if (email.isEmpty) {
        emit(state.copyWith(errorMessage: 'Введите Email'));
        return;
      }

      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(email)) {
        emit(state.copyWith(errorMessage: 'Введите корректный Email'));
        return;
      }

      emit(state.copyWith(isLoading: true, clearError: true));

      try {
        final result = await apiService.forgotPassword(email);
        
        if (result['success'] == true) {
          emit(state.copyWith(
            isLoading: false, 
            isSuccess: true, 
            successMessage: 'Если аккаунт существует, код отправлен на $email',
          ));
        } else {
          emit(state.copyWith(isLoading: false, errorMessage: result['message'] ?? 'Ошибка отправки'));
        }
      } catch (e) {
        emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      }
    });
  }
}
