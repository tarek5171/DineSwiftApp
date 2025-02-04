import 'package:flutter/material.dart';
import 'restaurant_card.dart';
import 'category_card.dart';


class RestaurantsPage extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> places;

  const RestaurantsPage({required this.title, required this.places});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
      ),
      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search for restaurants or dishes',
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

          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                CategoryCard(icon: Icons.local_pizza, label: "Pizza"),
                CategoryCard(icon: Icons.fastfood, label: "Burgers"),
                CategoryCard(icon: Icons.ramen_dining, label: "Asian"),
                CategoryCard(icon: Icons.emoji_food_beverage, label: "Drinks"),
                CategoryCard(icon: Icons.cake, label: "Desserts"),
              ],
            ),
          ),
          // Restaurant List
          Expanded(
            child: ListView.builder(
              itemCount: places.length,
              itemBuilder: (context, index) {
                final place = places[index];
                return RestaurantCard(
                  name: place["name"]!,
                  image: place["picture"]!,
                  rating: place["rating"]!,
                  deliveryTime: place["deliveryTime"]!,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


