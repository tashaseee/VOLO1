import 'package:equatable/equatable.dart';

class RegisterState extends Equatable {
  final bool isLoading;
  final bool showPassword;
  final bool showConfirmPassword;
  final bool isOrganization;
  final bool isSuccess;
  final String? errorMessage;
  final int formUpdateFlag;

  const RegisterState({
    this.isLoading = false,
    this.showPassword = false,
    this.showConfirmPassword = false,
    this.isOrganization = false,
    this.isSuccess = false,
    this.errorMessage,
    this.formUpdateFlag = 0,
  });

  RegisterState copyWith({
    bool? isLoading,
    bool? showPassword,
    bool? showConfirmPassword,
    bool? isOrganization,
    bool? isSuccess,
    String? errorMessage,
    bool clearError = false,
    int? formUpdateFlag,
  }) {
    return RegisterState(
      isLoading: isLoading ?? this.isLoading,
      showPassword: showPassword ?? this.showPassword,
      showConfirmPassword: showConfirmPassword ?? this.showConfirmPassword,
      isOrganization: isOrganization ?? this.isOrganization,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      formUpdateFlag: formUpdateFlag ?? this.formUpdateFlag,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        showPassword,
        showConfirmPassword,
        isOrganization,
        isSuccess,
        errorMessage,
        formUpdateFlag,
      ];
}
