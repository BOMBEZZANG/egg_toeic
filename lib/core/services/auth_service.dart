import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Get current user ID (never null after initialization)
  String get currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated. Call initialize() first.');
    }
    return user.uid;
  }

  /// Check if current user is anonymous
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? true;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Initialize authentication (call on app start)
  Future<void> initialize() async {
    try {
      print('🔐 Starting Firebase Authentication initialization...');

      if (_auth.currentUser == null) {
        print('🆕 No existing user found, creating new anonymous user...');
        // First time user - create anonymous account
        final userCredential = await _auth.signInAnonymously();
        print('✅ Created new anonymous user: ${userCredential.user?.uid}');
        print('📱 Provider: ${userCredential.user?.providerData}');
      } else {
        // Returning user - session persisted
        print('✅ Existing user found: ${_auth.currentUser?.uid}');
        print('📱 Is Anonymous: ${_auth.currentUser?.isAnonymous}');
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Exception: ${e.code} - ${e.message}');
      if (e.code == 'operation-not-allowed') {
        print('');
        print('⚠️  IMPORTANT: Anonymous Authentication is NOT ENABLED!');
        print('📝 Please enable it in Firebase Console:');
        print('   1. Go to: https://console.firebase.google.com/');
        print('   2. Select your project');
        print('   3. Click "Authentication" → "Sign-in method"');
        print('   4. Enable "Anonymous" provider');
        print('   5. Restart the app');
        print('');
      }
      throw AuthException('Failed to initialize authentication: ${e.code}', e);
    } catch (e) {
      print('❌ Auth initialization error: $e');
      print('📱 Error type: ${e.runtimeType}');
      // Handle offline scenario - app should still work
      throw AuthException('Failed to initialize authentication', e);
    }
  }

  /// Prepare for future social login upgrade
  /// This method will be expanded when implementing social logins
  Future<bool> upgradeToSocialAccount(AuthCredential credential) async {
    try {
      if (_auth.currentUser == null) {
        throw AuthException('No anonymous user to upgrade', null);
      }

      // Link anonymous account with social credential
      final userCredential = await _auth.currentUser!.linkWithCredential(credential);

      print('Account upgraded successfully: ${userCredential.user?.email}');
      return true;

    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        // Handle account already exists scenario
        print('This social account is already in use');
        // TODO: Implement merge strategy or user choice
      }
      print('Upgrade failed: ${e.message}');
      return false;
    }
  }

  /// Sign out (for future use)
  Future<void> signOut() async {
    await _auth.signOut();
    // After sign out, immediately create new anonymous session
    await initialize();
  }
}

class AuthException implements Exception {
  final String message;
  final dynamic originalError;

  AuthException(this.message, this.originalError);

  @override
  String toString() => 'AuthException: $message';
}

// Riverpod Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});