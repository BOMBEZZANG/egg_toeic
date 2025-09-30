// lib/core/services/social_auth_service.dart
// TO BE IMPLEMENTED IN PHASE 2

import 'package:egg_toeic/core/services/auth_service.dart';

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