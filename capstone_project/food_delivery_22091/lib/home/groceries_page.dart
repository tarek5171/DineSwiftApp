import 'package:flutter/material.dart';
import 'restaurant_card.dart';

class GroceriesPage extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> places;

  const GroceriesPage({required this.title, required this.places});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Icon(Icons.search),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              enabled: false,
              decoration: InputDecoration(
                hintText: 'Search for groceries or markets',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: places.length,
              itemBuilder: (context, index) {
                final place = places[index];
                return RestaurantCard(
                  name: place["name"]!,
                  image: place["image"] ?? "https://via.placeholder.com/150",
                  description: place["description"] ?? "No description available",
                  address: place["address"] ?? "No address available",
                  deliveryTime: "10 min",
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
