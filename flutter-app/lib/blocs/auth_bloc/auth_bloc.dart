import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:crop_damage_app/blocs/auth_bloc/auth_event.dart';
import 'package:crop_damage_app/blocs/auth_bloc/auth_state.dart';
import 'package:crop_damage_app/services/firebase_service.dart';
import 'package:crop_damage_app/models/user.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseService _firebaseService;

  AuthBloc(this._firebaseService) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<EmailSignInSubmitted>(_onEmailSignInSubmitted);
    on<EmailSignUpSubmitted>(_onEmailSignUpSubmitted);
    on<GoogleSignInSubmitted>(_onGoogleSignInSubmitted);
    on<ProfileCompleted>(_onProfileCompleted);
    on<AuthSignedOut>(_onAuthSignedOut);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    final fb_auth.User? user = await _firebaseService.authStateChanges.first;
    if (user != null) {
      final appUser = await _firebaseService.getUserProfile(user.uid);
      if (appUser != null) {
        emit(AuthAuthenticated(appUser));
      } else {
        // User authenticated with Firebase but no profile in Firestore
        emit(AuthUnauthenticated()); // Or a specific state for profile creation
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onEmailSignInSubmitted(
      EmailSignInSubmitted event, Emitter<AuthState> emit) async {
    print('🔥 BLoC: Email sign in submitted: ${event.email}');
    emit(AuthLoading());
    try {
      final userCredential = await _firebaseService.signInWithEmailPassword(
        event.email,
        event.password,
      );

      if (userCredential.user != null) {
        print('🔥 BLoC: Email sign in successful for user: ${userCredential.user!.uid}');
        await _handleUserAuthentication(userCredential.user!, emit);
      } else {
        emit(const AuthError('Failed to sign in with email.'));
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      print('🔥 BLoC: Email sign in failed: ${e.code} - ${e.message}');
      emit(AuthError(_getErrorMessage(e)));
    } catch (e) {
      print('🔥 BLoC: Email sign in error: $e');
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onEmailSignUpSubmitted(
      EmailSignUpSubmitted event, Emitter<AuthState> emit) async {
    print('🔥 BLoC: Email sign up submitted: ${event.email}');
    emit(AuthLoading());
    try {
      final userCredential = await _firebaseService.signUpWithEmailPassword(
        event.email,
        event.password,
      );

      if (userCredential.user != null) {
        print('🔥 BLoC: Email sign up successful for user: ${userCredential.user!.uid}');
        // Update display name
        await userCredential.user!.updateDisplayName(event.name);
        // New user needs profile setup
        emit(AuthProfileSetupRequired(userCredential.user!.uid));
      } else {
        emit(const AuthError('Failed to sign up with email.'));
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      print('🔥 BLoC: Email sign up failed: ${e.code} - ${e.message}');
      emit(AuthError(_getErrorMessage(e)));
    } catch (e) {
      print('🔥 BLoC: Email sign up error: $e');
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onGoogleSignInSubmitted(
      GoogleSignInSubmitted event, Emitter<AuthState> emit) async {
    print('🔥 BLoC: Google sign in submitted');
    emit(AuthLoading());
    try {
      final userCredential = await _firebaseService.signInWithGoogle();

      if (userCredential.user != null) {
        print('🔥 BLoC: Google sign in successful for user: ${userCredential.user!.uid}');
        await _handleUserAuthentication(userCredential.user!, emit);
      } else {
        emit(const AuthError('Failed to sign in with Google.'));
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      print('🔥 BLoC: Google sign in failed: ${e.code} - ${e.message}');
      emit(AuthError(_getErrorMessage(e)));
    } catch (e) {
      print('🔥 BLoC: Google sign in error: $e');
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _handleUserAuthentication(fb_auth.User firebaseUser, Emitter<AuthState> emit) async {
    // Check if user profile exists
    User? appUser = await _firebaseService.getUserProfile(firebaseUser.uid);
    if (appUser == null) {
      // For Google Sign-In, create profile automatically if we have the name
      if (firebaseUser.displayName != null && firebaseUser.displayName!.isNotEmpty) {
        print('🔥 BLoC: Creating profile for Google user: ${firebaseUser.displayName}');
        final newUser = User(
          id: firebaseUser.uid,
          name: firebaseUser.displayName!,
          phone: '', // No phone for Google auth
          aadhar: '', // Will be filled in profile setup
          address: '', // Will be filled in profile setup
          createdAt: Timestamp.now(),
        );

        // Save the basic profile
        await _firebaseService.createUserProfile(newUser);

        // Still need profile setup for Aadhar and address
        emit(AuthProfileSetupRequired(firebaseUser.uid));
      } else {
        // User needs to complete profile setup
        print('🔥 BLoC: New user - redirecting to profile setup');
        emit(AuthProfileSetupRequired(firebaseUser.uid));
      }
    } else {
      // User profile exists - authenticate
      print('🔥 BLoC: Existing user - authenticating');
      emit(AuthAuthenticated(appUser));
    }
  }

  String _getErrorMessage(fb_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }

  Future<void> _onProfileCompleted(
      ProfileCompleted event, Emitter<AuthState> emit) async {
    print('🔥 BLoC: Profile completed for user: ${event.user.id}');
    emit(AuthAuthenticated(event.user));
  }

  Future<void> _onAuthSignedOut(
      AuthSignedOut event, Emitter<AuthState> emit) async {
    await _firebaseService.signOut();
    emit(AuthUnauthenticated());
  }
}
