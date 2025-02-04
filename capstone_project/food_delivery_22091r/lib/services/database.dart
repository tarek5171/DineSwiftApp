import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Add dummy restaurant data to Firestore.
  Future<void> addDummyData() async {
    try {
      // Define a list of dummy restaurant data
      List<Map<String, dynamic>> dummyRestaurants = [
        {
          "name": "Pizza Paradise",
          "deliveryTime": "30-40 mins",
          "rating": 4.5,
          "picture": "https://example.com/pizza.jpg",
          "promotion": "20% off on all orders!",
        },
        {
          "name": "Burger Haven",
          "deliveryTime": "20-30 mins",
          "rating": 4.2,
          "picture": "https://example.com/burger.jpg",
          "promotion": "Buy 1 Get 1 Free!",
        },
        {
          "name": "Sushi Delight",
          "deliveryTime": "40-50 mins",
          "rating": 4.8,
          "picture": "https://example.com/sushi.jpg",
          "promotion": "Free dessert with orders over \$50",
        },
        {
          "name": "Taco Fiesta",
          "deliveryTime": "25-35 mins",
          "rating": 4.3,
          "picture": "https://example.com/taco.jpg",
          "promotion": "15% off for new customers",
        },
        {
          "name": "Vegan Bites",
          "deliveryTime": "30-40 mins",
          "rating": 4.6,
          "picture": "https://example.com/vegan.jpg",
          "promotion": "Free delivery on weekends",
        },
      ];

      // Write each dummy restaurant data to the 'restaurants' collection
      for (var restaurant in dummyRestaurants) {
        await _db.collection('restaurants').add(restaurant);
      }

      print("Dummy data added successfully!");
    } catch (e) {
      print("Error adding dummy data: $e");
    }
  }

  /// Fetch restaurant data from Firestore.
  Future<List<Map<String, dynamic>>> fetchRestaurants() async {
    try {
      // Fetch restaurants collection from Firestore
      QuerySnapshot snapshot = await _db.collection('restaurants').get();

      // Convert query snapshot to list of maps
      return snapshot.docs.map((doc) {
        return {
          "name": doc['name'],
          "deliveryTime": doc['deliveryTime'],
          "rating": doc['rating'],
          "picture": doc['picture'],
          "promotion": doc['promotion'],
        };
      }).toList();
    } catch (e) {
      print("Error fetching restaurants: $e");
      return [];
    }
  }
}
