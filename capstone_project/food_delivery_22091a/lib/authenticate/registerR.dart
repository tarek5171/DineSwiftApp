import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_delivery_22091a/services/auth.dart';
import 'package:flutter/material.dart';

class RegisterR extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<RegisterR> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  String error = '';
  String successMessage = '';

  // Text field states
  String email = '';
  String password = '';
  String confirmPassword = '';
  String name = '';
  String phone = '';
  String adminEmail = ''; // Admin email
  String adminPassword = ''; // Admin password

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
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
                // Name field
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                  val == null || val.isEmpty ? 'Enter your name' : null,
                  onChanged: (val) {
                    setState(() => name = val);
                  },
                ),
                SizedBox(height: 20.0),
                // Phone field
                TextFormField(
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Enter your phone number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                  val == null || val.isEmpty ? 'Enter your phone number' : null,
                  onChanged: (val) {
                    setState(() => phone = val);
                  },
                ),
                SizedBox(height: 20.0),
                // Email field
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
                // Password field
                TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                  val != null && val.length < 6
                      ? 'Enter a password 6+ chars long'
                      : null,
                  onChanged: (val) {
                    setState(() => password = val);
                  },
                ),
                SizedBox(height: 20.0),
                // Confirm Password field
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
                // Admin email field
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Enter admin email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                  val == null || val.isEmpty ? 'Enter admin email' : null,
                  onChanged: (val) {
                    setState(() => adminEmail = val);
                  },
                ),
                SizedBox(height: 20.0),
                // Admin password field
                TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Enter admin password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                  val == null || val.isEmpty ? 'Enter admin password' : null,
                  onChanged: (val) {
                    setState(() => adminPassword = val);
                  },
                ),
                SizedBox(height: 20.0),
                // Register Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600], // Button color
                    foregroundColor: Colors.white, // Text color
                  ),
                  child: Text('Register'),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // Perform registration
                      dynamic result = await _auth.registerRestaurantsWithEmailAndPassword(
                        email,
                        password,
                        name,
                        phone,
                      );
                      if (result == null) {
                        setState(() {
                          error = 'Registration failed. Please try again.';
                        });
                      } else {
                        // Registration successful, fetch the current logged-in user
                        User? currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser != null) {
                          print('Current logged-in user: ${currentUser.email}');
                          setState(() {
                            successMessage = 'Registration successful! Welcome ${currentUser.email}.';
                            error = ''; // Clear any previous error
                          });
                        }

                        // Sign out and log in as admin
                        await _auth.signOut();
                        await _auth.signInWithEmailAndPassword(adminEmail, adminPassword);

                        Navigator.pop(context); // Go back to Sign In screen
                      }
                    }
                  },
                ),
                SizedBox(height: 20.0),
                // Error message display
                Text(
                  error,
                  style: TextStyle(color: Colors.red, fontSize: 14.0),
                ),
                // Success message display
                if (successMessage.isNotEmpty)
                  Text(
                    successMessage,
                    style: TextStyle(color: Colors.green, fontSize: 14.0),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
