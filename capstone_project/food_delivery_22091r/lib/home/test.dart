import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ItemsPage extends StatefulWidget {
  final String restaurantId;
  final String orderId;

  const ItemsPage({required this.restaurantId, required this.orderId});

  @override
  _ItemsPageState createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  late List<String> sections = [];
  late Map<String, List<DocumentSnapshot>> groupedItems = {};
  Map<String, int> itemCounters = {};

  @override
  void initState() {
    super.initState();
    fetchSectionsAndItems();
  }


  Future<void> fetchSectionsAndItems() async {
    try {

      DocumentSnapshot restaurantSnapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantId)
          .get();


      List<String> fetchedSections =
      List<String>.from(restaurantSnapshot['sections'] ?? []);
      setState(() {
        sections = fetchedSections;
      });


      QuerySnapshot itemsSnapshot = await FirebaseFirestore.instance
          .collection('items')
          .where('userId', isEqualTo: widget.restaurantId)
          .where('isDeleted', isEqualTo: 'no')
          .get();


      Map<String, List<DocumentSnapshot>> tempGroupedItems = {};
      for (var item in itemsSnapshot.docs) {
        String section = item['section'] ?? 'Uncategorized';
        if (tempGroupedItems[section] == null) {
          tempGroupedItems[section] = [];
        }
        tempGroupedItems[section]!.add(item);


        setState(() {
          itemCounters[item.id] = 0;
        });
      }

      setState(() {
        groupedItems = tempGroupedItems;
      });
    } catch (e) {
      print('Error fetching sections or items: $e');
    }
  }




  Future<void> addItemToOrder(
      String orderDocumentId, String itemId, double itemPrice, double discount) async {
    try {

      final orderDocRef = FirebaseFirestore.instance.collection('orders').doc(orderDocumentId);


      final orderSnapshot = await orderDocRef.get();
      if (!orderSnapshot.exists) {
        throw Exception('Order not found');
      }


      List<dynamic> items = orderSnapshot.data()?['items'] ?? [];
      double totalPrice = orderSnapshot.data()?['totalPrice'] ?? 0.0;


      double discountedPrice = itemPrice * (1 - (discount / 100));

      int itemIndex = items.indexWhere((item) => item['itemId'] == itemId);

      if (itemIndex != -1) {

        items[itemIndex]['quantity'] = items[itemIndex]['quantity'] + 1;


        totalPrice += discountedPrice;
      } else {

        items.add({
          'itemId': itemId,
          'quantity': 1,
        });


        totalPrice += discountedPrice;
      }


      await orderDocRef.update({
        'items': items,
        'totalPrice': totalPrice,
      });

      print('Item $itemId successfully added to order $orderDocumentId.');
    } catch (e) {
      print('Error adding item to order: $e');
      rethrow;
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Items'),
        backgroundColor: Colors.blueGrey,
      ),
      body: sections.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: sections.length,
        itemBuilder: (context, sectionIndex) {
          String section = sections[sectionIndex];


          List<DocumentSnapshot> sectionItems =
              groupedItems[section] ?? [];

          return ExpansionTile(
            title: Text(
              section,
              style: const TextStyle(fontSize: 18),
            ),
            children: sectionItems.isEmpty
                ? [
              const ListTile(
                title: Text('No items available for this section.'),
              )
            ]
                : sectionItems
                .map(
                  (item) => Card(
                margin: const EdgeInsets.symmetric(
                    vertical: 8.0, horizontal: 16.0),
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
                              style: const TextStyle(
                                  fontSize: 18),
                            ),
                            Text(
                              item['description'],
                              style: const TextStyle(
                                  color: Colors.grey),
                            ),
                            Text(
                              '\$${item['price']}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),

                            if (item['discount'] != null &&
                                item['discount'] > 0)
                              Text(
                                'Discount: ${item['discount']}%',
                                style: const TextStyle(
                                    color: Colors.green),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Row(
                            children: [

                              IconButton(
                                onPressed: itemCounters[
                                item.id]! >
                                    0
                                    ? () {
                                  setState(() {
                                    itemCounters[item.id] =
                                        itemCounters[item.id]! - 1;
                                  });
                                }
                                    : null,
                                icon: const Icon(Icons.remove),
                                color: itemCounters[item.id]! > 0
                                    ? Colors.red
                                    : Colors.grey,
                              ),

                              Text(
                                '${itemCounters[item.id]}',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),

                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    itemCounters[item.id] =
                                        itemCounters[item.id]! + 1;
                                  });


                                  addItemToOrder(
                                      widget.orderId,
                                      item.id,
                                      item['price'],
                                      item['discount']
                                  );
                                },
                                icon: const Icon(Icons.add),
                                color: Colors.green,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
                .toList(),
          );
        },
      ),
    );
  }
}
