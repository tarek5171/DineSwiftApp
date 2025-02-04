import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:food_delivery_22091a/services/auth.dart';
import 'package:food_delivery_22091a/wrapper.dart';
import 'package:provider/provider.dart';

import 'models/user.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}
Future main() async{
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb){
    await Firebase.initializeApp(options: FirebaseOptions(apiKey: "AIzaSyATaqOzyMpy1EERQFdMyNkmoZwaSAw3D88", appId: "1:537511362891:web:96c4684bf9804ffba0e8ce", messagingSenderId: "537511362891", projectId: "food-delivery-22091"));
  }

  HttpOverrides.global = MyHttpOverrides();

  await Firebase.initializeApp();
  runApp( MyApp());
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

