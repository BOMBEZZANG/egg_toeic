import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Diagnostic utility to check Firebase setup
class FirebaseDiagnostics {
  static Future<void> runDiagnostics() async {
    print('');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔍 FIREBASE DIAGNOSTICS');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');

    // Check Firebase initialization
    try {
      final app = Firebase.app();
      print('✅ Firebase App initialized');
      print('   Project ID: ${app.options.projectId}');
      print('   App ID: ${app.options.appId}');
      print('   API Key: ${app.options.apiKey.substring(0, 10)}...');
    } catch (e) {
      print('❌ Firebase NOT initialized: $e');
      print('');
      return;
    }

    // Check Firebase Auth
    try {
      final auth = FirebaseAuth.instance;
      print('');
      print('✅ Firebase Auth instance available');
      print('   Current user: ${auth.currentUser?.uid ?? "NULL"}');
      print('   Is Anonymous: ${auth.currentUser?.isAnonymous ?? "N/A"}');
      print('   Provider: ${auth.currentUser?.providerData ?? "N/A"}');
    } catch (e) {
      print('❌ Firebase Auth error: $e');
    }

    // Try to sign in anonymously
    print('');
    print('🧪 Testing Anonymous Sign-in...');
    try {
      final auth = FirebaseAuth.instance;

      // Check if already signed in
      if (auth.currentUser != null) {
        print('   ℹ️  Already signed in as: ${auth.currentUser!.uid}');
      } else {
        print('   🔄 Attempting anonymous sign-in...');
        final userCredential = await auth.signInAnonymously();
        print('   ✅ SUCCESS! Created user: ${userCredential.user?.uid}');
        print('   📱 Is Anonymous: ${userCredential.user?.isAnonymous}');
      }
    } on FirebaseAuthException catch (e) {
      print('   ❌ FirebaseAuthException:');
      print('      Code: ${e.code}');
      print('      Message: ${e.message}');
      print('');

      if (e.code == 'operation-not-allowed') {
        print('   ⚠️  ISSUE FOUND: Anonymous Authentication NOT Enabled');
        print('   📝 Fix: Enable in Firebase Console');
        print('      1. Go to: https://console.firebase.google.com/');
        print('      2. Select your project');
        print('      3. Authentication → Sign-in method');
        print('      4. Enable "Anonymous" provider');
      }
    } catch (e) {
      print('   ❌ Unexpected error: $e');
      print('   📱 Error type: ${e.runtimeType}');
    }

    print('');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔍 DIAGNOSTICS COMPLETE');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');
  }
}