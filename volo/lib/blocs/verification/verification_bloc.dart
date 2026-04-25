import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'verification_event.dart';
import 'verification_state.dart';

class VerificationBloc extends Bloc<VerificationEvent, VerificationState> {
  final ApiService apiService;

  VerificationBloc({required this.apiService}) : super(const VerificationState()) {
    on<VerifyCodeRequested>((event, emit) async {
      if (event.code.length < 6) {
        emit(state.copyWith(errorMessage: 'Введите 6-значный код'));
        return;
      }

      emit(state.copyWith(isLoading: true, clearError: true));

      try {
        final result = await apiService.verifyEmail(event.email, event.code);
        
        if (result['success'] == true) {
          // Login after verification
          final loginResult = await apiService.login(event.email, event.password);
          
          if (loginResult['success'] == true) {
            final role = loginResult['data']['role'];
            emit(state.copyWith(isLoading: false, isSuccess: true, role: role));
          } else {
            emit(state.copyWith(isLoading: false, errorMessage: loginResult['message'] ?? 'Ошибка авторизации после верификации'));
          }
        } else {
          emit(state.copyWith(isLoading: false, errorMessage: result['message'] ?? 'Неверный код'));
        }
      } catch (e) {
        emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      }
    });
  }
}
