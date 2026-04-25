import 'package:equatable/equatable.dart';

abstract class ForgotPasswordEvent extends Equatable {
  const ForgotPasswordEvent();

  @override
  List<Object> get props => [];
}

class SendCodeRequested extends ForgotPasswordEvent {
  final String email;

  const SendCodeRequested(this.email);

  @override
  List<Object> get props => [email];
}
