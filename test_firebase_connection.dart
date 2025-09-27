import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');

    // Test Firestore connection
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('test').limit(1).get();
    print('✅ Firestore connection successful');

  } catch (e) {
    print('❌ Firebase connection failed: $e');
  }
}