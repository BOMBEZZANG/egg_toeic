# Firebase Auth Implementation - Development Request

## Project Overview

**App Name:** Egg TOEIC  
**Type:** TOEIC Part 5 Practice App with Gamification  
**Current Status:** MVP ready for initial launch (no existing users)  
**Tech Stack:** Flutter, Firebase (Firestore, Analytics), Hive, Riverpod

## Current Architecture

The app currently uses a device-based anonymous user system:
- `AnonymousUserService` generates device-specific IDs
- Data is stored locally in Hive
- Some analytics data goes to Firestore
- No user authentication system exists

## Implementation Requirements

### Primary Goal
Implement Firebase Anonymous Authentication as the foundation for user management, preparing for future social login integration (Google, Apple, Kakao).

### Key Requirements

1. **Automatic Anonymous Authentication**
   - Users should be automatically signed in anonymously when launching the app
   - No login screens or user interaction required
   - Seamless experience - users won't know they're being authenticated

2. **Data Persistence**
   - Replace device-based IDs with Firebase Auth UIDs
   - Store all user data in Firestore (with Hive as local cache)
   - Ensure data persists across app updates
   - Handle offline scenarios gracefully

3. **Future-Proof Architecture**
   - Design with social login upgrade path in mind
   - Use `linkWithCredential` pattern for account upgrades
   - Maintain same UID when upgrading from anonymous to social

## Technical Specifications

### 1. Dependencies to Add

```yaml
# pubspec.yaml
dependencies:
  firebase_auth: ^4.15.0  # Check for latest version
  
  # For future social logins (add when needed)
  # google_sign_in: ^6.1.5
  # sign_in_with_apple: ^5.0.0
  # kakao_flutter_sdk_user: ^1.6.1
```

### 2. Create AuthService

Create new file: `lib/core/services/auth_service.dart`

```dart
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
      if (_auth.currentUser == null) {
        // First time user - create anonymous account
        final userCredential = await _auth.signInAnonymously();
        print('Created new anonymous user: ${userCredential.user?.uid}');
      } else {
        // Returning user - session persisted
        print('Existing user found: ${_auth.currentUser?.uid}');
      }
    } catch (e) {
      print('Auth initialization error: $e');
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
```

### 3. Update Main App Initialization

Modify `lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:egg_toeic/core/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Hive (existing)
  await Hive.initFlutter();
  
  // Initialize Authentication - NEW
  try {
    await AuthService().initialize();
    print('✅ Authentication initialized');
  } catch (e) {
    print('⚠️ Auth initialization failed, continuing with offline mode');
    // App should still work offline
  }
  
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}
```

### 4. Update Repository Layer

Modify `lib/data/repositories/user_data_repository.dart`:

```dart
// BEFORE:
// import 'package:egg_toeic/core/services/anonymous_user_service.dart';

// AFTER:
import 'package:egg_toeic/core/services/auth_service.dart';

class UserDataRepositoryImpl implements UserDataRepository {
  final AuthService _authService = AuthService();
  
  // CHANGE: User ID source
  String get _userId {
    // BEFORE: return AnonymousUserService.getAnonymousUserId();
    // AFTER:
    return _authService.currentUserId;
  }
  
  // Update all Firestore paths to use Firebase Auth UID
  Future<void> saveUserProgress(UserProgress progress) async {
    // Save to Firestore with Firebase Auth UID
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)  // Now using Firebase Auth UID
        .collection('progress')
        .doc('current')
        .set(progress.toJson());
    
    // Also save to Hive for offline support (existing logic)
    await _hiveBox.put('progress', progress.toJson());
  }
  
  // Similar updates for all other methods...
}
```

### 5. Update Analytics Repository

Modify `lib/data/repositories/analytics_repository.dart`:

```dart
// Use AuthService instead of AnonymousUserService
class AnalyticsRepository {
  final AuthService _authService = AuthService();
  
  Future<void> submitAnswer(...) async {
    final userId = _authService.currentUserId;  // Firebase Auth UID
    
    // Rest of the implementation remains the same
    await _analyticsService.submitUserAnswer(
      userId: userId,
      // ...
    );
  }
}
```

### 6. Firestore Security Rules

Update Firebase Console > Firestore > Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to read/write their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && 
                           request.auth.uid == userId;
    }
    
    // Allow anonymous users to read/write their data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && 
                           request.auth.token.firebase.sign_in_provider == 'anonymous' &&
                           request.auth.uid == userId;
    }
  }
}
```

### 7. Future Social Login Preparation

Create placeholder structure for future implementation:

```dart
// lib/core/services/social_auth_service.dart
// TO BE IMPLEMENTED IN PHASE 2

class SocialAuthService {
  final AuthService _authService = AuthService();
  
  // Google Sign In (Phase 2)
  Future<bool> signInWithGoogle() async {
    // TODO: Implement Google Sign In
    // 1. Get Google credential
    // 2. Call _authService.upgradeToSocialAccount(credential)
    throw UnimplementedError('Google Sign In coming soon');
  }
  
  // Apple Sign In (Phase 2)
  Future<bool> signInWithApple() async {
    // TODO: Implement Apple Sign In
    throw UnimplementedError('Apple Sign In coming soon');
  }
  
  // Kakao Sign In (Phase 2)
  Future<bool> signInWithKakao() async {
    // TODO: Implement Kakao Sign In
    // Note: Requires Cloud Functions for custom token
    throw UnimplementedError('Kakao Sign In coming soon');
  }
}
```

## Testing Requirements

### 1. Unit Tests

```dart
// test/services/auth_service_test.dart
void main() {
  group('AuthService', () {
    test('should create anonymous user on first launch', () async {
      // Test anonymous user creation
    });
    
    test('should persist user across app restarts', () async {
      // Test UID persistence
    });
    
    test('should handle offline scenario', () async {
      // Test offline functionality
    });
  });
}
```

### 2. Integration Test Scenarios

- [ ] Fresh install → Anonymous account created automatically
- [ ] App restart → Same UID maintained
- [ ] Offline launch → App functions without crash
- [ ] Online return → Data syncs to Firestore
- [ ] Data persistence → Progress saved and retrieved correctly

## Implementation Checklist

- [ ] Add firebase_auth dependency
- [ ] Create AuthService class
- [ ] Update main.dart initialization
- [ ] Modify UserDataRepository to use AuthService
- [ ] Update AnalyticsRepository
- [ ] Update Firestore security rules
- [ ] Remove AnonymousUserService dependencies
- [ ] Test anonymous authentication flow
- [ ] Test data persistence
- [ ] Test offline scenarios
- [ ] Add error handling and logging
- [ ] Update any affected providers

## Migration Strategy

Since this is pre-launch with no existing users:
1. No data migration needed
2. Remove all references to device-based IDs
3. Start fresh with Firebase Auth UIDs

## Future Enhancements (Phase 2)

When adding social logins:

1. **UI Changes**
   - Add optional login button in settings
   - Show account status (anonymous vs social)
   - Add account upgrade prompts

2. **Backend Requirements**
   - Cloud Functions for Kakao custom tokens
   - User data merge strategies
   - Account conflict resolution

3. **Implementation Order**
   - Google Sign In (easiest)
   - Apple Sign In (iOS required)
   - Kakao Sign In (most complex, needs backend)

## Success Criteria

1. **Seamless UX**: Users can use the app without any authentication friction
2. **Data Persistence**: User progress persists across app updates
3. **Future Ready**: Architecture supports easy social login addition
4. **Offline Support**: App works offline, syncs when online
5. **Same UID**: Anonymous UID remains constant for upgrades

## Important Notes

- Firebase Auth automatically handles session persistence
- UIDs remain constant when upgrading anonymous to social accounts
- Always check `currentUser` before accessing UID
- Handle offline scenarios gracefully - app should never crash due to auth issues
- Test on both iOS and Android platforms

## Questions or Clarifications Needed

Please confirm:
1. Should we implement any analytics events for auth state changes?
2. Any specific error messages or user feedback needed?
3. Preferred logging framework for debugging?
4. Any specific requirements for offline data limits?

## Timeline Estimate

- **Day 1**: Core implementation (4-6 hours)
- **Day 2**: Repository updates and testing (4-6 hours)
- **Day 3**: Edge cases and polish (2-4 hours)

Total: 2-3 days for complete implementation and testing

---

**Priority**: High - This is a foundational change that blocks future features  
**Risk**: Low - No existing users to migrate  
**Impact**: High - Enables data persistence and future monetization