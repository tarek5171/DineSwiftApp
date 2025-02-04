import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'checkout.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Map<String, List<Map<String, dynamic>>> groupedCartItems = {};
  double totalPrice = 0;
  String? userAddressId;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
    fetchUserAddress();
  }


  Future<void> fetchUserAddress() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('user_accounts')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc['address'] != null) {
          setState(() {
            userAddressId = userDoc['address'];
          });
        }
      } catch (e) {
        print("Error fetching user address: $e");
      }
    }
  }

  Future<void> fetchCartItems() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('user_accounts')
            .doc(user.uid)
            .get();


        if (userDoc.exists && userDoc['items'] is List) {
          List<dynamic> itemsArray = userDoc['items'];

          Map<String, List<Map<String, dynamic>>> tempGroupedItems = {};

          for (var item in itemsArray) {
            String itemId = item['itemId'];
            int count = item['count'];

            DocumentSnapshot itemSnapshot = await FirebaseFirestore.instance
                .collection('items')
                .doc(itemId)
                .get();

            if (itemSnapshot.exists) {
              String name = itemSnapshot['name'] ?? 'Unnamed Item';
              double price = itemSnapshot['price']?.toDouble() ?? 0.0;
              double discount = itemSnapshot['discount']?.toDouble() ?? 0.0;
              String description = itemSnapshot['description'] ?? 'No description';
              String picture = itemSnapshot['picture'] ?? '';
              String restaurantid = itemSnapshot['userId'] ?? '';
              double discountedPrice = price - (price * (discount / 100));
              double totalItemPrice = discountedPrice * count;

              setState(() {
                totalPrice += totalItemPrice;
              });

              if (!tempGroupedItems.containsKey(restaurantid)) {
                tempGroupedItems[restaurantid] = [];
              }

              tempGroupedItems[restaurantid]!.add({
                'itemId': itemId,
                'name': name,
                'price': price,
                'discount': discount,
                'description': description,
                'picture': picture,
                'count': count,
                'totalItemPrice': totalItemPrice,
                'restaurantName': await fetchRestaurantName(restaurantid),
              });


              print("Grouped items for restaurant $restaurantid: ${tempGroupedItems[restaurantid]}");
            }
          }

          setState(() {
            groupedCartItems = tempGroupedItems;
          });
        }
      } catch (e) {
        print("Error fetching cart items: $e");
      }
    }
  }

  Future<String> fetchRestaurantName(String restaurantId) async {
    try {
      DocumentSnapshot restaurantSnapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .get();

      if (restaurantSnapshot.exists) {
        return restaurantSnapshot['name'] ?? 'Unknown Restaurant';
      }
    } catch (e) {
      print("Error fetching restaurant name: $e");
    }
    return 'Unknown Restaurant';
  }

  Future<void> updateItemQuantity(String itemId, int newQuantity) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('user_accounts')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc['items'] is List) {
          List<dynamic> itemsArray = userDoc['items'];
          for (var item in itemsArray) {
            if (item['itemId'] == itemId) {
              if (newQuantity == 0) {
                itemsArray.remove(item);
              } else {
                item['count'] = newQuantity;
              }

              await FirebaseFirestore.instance
                  .collection('user_accounts')
                  .doc(user.uid)
                  .update({'items': itemsArray});

              setState(() {
                totalPrice = 0;
                fetchCartItems();
              });
              break;
            }
          }
        }
      } catch (e) {
        print("Error updating item quantity: $e");
      }
    }
  }


  void checkout(String restaurantId) {
    if (userAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an address before checking out."),
        ),
      );
      return;
    }

    List<Map<String, dynamic>> items = groupedCartItems[restaurantId]!;
    double restaurantTotalPrice =
    items.fold(0, (sum, item) => sum + item['totalItemPrice']);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutPage(
          restaurantId: restaurantId,
          items: items,
          totalPrice: restaurantTotalPrice,
          userAddressId: userAddressId!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: Colors.blueGrey,
      ),
      body: groupedCartItems.isEmpty
          ? const Center(child: Text('Your cart is empty.'))
          : ListView.builder(
        itemCount: groupedCartItems.keys.length,
        itemBuilder: (context, index) {
          String restaurantId = groupedCartItems.keys.elementAt(index);
          List<Map<String, dynamic>> items = groupedCartItems[restaurantId]!;

          double restaurantTotalPrice = items.fold(
              0, (sum, item) => sum + item['totalItemPrice']);

          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (items.isNotEmpty)
                      ClipOval(
                        child: Image.network(
                          items[0]['picture'],
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      items[0]['restaurantName'] ?? 'Unknown Restaurant',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '\$${restaurantTotalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => checkout(restaurantId),
                      child: const Text('Checkout'),
                    ),
                  ],
                ),
                ...items.map((item) {
                  double price = item['price'];
                  double discount = item['discount'];
                  double discountedPrice = price - (price * (discount / 100));

                  return ListTile(
                    leading: Image.network(
                      item['picture'],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                    title: Text(
                      item['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Description: ${item['description']}'),
                        Row(
                          children: [
                            if (discount > 0)
                              Text(
                                '\$${price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.red,
                                ),
                              ),
                            const SizedBox(width: 8),

                            Text(
                              discount > 0
                                  ? '\$${discountedPrice.toStringAsFixed(2)}'
                                  : '\$${price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        if (discount > 0)
                          Text(
                            'Discount: ${discount}% OFF',
                            style: const TextStyle(color: Colors.green),
                          ),
                        Text('Quantity: ${item['count']}'),
                        Text(
                          'Total: \$${item['totalItemPrice'].toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, color: Colors.red),
                              onPressed: item['count'] > 0
                                  ? () {
                                updateItemQuantity(item['itemId'], item['count'] - 1);
                              }
                                  : null,
                            ),
                            Text('${item['count']}'),
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.green),
                              onPressed: () {
                                updateItemQuantity(item['itemId'], item['count'] + 1);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        color: Colors.grey.shade200,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Grand Total:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '\$${totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
