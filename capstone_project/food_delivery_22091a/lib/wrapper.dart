import 'package:flutter/material.dart';
import 'package:food_delivery_22091a/authenticate/authenticate.dart';
import 'home/home_page.dart';
import 'package:food_delivery_22091a/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class Wrapper extends StatelessWidget {
  Future<DocumentSnapshot?> _fetchRestaurantData(String uid, {int retries = 3}) async {
    DocumentSnapshot? userDoc;
    for (int i = 0; i < retries; i++) {
      try {
        userDoc = await FirebaseFirestore.instance
            .collection('admin_accounts')
            .doc(uid)
            .get();

        if (userDoc.exists) {
          return userDoc;
        }
      } catch (e) {

        print('Error fetching user data: $e');
      }


      await Future.delayed(Duration(seconds: 1));
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);

    if (user == null) {
      return Authenticate();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (authSnapshot.data == null) {
          return Authenticate();
        }

        return FutureBuilder<DocumentSnapshot?>(
          future: _fetchRestaurantData(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || snapshot.data == null) {

              return _StatusPage(
                message: 'An error occurred. your account may have been disabled or awaiting confirmation. please try again later or contact adminstrator.',
                onComplete: () {
                  FirebaseAuth.instance.signOut();
                },
              );
            }

            if (snapshot.data!.exists) {
              Map<String, dynamic> userData = snapshot.data!.data() as Map<String, dynamic>;
              String status = userData['status'] ?? 'rejected';

              if (status == 'pending' || !(status == 'accepted') ) {
                return _StatusPage(
                  message: 'Your account is awaiting administrator approval.',
                  onComplete: () {
                    FirebaseAuth.instance.signOut();
                  },
                );
              }

              if (status == 'rejected') {
                return _StatusPage(
                  message: 'Your account has been rejected by the administrator.',
                  onComplete: () {
                    FirebaseAuth.instance.signOut();
                  },
                );
              }

              if (status == 'accepted') {
                return AdminHomePage();
              }

              return AdminHomePage();
            }

            return _StatusPage(
              message: 'User data could not be found. Logging out...',
              onComplete: () {
                FirebaseAuth.instance.signOut();
              },
            );
          },
        );
      },
    );
  }
}

class _StatusPage extends StatelessWidget {
  final String message;
  final VoidCallback onComplete;

  const _StatusPage({
    required this.message,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 5), onComplete);

    return Scaffold(
      body: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
