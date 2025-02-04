import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:food_delivery_22091r/services/auth.dart';
import 'package:food_delivery_22091r/loading.dart';

class Register extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  String error = '';
  bool isLoading = false;


  String name = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  String phoneNumber = '';

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Loading();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Registration Form'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.of(context).pushReplacementNamed('/login'); // Navigate to login screen
            },
          ),
        ],
      ),

      body: Container(
        padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                SizedBox(height: 20.0),

                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                  val == null || val.isEmpty ? 'Enter a name' : null,
                  onChanged: (val) {
                    setState(() => name = val);
                  },
                ),
                SizedBox(height: 20.0),

                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                  val == null || val.isEmpty ? 'Enter an email' : null,
                  onChanged: (val) {
                    setState(() => email = val);
                  },
                ),
                SizedBox(height: 20.0),

                TextFormField(
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Enter your phone number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                  val == null || val.isEmpty ? 'Enter a phone number' : null,
                  onChanged: (val) {
                    setState(() => phoneNumber = val);
                  },
                ),
                SizedBox(height: 20.0),
                TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Enter a password';
                    } else if (val.length < 8) {
                      return 'Password must be at least 8 characters long';
                    } else if (!RegExp(r'[A-Z]').hasMatch(val)) {
                      return 'Password must contain at least one uppercase letter';
                    } else if (!RegExp(r'[a-z]').hasMatch(val)) {
                      return 'Password must contain at least one lowercase letter';
                    } else if (!RegExp(r'[0-9]').hasMatch(val)) {
                      return 'Password must contain at least one number';
                    } else if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(val)) {
                      return 'Password must contain at least one special character';
                    }
                    return null;
                  },
                  onChanged: (val) {
                    setState(() => password = val);
                  },
                ),

                SizedBox(height: 20.0),
                TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Confirm your password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                  val != password ? 'Passwords do not match' : null,
                  onChanged: (val) {
                    setState(() => confirmPassword = val);
                  },
                ),
                SizedBox(height: 20.0),
                // Register Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Register'),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() => isLoading = true);
                      try {
                        dynamic result = await _auth.registerWithEmailAndPassword(
                          email,
                          password,
                          name,
                          phoneNumber,
                        );

                        if (result == null) {
                          setState(() {
                            error = 'Registration failed. Please try again.';
                          });
                        } else {
                          print('Registration successful');
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (e is FirebaseException && e.code == 'permission-denied') {
                          setState(() {
                            error = 'Awaiting admin approval. Please try again later.';
                          });
                        } else {
                          setState(() {
                            error = 'An unexpected error occurred. Please try again.';
                          });
                          print('Error: $e');
                        }
                      } finally {
                        setState(() => isLoading = false);
                      }
                    }
                  },
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
