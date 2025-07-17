import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class AuthRepository {
  static Future<UserModel?> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final userCredential = await FirebaseService.signUp(email, password);
      final user = userCredential.user;
      
      if (user != null) {
        final userModel = UserModel(
          uid: user.uid,
          email: email,
          username: username,
        );
        
        await FirebaseService.firestore
            .collection(FirebaseService.usersCollection)
            .doc(user.uid)
            .set(userModel.toJson());
            
        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }
  
  static Future<UserModel?> signIn(String email, String password) async {
    try {
      final userCredential = await FirebaseService.signIn(email, password);
      final user = userCredential.user;
      
      if (user != null) {
        final doc = await FirebaseService.firestore
            .collection(FirebaseService.usersCollection)
            .doc(user.uid)
            .get();
            
        if (doc.exists && doc.data() != null) {
          return UserModel.fromJson(doc.data()!);
        } else {
          // Eğer Firestore'da kullanıcı yoksa, geçici bir model döndür
          return UserModel(
            uid: user.uid,
            email: email,
            username: email.split('@')[0],
          );
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }
  
  static Future<void> signOut() async {
    await FirebaseService.signOut();
  }
}