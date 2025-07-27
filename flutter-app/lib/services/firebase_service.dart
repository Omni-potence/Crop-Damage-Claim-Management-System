import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:crop_damage_app/models/user.dart';
import 'package:crop_damage_app/models/claim.dart';

class FirebaseService {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Retry mechanism for network operations
  Future<T> _retryOperation<T>(Future<T> Function() operation, {int maxRetries = 3}) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        print('🔥 Operation failed (attempt $attempts/$maxRetries): $e');

        if (attempts >= maxRetries) {
          print('🔥 Max retries reached, throwing error');
          rethrow;
        }

        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: attempts * 2));
        print('🔥 Retrying operation...');
      }
    }
    throw Exception('Operation failed after $maxRetries attempts');
  }

  // --- Authentication Methods ---

  Stream<fb_auth.User?> get authStateChanges => _auth.authStateChanges();

  // Email/Password Authentication
  Future<fb_auth.UserCredential> signInWithEmailPassword(String email, String password) async {
    print('🔥 Attempting to sign in with email: $email');
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('🔥 Email sign in successful: ${result.user?.uid}');
      return result;
    } catch (e) {
      print('🔥 Email sign in failed: $e');
      rethrow;
    }
  }

  Future<fb_auth.UserCredential> signUpWithEmailPassword(String email, String password) async {
    print('🔥 Attempting to sign up with email: $email');
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send email verification
      if (result.user != null && !result.user!.emailVerified) {
        await result.user!.sendEmailVerification();
        print('🔥 Email verification sent to: $email');
      }

      print('🔥 Email sign up successful: ${result.user?.uid}');
      return result;
    } catch (e) {
      print('🔥 Email sign up failed: $e');
      rethrow;
    }
  }

  // Google Authentication
  Future<fb_auth.UserCredential> signInWithGoogle() async {
    print('🔥 Attempting to sign in with Google');
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw fb_auth.FirebaseAuthException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Sign in aborted by user',
        );
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = fb_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final result = await _auth.signInWithCredential(credential);
      print('🔥 Google sign in successful: ${result.user?.uid}');
      return result;
    } catch (e) {
      print('🔥 Google sign in failed: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    print('🔥 User signed out successfully');
  }

  // --- User Management (Firestore) ---

  Future<void> createUserProfile(User user) async {
    await _firestore.collection('users').doc(user.id).set(user.toFirestore());
  }

  Future<User?> getUserProfile(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return User.fromFirestore(doc);
    }
    return null;
  }

  // --- Claim Management (Firestore & Storage) ---

  Future<String> uploadFile(File file, String path) async {
    return await _retryOperation(() async {
      print('🔥 Starting file upload to: $path');
      print('🔥 File size: ${await file.length()} bytes');

      // Ensure user is authenticated
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated for file upload');
      }

      print('🔥 User authenticated: ${currentUser.uid}');

      final ref = _storage.ref().child(path);

      // Add metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': currentUser.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      print('🔥 Starting upload task...');
      final uploadTask = ref.putFile(file, metadata);

      final snapshot = await uploadTask;
      print('🔥 Upload completed successfully');

      final downloadURL = await snapshot.ref.getDownloadURL();
      print('🔥 Download URL obtained: $downloadURL');

      return downloadURL;
    });
  }

  Future<void> submitClaim(Claim claim) async {
    return await _retryOperation(() async {
      print('🔥 Starting claim submission for user: ${claim.userId}');

      // Ensure user is authenticated
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated for claim submission');
      }

      if (currentUser.uid != claim.userId) {
        throw Exception('User ID mismatch in claim submission');
      }

      print('🔥 Adding claim to Firestore...');
      final docRef = await _firestore.collection('claims').add(claim.toFirestore());
      print('🔥 Claim submitted successfully with ID: ${docRef.id}');
    });
  }

  Stream<List<Claim>> getUserClaims(String userId) {
    print('🔥 Fetching claims for user: $userId');

    return _firestore
        .collection('claims')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          print('🔥 Claims snapshot received: ${snapshot.docs.length} documents');

          if (snapshot.docs.isEmpty) {
            print('🔥 No claims found for user: $userId');
            return <Claim>[];
          }

          final claims = snapshot.docs.map((doc) {
            print('🔥 Processing claim document: ${doc.id}');
            print('🔥 Claim data: ${doc.data()}');
            return Claim.fromFirestore(doc);
          }).toList();

          // Sort in memory instead of using orderBy to avoid index issues
          claims.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

          print('🔥 Successfully parsed and sorted ${claims.length} claims');
          return claims;
        });
  }
}
