import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double radius = 6371;
    double latDiff = _degToRad(lat2 - lat1);
    double lonDiff = _degToRad(lon2 - lon1);
    double a = sin(latDiff / 2) * sin(latDiff / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
            sin(lonDiff / 2) * sin(lonDiff / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radius * c;
  }


  double _degToRad(double deg) {
    return deg * (pi / 180);
  }

  Future<List<Map<String, dynamic>>> fetchRestaurants() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return [];
      }

      String userId = currentUser.uid;

      DocumentSnapshot userAccountSnapshot = await _db.collection('user_accounts').doc(userId).get();

      if (!userAccountSnapshot.exists) {
        return [];
      }

      var userAccountData = userAccountSnapshot.data() as Map<String, dynamic>;
      String addressDocId = userAccountData["address"];

      DocumentSnapshot addressSnapshot = await _db.collection('addresses').doc(addressDocId).get();

      if (!addressSnapshot.exists) {
        return [];
      }

      var addressData = addressSnapshot.data() as Map<String, dynamic>;
      double userLat = addressData["location"]["latitude"];
      double userLon = addressData["location"]["longitude"];


      QuerySnapshot restaurantSnapshot = await _db.collection('restaurants').get();
      List<Map<String, dynamic>> restaurantList = [];

      for (var restaurantDoc in restaurantSnapshot.docs) {
        var restaurantData = restaurantDoc.data() as Map<String, dynamic>;
        String userIdFromRestaurant = restaurantData["userId"] ?? "Unknown User";


        QuerySnapshot accountSnapshot = await _db
            .collection('restaurants_accounts')
            .where('uid', isEqualTo: userIdFromRestaurant)
            .get();

        if (accountSnapshot.docs.isNotEmpty) {
          var accountData = accountSnapshot.docs.first.data() as Map<String, dynamic>;

          String? activityStatus = accountData["activity"];
          if (activityStatus != null && activityStatus == "Active") {
            if (accountData["status"] == "approved") {
              double restaurantLat = restaurantData["location"]["latitude"];
              double restaurantLon = restaurantData["location"]["longitude"];
              double distance = _calculateDistance(userLat, userLon, restaurantLat, restaurantLon);

              if (distance <= 10) {
                restaurantList.add({
                  "name": restaurantData["name"] ?? "No Name",
                  "description": restaurantData["description"] ?? "No Description",
                  "address": restaurantData["address"] ?? "No Address",
                  "logo": restaurantData["logo"] ?? "https://via.placeholder.com/150",
                  "restaurantPicture": restaurantData["restaurantPicture"] ?? "https://via.placeholder.com/150",
                  "deliveryTime": "10 min",
                  "userId": userIdFromRestaurant,
                });
              }
            }
          }
        }
      }

      return restaurantList;
    } catch (e) {
      print('Error fetching restaurants: $e');
      return [];
    }
  }

}
