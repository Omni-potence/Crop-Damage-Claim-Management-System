import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:crop_damage_app/models/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSignUpMode extends AuthState {}

class AuthSignInMode extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User appUser;

  const AuthAuthenticated(this.appUser);

  @override
  List<Object> get props => [appUser];
}

class AuthProfileSetupRequired extends AuthState {
  final String userId;

  const AuthProfileSetupRequired(this.userId);

  @override
  List<Object> get props => [userId];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}
