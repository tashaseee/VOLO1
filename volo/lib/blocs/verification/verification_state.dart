import 'package:equatable/equatable.dart';

class VerificationState extends Equatable {
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;
  final String? role;

  const VerificationState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
    this.role,
  });

  VerificationState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    String? role,
    bool clearError = false,
  }) {
    return VerificationState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      role: role ?? this.role,
    );
  }

  @override
  List<Object?> get props => [isLoading, isSuccess, errorMessage, role];
}
