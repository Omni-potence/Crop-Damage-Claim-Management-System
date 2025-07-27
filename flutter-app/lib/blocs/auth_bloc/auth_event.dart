import 'package:equatable/equatable.dart';
import 'package:crop_damage_app/models/user.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AppStarted extends AuthEvent {}

class EmailSignInSubmitted extends AuthEvent {
  final String email;
  final String password;

  const EmailSignInSubmitted(this.email, this.password);

  @override
  List<Object> get props => [email, password];
}

class EmailSignUpSubmitted extends AuthEvent {
  final String email;
  final String password;
  final String name;

  const EmailSignUpSubmitted(this.email, this.password, this.name);

  @override
  List<Object> get props => [email, password, name];
}

class GoogleSignInSubmitted extends AuthEvent {}

class ProfileCompleted extends AuthEvent {
  final User user;

  const ProfileCompleted(this.user);

  @override
  List<Object> get props => [user];
}

class AuthSignedOut extends AuthEvent {}
