import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class LiveLocation {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<Position>? _positionStreamSubscription;


  Future<void> startLocationUpdates() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not logged in.");
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          throw Exception("Location permission denied.");
        }
      }

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      ).listen((Position position) async {
        try {
          await _firestore.collection('driver_accounts').doc(user.uid).update({
            'location': {
              'latitude': position.latitude,
              'longitude': position.longitude,
              'locationTimestamp': FieldValue.serverTimestamp(),
            },
          });
          print("Updated location: ${position.latitude}, ${position.longitude}");
        } catch (e) {
          print("Error updating Firestore with location: $e");
        }
      });
    } catch (e) {
      print("Error starting location updates: $e");
    }
  }

  void stopLocationUpdates() {
    if (_positionStreamSubscription != null) {
      _positionStreamSubscription!.cancel();
      _positionStreamSubscription = null;
      print("Location updates stopped.");
    }
  }
}
