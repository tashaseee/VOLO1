import 'package:equatable/equatable.dart';

abstract class RegisterEvent extends Equatable {
  const RegisterEvent();

  @override
  List<Object?> get props => [];
}

class RegisterRequested extends RegisterEvent {
  final String email;
  final String password;
  final bool isOrganization;
  final String? orgName;
  final String? bin;

  const RegisterRequested({
    required this.email,
    required this.password,
    required this.isOrganization,
    this.orgName,
    this.bin,
  });

  @override
  List<Object?> get props => [email, password, isOrganization, orgName, bin];
}

class TogglePasswordVisibility extends RegisterEvent {}

class ToggleConfirmPasswordVisibility extends RegisterEvent {}

class ChangeAccountType extends RegisterEvent {
  final bool isOrganization;
  const ChangeAccountType(this.isOrganization);

  @override
  List<Object?> get props => [isOrganization];
}

class RegisterFormChanged extends RegisterEvent {}
