import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:food_delivery_22091d/models/user.dart'; // Assuming this file exists
import 'package:food_delivery_22091d/loading.dart';
import 'package:food_delivery_22091d/authenticate/register.dart'; // Assuming this file exists

class SignIn extends StatefulWidget {
  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  String error = '';
  bool loading = false;

  // Text field states
  String email = '';
  String password = '';

  // Function to show the forgot password dialog
  Future<void> _showForgotPasswordDialog(BuildContext context) async {
    String _forgotPasswordEmail = '';

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Forgot Password'),
          content: TextField(
            onChanged: (value) {
              _forgotPasswordEmail = value;
            },
            decoration: InputDecoration(hintText: 'Enter your email'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  setState(() => loading = true);
                  await _auth.sendPasswordResetEmail(email: _forgotPasswordEmail);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Password reset email sent!'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to send email: $e'),
                    ),
                  );
                } finally {
                  setState(() => loading = false);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Send Email'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);

    if (loading) {
      return Loading();
    }

    if (user != null) {
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('driver_accounts').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Loading(); // Show loading while fetching user data
          }

          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text('Error fetching user data. Please try again.'),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data!.exists) {
            Map<String, dynamic> userData = snapshot.data!.data() as Map<String, dynamic>;
            bool isBlocked = userData['isBlocked'] ?? false;

            if (isBlocked) {
              return Scaffold(
                body: Center(
                  child: Text(
                    'Your account is blocked. Please contact support.',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              );
            }
          }

          return Scaffold(
            body: Center(
              child: Text(
                'User account not found. Please register.',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          );
        },
      );
    }

    // If user is not logged in, show the sign-in form
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign In'),
        elevation: 0,
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
                // Email field
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Enter an email' : null,
                  onChanged: (val) {
                    setState(() => email = val);
                  },
                ),
                SizedBox(height: 20.0),
                // Password field
                TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val != null && val.length < 6
                      ? 'Enter a password 6+ chars long'
                      : null,
                  onChanged: (val) {
                    setState(() => password = val);
                  },
                ),
                SizedBox(height: 20.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Sign In Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Sign In'),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => loading = true);

                          try {
                            await _auth.signInWithEmailAndPassword(email: email, password: password);
                          } catch (e) {
                            setState(() {
                              error = 'Sign in failed. Please check your credentials or account status.';
                              loading = false;
                            });
                          }
                        }
                      },
                    ),
                    // Forgot Password Button
                    TextButton(
                      onPressed: () => _showForgotPasswordDialog(context),
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.0),
                // Error message display
                Text(
                  error,
                  style: TextStyle(color: Colors.red, fontSize: 14.0),
                ),
                SizedBox(height: 20.0),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Register(),
                      ),
                    );
                  },
                  child: Text(
                    'Don\'t have an account? Register here',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
