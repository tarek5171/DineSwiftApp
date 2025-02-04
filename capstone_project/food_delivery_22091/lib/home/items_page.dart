import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_delivery_22091/home/cart.dart';

class ItemsPage extends StatefulWidget {
  final String restaurantId;

  const ItemsPage({required this.restaurantId});

  @override
  _ItemsPageState createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  late List<String> sections = [];
  late Map<String, List<DocumentSnapshot>> groupedItems = {};
  Map<String, int> itemCounters = {};
  bool _isProcessing = false;

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
          .get();

      User? user = FirebaseAuth.instance.currentUser;
      List<dynamic> userCartItems = [];
      if (user != null) {
        DocumentReference userDocRef =
        FirebaseFirestore.instance.collection('user_accounts').doc(user.uid);
        DocumentSnapshot userDoc = await userDocRef.get();

        if (userDoc.exists) {
          Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

          if (userData == null || !userData.containsKey('items')) {
            await userDocRef.set({'items': []}, SetOptions(merge: true));
          } else {
            userCartItems = List<dynamic>.from(userData['items']);
          }
        } else {
          await userDocRef.set({'items': []});
        }
      }

      Map<String, List<DocumentSnapshot>> tempGroupedItems = {};
      for (var item in itemsSnapshot.docs) {
        String section = item['section'] ?? 'Uncategorized';
        if (tempGroupedItems[section] == null) {
          tempGroupedItems[section] = [];
        }
        tempGroupedItems[section]!.add(item);

        int itemCount = 0;
        for (var cartItem in userCartItems) {
          if (cartItem['itemId'] == item.id) {
            itemCount = cartItem['count'];
            break;
          }
        }

        setState(() {
          itemCounters[item.id] = itemCount;
        });
      }

      if (user != null) {
        DocumentReference userDocRef =
        FirebaseFirestore.instance.collection('user_accounts').doc(user.uid);

        List<dynamic> updatedItems = List.from(userCartItems);
        for (var item in itemsSnapshot.docs) {
          bool existsInCart = userCartItems.any((cartItem) => cartItem['itemId'] == item.id);

          if (!existsInCart && itemCounters[item.id]! > 0) {
            updatedItems.add({'itemId': item.id, 'count': itemCounters[item.id]!});
          }
        }

        await userDocRef.update({'items': updatedItems});
      }

      setState(() {
        groupedItems = tempGroupedItems;
      });
    } catch (e) {
      print('Error fetching sections or items: $e');
    }
  }


  void _onCartPressed() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartPage()),
    );


    fetchSectionsAndItems();
  }


  Future<void> removeItemFromUserAccount(String itemId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;

      try {
        DocumentReference userAccountRef = FirebaseFirestore.instance
            .collection('user_accounts')
            .doc(uid);


        DocumentSnapshot userDoc = await userAccountRef.get();

        List<dynamic> items = [];

        if (userDoc.exists) {
          var data = userDoc.data();
          if (data != null && data is Map<String, dynamic> && data.containsKey('items')) {
            items = List<dynamic>.from(data['items']);
          }
        }

        bool itemFound = false;
        for (var item in items) {
          if (item['itemId'] == itemId && item['count'] > 0) {
            if (item['count'] > 1) {
              item['count'] = item['count'] - 1;
            } else {
              items.remove(item);
            }
            itemFound = true;
            break;
          }
        }

        if (itemFound) {
          await userAccountRef.set({
            'items': items,
          }, SetOptions(merge: true));
        } else {
          print("Item not found or count is already 0");
        }
      } catch (e) {
        print("Error removing item from user account: $e");
      }
    }
  }

  Future<void> _addItemToUserAccount(String itemId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;

      try {
        DocumentReference userAccountRef = FirebaseFirestore.instance
            .collection('user_accounts')
            .doc(uid);

        DocumentSnapshot userDoc = await userAccountRef.get();

        List<dynamic> items = [];

        if (userDoc.exists) {
          var data = userDoc.data();
          if (data != null && data is Map<String, dynamic> && data.containsKey('items')) {
            items = List<dynamic>.from(data['items']);
          }
        }

        bool itemExists = false;
        for (var item in items) {
          if (item['itemId'] == itemId) {
            item['count'] = item['count'] + 1;
            itemExists = true;
            break;
          }
        }

        if (!itemExists) {
          items.add({
            'itemId': itemId,
            'count': 1,
          });
        }

        await userAccountRef.set({
          'items': items,
        }, SetOptions(merge: true));

      } catch (e) {
        print("Error adding item to user account: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Items'),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: _onCartPressed,
          ),
        ],
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
                .where((item) => item['hide'] != 'yes' && item['isDeleted'] != 'yes')
                .map(
                  (item) => Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'],
                              style: const TextStyle(fontSize: 18),
                            ),
                            Text(
                              item['description'],
                              style: const TextStyle(color: Colors.grey),
                            ),
                            Row(
                              children: [
                                if (item['discount'] != null && item['discount'] > 0)
                                  Text(
                                    '\$${item['price']}',
                                    style: const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.red,
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Text(
                                  item['discount'] != null && item['discount'] > 0
                                      ? '\$${(item['price'] * (1 - item['discount'] / 100)).toStringAsFixed(2)}'
                                      : '\$${item['price']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            if (item['discount'] != null && item['discount'] > 0)
                              Text(
                                'Discount: ${item['discount']}%',
                                style: const TextStyle(color: Colors.green),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          if (item['availability'] == 'no')
                            const Text(
                              'Currently unavailable',
                              style: TextStyle(color: Colors.red),
                            )
                          else ...[
                            Row(
                              children: [
                                IconButton(
                                  onPressed: itemCounters[item.id]! > 0 && !_isProcessing
                                      ? () async {
                                    setState(() {
                                      _isProcessing = true;
                                    });

                                    try {

                                      setState(() {
                                        itemCounters[item.id] = itemCounters[item.id]! - 1;
                                      });

                                      await removeItemFromUserAccount(item.id);
                                    } catch (e) {
                                      print("Error removing item: $e");
                                    } finally {
                                      setState(() {
                                        _isProcessing = false;
                                      });
                                    }
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
                                      fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  onPressed: item['availability'] != 'no' && !_isProcessing
                                      ? () async {
                                    setState(() {
                                      _isProcessing = true;

                                    });

                                    try {

                                      setState(() {
                                        itemCounters[item.id] = itemCounters[item.id]! + 1;
                                      });


                                      await _addItemToUserAccount(item.id);
                                    } catch (e) {
                                      print("Error adding item: $e");
                                    } finally {
                                      setState(() {
                                        _isProcessing = false;
                                      });
                                    }
                                  }
                                      : null,
                                  icon: const Icon(Icons.add),
                                  color: Colors.green,
                                ),
                              ],
                            ),
                          ],
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
