import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'register_event.dart';
import 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final ApiService apiService;

  RegisterBloc({required this.apiService}) : super(const RegisterState()) {
    on<TogglePasswordVisibility>((event, emit) {
      emit(state.copyWith(showPassword: !state.showPassword, clearError: true));
    });

    on<ToggleConfirmPasswordVisibility>((event, emit) {
      emit(state.copyWith(showConfirmPassword: !state.showConfirmPassword, clearError: true));
    });

    on<ChangeAccountType>((event, emit) {
      emit(state.copyWith(isOrganization: event.isOrganization, clearError: true));
    });

    on<RegisterFormChanged>((event, emit) {
      emit(state.copyWith(formUpdateFlag: state.formUpdateFlag + 1, clearError: true));
    });

    on<RegisterRequested>((event, emit) async {
      emit(state.copyWith(isLoading: true, clearError: true));

      try {
        final result = await apiService.register(
          event.email,
          event.password,
          role: event.isOrganization ? 'organizer' : 'volunteer',
          orgName: event.isOrganization ? event.orgName : null,
          bin: event.isOrganization ? event.bin : null,
        );
        
        if (result['success'] == true) {
          emit(state.copyWith(isLoading: false, isSuccess: true));
        } else {
          emit(state.copyWith(isLoading: false, errorMessage: result['message'] ?? 'Ошибка регистрации'));
        }
      } catch (e) {
        emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      }
    });
  }
}
