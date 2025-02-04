import 'package:flutter/material.dart';
import 'package:food_delivery_22091d/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_page.dart';

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String phone = '';
  String email = '';
  String password = '';
  String oldPassword = '';
  String newPassword = '';
  String error = '';
  bool isLoading = true;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _getUserData();
    }
  }

  Future<void> _getUserData() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('driver_accounts')
          .doc(currentUser!.uid)
          .get();

      if (snapshot.exists) {
        setState(() {
          name = snapshot['name'] ?? '';
          phone = snapshot['phoneNumber'] ?? '';
          email = snapshot['email'] ?? '';
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'User data not found';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error fetching user data: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      try {

        if (oldPassword.isNotEmpty) {
          AuthCredential credential = EmailAuthProvider.credential(
            email: currentUser!.email!,
            password: oldPassword,
          );

          await currentUser!.reauthenticateWithCredential(credential);
        }


        if (email != currentUser?.email) {
          await currentUser!.updateEmail(email);
        }


        if (newPassword.isNotEmpty) {
          await currentUser!.updatePassword(newPassword);
        }


        await FirebaseFirestore.instance.collection('driver_accounts').doc(currentUser!.uid).update({
          'name': name,
          'phoneNumber': phone,
          'email': email,
        });


        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully')));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } catch (e) {
        setState(() {
          error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Profile'),
          backgroundColor: Colors.blue,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                SizedBox(height: 20.0),
                TextFormField(
                  initialValue: name,
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Enter your name' : null,
                  onChanged: (val) => setState(() => name = val),
                ),
                SizedBox(height: 20.0),
                TextFormField(
                  initialValue: phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Enter your phone number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Enter your phone number' : null,
                  onChanged: (val) => setState(() => phone = val),
                ),
                SizedBox(height: 20.0),
                TextFormField(
                  initialValue: email,
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Enter an email' : null,
                  onChanged: (val) => setState(() => email = val),
                ),
                SizedBox(height: 20.0),
                TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Enter your old password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Enter your old password' : null,
                  onChanged: (val) => setState(() => oldPassword = val),
                ),
                SizedBox(height: 20.0),
                TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Enter new password (leave empty to keep current)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => setState(() => newPassword = val),
                ),
                SizedBox(height: 20.0),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Update Profile'),
                  onPressed: _updateProfile,
                ),
                SizedBox(height: 20.0),

                Text(
                  error,
                  style: TextStyle(color: Colors.red, fontSize: 14.0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
