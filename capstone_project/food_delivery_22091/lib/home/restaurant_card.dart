import 'package:flutter/material.dart';

class RestaurantCard extends StatelessWidget {
  final String name;
  final String image;
  final String description;
  final String address;
  final String deliveryTime;

  const RestaurantCard({
    required this.name,
    required this.image,
    required this.description,
    required this.address,
    required this.deliveryTime,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              image,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  "$description",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                Text(
                  "$address",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                Text(
                  "$deliveryTime",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
