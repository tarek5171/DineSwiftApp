import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({Key? key}) : super(key: key);

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchOrders() {

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in.");
    }

    return FirebaseFirestore.instance
        .collection('orders')
        .where('driverId', isEqualTo: user.uid)
        .where('driverStatus', isEqualTo: 'awaiting response')
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs);
  }

  Future<void> updateDriverStatus(String orderDocId, String status) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderDocId).update({
        'driverStatus': status,
      });
    } catch (e) {
      debugPrint('Error updating driver status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders Requests'),
      ),
      body: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        stream: fetchOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isEmpty) {
            return const Center(child: Text('No orders found.'));
          } else if (snapshot.hasData) {
            final orders = snapshot.data!;

            return ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index].data();
                final orderDocId = orders[index].id;

                final restaurantId = order['restaurantId'];
                final userId = order['uid'];

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('restaurants')
                      .doc(restaurantId)
                      .get(),
                  builder: (context, restaurantSnapshot) {
                    if (!restaurantSnapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final restaurantData = restaurantSnapshot.data!;
                    final restaurantName = restaurantData['name'] ?? 'Unknown Restaurant';
                    final restaurantAddress = restaurantData['address'] ?? 'Unknown Address';

                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text('Order ID: $orderDocId'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Restaurant: $restaurantName'),
                                Text('Restaurant Address: $restaurantAddress'),
                                Text('User Name: ${order['name'] ?? 'N/A'}'),
                                Text('User Phone Number: ${order['phoneNumber'] ?? 'N/A'}'),
                                Text('Status: ${order['status'] ?? 'N/A'}'),
                                Text('Total Price: \$${order['totalPrice'] ?? 0}'),
                                Text('Driver Status: ${order['driverStatus'] ?? 'N/A'}'),
                              ],
                            ),
                            trailing: Text(order['timestamp'] != null
                                ? (order['timestamp'] as Timestamp).toDate().toString()
                                : 'N/A'),
                          ),
                          ListTile(
                            title: Text('User Address: ${order['address']['addressName'] ?? 'Unknown Address Name'}'),
                            subtitle: Text(
                              'Street: ${order['address']['street'] ?? 'Unknown Street'}, '
                                  'Building: ${order['address']['building'] ?? 'Unknown Building'}, '
                                  'City: ${order['address']['city'] ?? 'Unknown City'}\n'
                                  'Latitude: ${order['address']['location']?['latitude'] ?? 'N/A'} | '
                                  'Longitude: ${order['address']['location']?['longitude'] ?? 'N/A'}',
                            ),
                          ),
                          ExpansionTile(
                            title: const Text("Items"),
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...order['items'].map<Widget>((item) {
                                    final itemId = item['itemId'] ?? 'No Item ID';
                                    final quantity = item['quantity'] ?? 0;

                                    return FutureBuilder<DocumentSnapshot>(
                                      future: FirebaseFirestore.instance
                                          .collection('items')
                                          .doc(itemId)
                                          .get(),
                                      builder: (context, itemSnapshot) {
                                        if (!itemSnapshot.hasData) {
                                          return const CircularProgressIndicator();
                                        }

                                        final itemData = itemSnapshot.data!;
                                        final itemName = itemData['name'] ?? 'Unknown Item';
                                        final originalPrice = itemData['price'] ?? 0.0;
                                        final discount = itemData['discount'] ?? 0.0;


                                        final discountedPrice = originalPrice * (1 - (discount / 100));

                                        return ListTile(
                                          title: Text(itemName),
                                          subtitle: Row(
                                            children: [

                                              Text(
                                                '\$${originalPrice.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  decoration: TextDecoration.lineThrough,
                                                  color: Colors.red,
                                                ),
                                              ),
                                              const SizedBox(width: 8),

                                              Text(
                                                '\$${discountedPrice.toStringAsFixed(2)}',
                                                style: const TextStyle(color: Colors.green),
                                              ),
                                            ],
                                          ),
                                          trailing: Text('x$quantity'),
                                        );
                                      },
                                    );
                                  }).toList(),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  await updateDriverStatus(orderDocId, 'accepted');
                                  (context as Element).markNeedsBuild();
                                },
                                child: const Text('Accept', style: TextStyle(color: Colors.green)),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await updateDriverStatus(orderDocId, 'rejected');
                                  (context as Element).markNeedsBuild();
                                },
                                child: const Text('Reject', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );

                  },
                );
              },
            );
          } else {
            return const Center(child: Text('Something went wrong.'));
          }
        },
      ),
    );
  }
}
