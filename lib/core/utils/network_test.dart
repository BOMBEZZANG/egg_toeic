import 'dart:io';

/// Simple network connectivity test
class NetworkTest {
  static Future<void> checkConnectivity() async {
    print('');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🌐 NETWORK CONNECTIVITY TEST');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');

    // Test 1: Check general internet connectivity
    print('📡 Test 1: Can we reach Google?');
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('   ✅ YES - Google is reachable');
        print('   📍 IP: ${result[0].address}');
      }
    } on SocketException catch (e) {
      print('   ❌ NO - Cannot reach Google');
      print('   📱 Error: ${e.message}');
      print('   ⚠️  Device has no internet connection!');
      print('');
      print('   📝 Please check:');
      print('      - WiFi is connected');
      print('      - Mobile data is enabled');
      print('      - Airplane mode is OFF');
      print('');
      return;
    }

    // Test 2: Check Firebase connectivity
    print('');
    print('🔥 Test 2: Can we reach Firebase?');
    try {
      final result = await InternetAddress.lookup('firebase.google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('   ✅ YES - Firebase is reachable');
        print('   📍 IP: ${result[0].address}');
      }
    } on SocketException catch (e) {
      print('   ❌ NO - Cannot reach Firebase');
      print('   📱 Error: ${e.message}');
      print('');
      print('   ⚠️  Firebase servers are blocked or unreachable!');
      print('');
      print('   📝 Possible causes:');
      print('      - Firewall blocking Firebase');
      print('      - Company/school network restrictions');
      print('      - VPN interfering');
      print('      - Regional restrictions');
      print('');
      return;
    }

    // Test 3: Check Auth endpoint
    print('');
    print('🔐 Test 3: Can we reach Firebase Auth?');
    try {
      final result = await InternetAddress.lookup('identitytoolkit.googleapis.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('   ✅ YES - Firebase Auth endpoint is reachable');
        print('   📍 IP: ${result[0].address}');
        print('');
        print('   ℹ️  Network is OK, but authentication still failed.');
        print('   📝 This might be a temporary issue. Try:');
        print('      1. Wait 30 seconds and try again');
        print('      2. Restart the app');
        print('      3. Check Firebase Console status');
      }
    } on SocketException catch (e) {
      print('   ❌ NO - Cannot reach Firebase Auth');
      print('   📱 Error: ${e.message}');
    }

    print('');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🌐 NETWORK TEST COMPLETE');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');
  }
}