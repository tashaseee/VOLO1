import 'package:equatable/equatable.dart';

abstract class VerificationEvent extends Equatable {
  const VerificationEvent();

  @override
  List<Object> get props => [];
}

class VerifyCodeRequested extends VerificationEvent {
  final String email;
  final String password;
  final String code;

  const VerifyCodeRequested({
    required this.email,
    required this.password,
    required this.code,
  });

  @override
  List<Object> get props => [email, password, code];
}
