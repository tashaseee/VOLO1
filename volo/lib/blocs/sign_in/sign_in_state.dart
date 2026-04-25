import 'package:equatable/equatable.dart';

class SignInState extends Equatable {
  final bool isLoading;
  final bool showPassword;
  final bool isSuccess;
  final String? errorMessage;
  final dynamic userData;

  const SignInState({
    this.isLoading = false,
    this.showPassword = false,
    this.isSuccess = false,
    this.errorMessage,
    this.userData,
  });

  SignInState copyWith({
    bool? isLoading,
    bool? showPassword,
    bool? isSuccess,
    String? errorMessage,
    dynamic userData,
  }) {
    return SignInState(
      isLoading: isLoading ?? this.isLoading,
      showPassword: showPassword ?? this.showPassword,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage, // We don't use ?? to allow clearing errors by passing null explicitly below
      userData: userData ?? this.userData,
    );
  }

  @override
  List<Object?> get props => [isLoading, showPassword, isSuccess, errorMessage, userData];
}
