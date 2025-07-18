import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static final FirebaseStorage storage = FirebaseStorage.instance;
  
  // Collections
  static const String usersCollection = 'users';
  static const String postsCollection = 'posts';
  static const String commentsCollection = 'comments';
  static const String adoptionsCollection = 'adoptions';
  static const String conversationsCollection = 'conversations';
  static const String messagesCollection = 'messages';
  static const String typingCollection = 'typing';
  static const String notificationsCollection = 'notifications'; // EKLENDİ

  // Auth Methods
  static Future<UserCredential> signUp(String email, String password) async {
    return await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
  
  static Future<UserCredential> signIn(String email, String password) async {
    return await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
  
  static Future<void> signOut() async {
    await auth.signOut();
  }
  
  static User? getCurrentUser() {
    return auth.currentUser;
  }
}