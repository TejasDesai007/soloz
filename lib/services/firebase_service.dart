import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static Future<void> initializeFirebase() async {
    try {
      // Only initialize if not already initialized
      if (Firebase.apps.isEmpty) {
        // For web platform
        if (kIsWeb) {
          await Firebase.initializeApp(
            options: const FirebaseOptions(
              apiKey: "AIzaSyCshe7-O9huJq5soG-3mWFlRrPxCjvopH0",
              authDomain: "soloz-2139c.firebaseapp.com",
              projectId: "soloz-2139c",
              storageBucket: "soloz-2139c.appspot.com",
              messagingSenderId: "394401398680",
              appId: "1:394401398680:android:dc8732b67ff50d7370b5ed",
            ),
          );
        } else {
          // For mobile platforms - will use google-services.json for Android
          // or GoogleService-Info.plist for iOS
          await Firebase.initializeApp();
        }

        // Initialize Firestore settings to avoid timestamp issues
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );

        debugPrint('Firebase initialized successfully');
      } else {
        debugPrint('Firebase was already initialized');
      }
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
      rethrow;
    }
  }

  // Authentication methods
  static Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }

  static Future<UserCredential> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      return await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  // Firestore methods
  static Future<void> createUserProfile(
      String userId, Map<String, dynamic> data) async {
    try {
      debugPrint('Creating user profile for $userId with data: $data');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set(data, SetOptions(merge: true));
      debugPrint('User profile created successfully');
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      rethrow;
    }
  }

  static Future<DocumentSnapshot> getUserProfile(String userId) async {
    try {
      return await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      rethrow;
    }
  }
}
