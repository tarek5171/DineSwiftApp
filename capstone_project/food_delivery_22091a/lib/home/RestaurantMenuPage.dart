import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantMenuPage extends StatelessWidget {
  final String restaurantId;

  RestaurantMenuPage({required this.restaurantId});

  Stream<Map<String, List<DocumentSnapshot>>> fetchItemsGroupedBySection() {
    DocumentReference restaurantRef =
    FirebaseFirestore.instance.collection('restaurants').doc(restaurantId);

    return restaurantRef.snapshots().asyncMap((restaurantDoc) async {
      if (!restaurantDoc.exists) return {};

      List<dynamic> sections = restaurantDoc['sections'] ?? [];
      Map<String, List<DocumentSnapshot>> groupedItems = {};

      for (String section in sections) {
        QuerySnapshot sectionItems = await FirebaseFirestore.instance
            .collection('items')
            .where('section', isEqualTo: section)
            .where('userId', isEqualTo: restaurantDoc['userId'])
            .get();

        groupedItems[section] = sectionItems.docs;
      }

      return groupedItems;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
      ),
      body: StreamBuilder<Map<String, List<DocumentSnapshot>>>(
        stream: fetchItemsGroupedBySection(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No items available.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          Map<String, List<DocumentSnapshot>> groupedItems = snapshot.data!;

          return ListView.builder(
            itemCount: groupedItems.keys.length,
            itemBuilder: (context, index) {
              String sectionName = groupedItems.keys.elementAt(index);
              List<DocumentSnapshot> sectionItems = groupedItems[sectionName]!;

              return ExpansionTile(
                title: Text(
                  sectionName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                children: sectionItems.isEmpty
                    ? [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No items in this section.',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ]
                    : sectionItems.map((item) {
                  final double price = item['price'];
                  final double discount = item['discount'] ?? 0;
                  final double discountedPrice =
                      price * (1 - (discount / 100));
                  final int discountPercentage = discount.round();

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16.0,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16.0),
                      title: Row(
                        children: [
                          Image.network(
                            item['picture'],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'],
                                  style: const TextStyle(fontSize: 18),
                                ),
                                Text(
                                  item['description'],
                                  style: const TextStyle(
                                      color: Colors.grey),
                                ),
                                const SizedBox(height: 8),

                                if (discount > 0)
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '\$${price.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          decoration: TextDecoration
                                              .lineThrough,
                                        ),
                                      ),
                                      Text(
                                        '\$${discountedPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        '$discountPercentage% off!',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Text(
                                    '\$${price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
