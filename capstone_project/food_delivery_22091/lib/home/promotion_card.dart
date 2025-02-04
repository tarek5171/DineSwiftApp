import 'package:flutter/material.dart';

class PromotionCard extends StatelessWidget {
  final String title;
  final String discount;
  final String image;

  const PromotionCard({
    required this.title,
    required this.discount,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              image,
              height: 100,
              width: 150,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            discount,
            style: TextStyle(fontSize: 14, color: Colors.red),
          ),
        ],
      ),
    );
  }
}
