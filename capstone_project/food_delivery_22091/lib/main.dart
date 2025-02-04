import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'wrapper.dart';
import 'package:provider/provider.dart';
import 'package:food_delivery_22091/services/auth.dart';
import 'package:food_delivery_22091/models/user.dart';
import 'package:food_delivery_22091/services/database.dart';
import 'dart:io';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  HttpOverrides.global = MyHttpOverrides();

  final DatabaseService _databaseService = DatabaseService();


  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamProvider<UserModel?>.value(
      value: AuthService().user,
      initialData: null,
      child: MaterialApp(
        home: Wrapper(),
      ),
    );
  }
}
