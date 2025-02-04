import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchRestaurants() async {
    try {
      QuerySnapshot querySnapshot = await _db.collection('restaurants').get();
      List<Map<String, dynamic>> restaurantList = querySnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;

        // Handle missing fields with fallback values and add the userId
        return {
          "name": data["name"] ?? "No Name",
          "description": data["description"] ?? "No Description",
          "address": data["address"] ?? "No Address",
          "logo": data["logo"] ?? "https://via.placeholder.com/150",
          "restaurantPicture": data["restaurantPicture"] ?? "https://via.placeholder.com/150",
          "deliveryTime": "10 min",  // Provide default value for deliveryTime
          "userId": data["userId"] ?? "Unknown User",  // Add userId field here
        };
      }).toList();

      return restaurantList;
    } catch (e) {
      print('Error fetching restaurants: $e');
      return [];
    }
  }}
