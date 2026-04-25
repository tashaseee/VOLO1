import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'sign_in_event.dart';
import 'sign_in_state.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  final ApiService apiService;

  SignInBloc({required this.apiService}) : super(const SignInState()) {
    on<TogglePasswordVisibility>((event, emit) {
      emit(state.copyWith(showPassword: !state.showPassword, errorMessage: null));
    });

    on<SignInRequested>((event, emit) async {
      if (event.email.trim().isEmpty || event.password.isEmpty) {
        emit(state.copyWith(errorMessage: 'Пожалуйста, заполните все поля'));
        return;
      }

      emit(state.copyWith(isLoading: true, errorMessage: null));

      try {
        final result = await apiService.login(event.email.trim(), event.password);
        
        if (result['success'] == true) {
          emit(state.copyWith(isLoading: false, isSuccess: true, userData: result['data']));
        } else {
          emit(state.copyWith(isLoading: false, errorMessage: result['message'] ?? 'Ошибка авторизации'));
        }
      } catch (e) {
        emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      }
    });
  }
}
