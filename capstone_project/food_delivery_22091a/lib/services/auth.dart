import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_delivery_22091a/models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;


  UserModel? _userFromFirebaseUser(User? user) {
    return user != null ? UserModel(uid: user.uid) : null;
  }

  Stream<UserModel?> get user {
    return _auth.authStateChanges()
        .map((User? user) => _userFromFirebaseUser(user));
  }


  Future<UserModel?> signInAnon() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      User? user = result.user;
      return _userFromFirebaseUser(user);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {

      QuerySnapshot<Map<String, dynamic>> userSnapshot = await _db
          .collection('admin_accounts')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        await _auth.signOut();
        print('User not found in admin_accounts database.');
        return null;
      }

      QueryDocumentSnapshot<Map<String, dynamic>> userDoc = userSnapshot.docs.first;

      String status = userDoc.data()['status'] ?? '';
      if (status != 'accepted') {
        await _auth.signOut();
        print('User status is not accepted.');
        return null;
      }


      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        return _userFromFirebaseUser(user);
      }

      return null;
    } catch (e) {
      print('Error signing in: ${e.toString()}');
      return null;
    }
  }


  Future<UserModel?> registerWithEmailAndPassword(String email, String password, String name, String phoneNumber) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user != null) {
        await _db.collection('admin_accounts').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'phoneNumber': phoneNumber,
          'createdAt': FieldValue.serverTimestamp(),
          'status' : 'pending',
        });
      }

      return _userFromFirebaseUser(user);
    } catch (error) {
      print(error.toString());
      return null;
    }
  }
  Future<UserModel?> registerRestaurantsWithEmailAndPassword(String email, String password, String name, String phoneNumber) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user != null) {
        await _db.collection('restaurants_accounts').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'phoneNumber': phoneNumber,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return _userFromFirebaseUser(user);
    } catch (error) {
      print(error.toString());
      return null;
    }
  }

  Future<UserModel?> registerDriverWithEmailAndPassword(String email, String password, String name, String phoneNumber) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user != null) {
        await _db.collection('admin_accounts').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'phoneNumber': phoneNumber,
          'createdAt': FieldValue.serverTimestamp(),
          'status':'pending',
        });
      }

      return _userFromFirebaseUser(user);
    } catch (error) {
      print(error.toString());
      return null;
    }
  }



  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('User signed out successfully');
    } catch (error) {
      print('Error during sign-out: ${error.toString()}');
    }
  }
}
