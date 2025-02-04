import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_delivery_22091r/home/test.dart';

class OrdersPage extends StatefulWidget {
  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Map<String, String?> selectedDrivers = {};
  Map<String, String?> selectedDriverIds = {};
  Map<String, String> driverStatuses = {};


  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const radius = 6371;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radius * c;
  }


  double _degToRad(double deg) {
    return deg * (pi / 180);
  }


  Future<List<Map<String, dynamic>>> getDriverLocationsAndDistances() async {
    final restaurantSnapshot = await FirebaseFirestore.instance
        .collection('restaurants')
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .limit(1)
        .get();

    final restaurantData = restaurantSnapshot.docs.first.data();
    final restaurantLatitude = restaurantData['location']['latitude'];
    final restaurantLongitude = restaurantData['location']['longitude'];

    if (restaurantLatitude == null || restaurantLongitude == null) {
      return [];
    }


    final driverSnapshot = await FirebaseFirestore.instance
        .collection('driver_accounts')
        .where('availability', isEqualTo: 'available')
        .where('status', isEqualTo: 'accepted')
        .get();

    final drivers = driverSnapshot.docs;
    List<Map<String, dynamic>> driverWithDistances = [];

    final currentTime = DateTime.now().millisecondsSinceEpoch;

    for (var driver in drivers) {
      final driverLatitude = driver['location']['latitude'];
      final driverLongitude = driver['location']['longitude'];
      final driverTimestamp = driver['location']['locationTimestamp'];

      if (driverLatitude != null && driverLongitude != null && driverTimestamp != null) {

        final driverDateTime = driverTimestamp.toDate();


        final driverTimestampMillis = driverDateTime.millisecondsSinceEpoch;

        final driverDistance = calculateDistance(
          restaurantLatitude,
          restaurantLongitude,
          driverLatitude,
          driverLongitude,
        );


        final timestampDifference = (currentTime - driverTimestampMillis) / 1000;


        if (driverDistance < 10 && timestampDifference <= 10) {
          driverWithDistances.add({
            'name': driver['name'],
            'id': driver['uid'],
            'distance': driverDistance,
            'phoneNumber': driver['phoneNumber'] ?? 'N/A',
          });
        }
      }
    }

    return driverWithDistances;
  }


  Future<void> updateOrderWithDriver(String orderId, String driverId) async {
    await checkAndCreateDriverFields(orderId);

    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'driverId': driverId,
        'driverStatus': 'awaiting response',
      });
    } catch (e) {
      print("Error updating order with driver: $e");
    }
  }


  Future<void> checkAndCreateDriverFields(String orderId) async {
    final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);
    final orderSnapshot = await orderRef.get();

    if (orderSnapshot.exists) {
      final orderData = orderSnapshot.data();


      if (orderData?['driverId'] == null) {
        await orderRef.update({'driverId': ''});
      }
      if (orderData?['driverStatus'] == null) {
        await orderRef.update({'driverStatus': 'not selected'});
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Orders")),
        body: Center(child: Text('Please log in to view orders')),
      );
    }

    final currentUserId = user.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text("Orders"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Canceled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildOrderList(currentUserId, ['awaiting confirmation', 'under preparation', 'out for delivery','confirmed']),
          buildOrderList(currentUserId, ['completed']),
          buildOrderList(currentUserId, ['canceled']),
        ],
      ),
    );
  }


  Widget buildOrderList(String currentUserId, List<String> statuses) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('restaurantId', isEqualTo: currentUserId)
          .where('status', whereIn: statuses)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data!.docs;

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final orderId = order.id;
            final timestamp = order['timestamp']?.toDate() ?? DateTime.now();
            final totalPrice = order['totalPrice'] ?? 0.0;
            final currentStatus = order['status'] ?? 'awaiting confirmation';
            final addressId = order['addressId'] ?? null;
            final userId = order['uid'] ?? 'Unknown';
            final driverId = order['driverId'] ?? null;
            final driverStatus = order['driverStatus'] ?? 'not selected';

            final formattedDate = "${timestamp.day}/${timestamp.month}/${timestamp.year}";


            Future<void> updateOrderStatus(String newStatus) async {
              await FirebaseFirestore.instance
                  .collection('orders')
                  .doc(orderId)
                  .update({'status': newStatus});
            }


            Future<void> assignDriverToOrder(String driverId) async {
              await FirebaseFirestore.instance
                  .collection('orders')
                  .doc(orderId)
                  .update({'driverId': driverId});
            }

            return Card(
              margin: EdgeInsets.all(8.0),
              child: Column(
                children: [
                  ListTile(
                    title: Text('Order ID: $orderId'),
                    subtitle: Text('Date: $formattedDate - Total: \$${totalPrice.toStringAsFixed(2)}'),
                  ),
                  ListTile(
                    title: Text('Status: $currentStatus'),
                    trailing: DropdownButton<String>(
                      value: currentStatus,
                      onChanged: (String? newStatus) {
                        if (newStatus != null) {
                          updateOrderStatus(newStatus);
                        }
                      },
                      items: <String>[
                        'awaiting confirmation',
                        'confirmed',
                        'under preparation',
                        'out for delivery',
                        'completed',
                        'canceled'
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                  // ExpansionTile to show order items
                  ExpansionTile(
                    title: Text("Items"),
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
                                  return Center(child: CircularProgressIndicator());
                                }

                                final itemData = itemSnapshot.data!;
                                final itemName = itemData['name'] ?? 'Unknown Item';
                                final originalPrice = itemData['price'] ?? 0.0;
                                final discount = itemData['discount'] ?? 0.0;

                                // Calculate the discounted price
                                final discountedPrice = originalPrice * (1 - (discount / 100));

                                return ListTile(
                                  title: Text(itemName),
                                  subtitle: Row(
                                    children: [
                                      // Original price with strikethrough
                                      Text(
                                        '\$${originalPrice.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          decoration: TextDecoration.lineThrough,
                                          color: Colors.red,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      // Discounted price
                                      Text(
                                        '\$${discountedPrice.toStringAsFixed(2)}',
                                        style: TextStyle(color: Colors.green),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Show quantity of item ordered
                                      Text('x$quantity'),
                                      SizedBox(width: 8),

                                      IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () async {

                                          try {
                                            await updateOrderItem(orderId, itemId, discountedPrice);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('$itemName updated successfully')),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Failed to update $itemName: $e')),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          }).toList(),

                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () {

                                final currentUserId = FirebaseAuth.instance.currentUser?.uid;

                                if (currentUserId != null) {

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ItemsPage(
                                        restaurantId: currentUserId,
                                        orderId: orderId,
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('User is not logged in.')),
                                  );
                                }
                              },
                              icon: Icon(Icons.add),
                              label: Text('Add Item'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),


                  // Fetch user info and display name and phone
                  FutureBuilder<DocumentSnapshot>(

                    builder: (context, userSnapshot) {
                      

                     
                      final userName = order['name'] ?? 'Unknown User';
                      final userPhoneNumber = order['phoneNumber'] ?? 'N/A';

                      return ListTile(
                        title: Text('Customer: $userName'),
                        subtitle: Text('Phone: $userPhoneNumber'),
                      );
                    }, future: null,
                  ),
                  // Fetch and display address info
                  ListTile(
                    title: Text('Address: ${order['address']['addressName'] ?? 'Unknown Address Name'}'),
                    subtitle: Text(
                      'Street: ${order['address']['street'] ?? 'Unknown Street'}, '
                          'Building: ${order['address']['building'] ?? 'Unknown Building'}, '
                          'City: ${order['address']['city'] ?? 'Unknown City'}\n'
                          'Latitude: ${order['address']['location']?['latitude'] ?? 'N/A'} | '
                          'Longitude: ${order['address']['location']?['longitude'] ?? 'N/A'}',
                    ),
                  ),

                  if (driverId != null) ...[
                    FutureBuilder<String>(
                      future: getDriverNameAndPhone(driverId),
                      builder: (context, driverSnapshot) {
                        if (!driverSnapshot.hasData) {
                          return ListTile(
                            title: Text('not selected'),
                            subtitle: Text('Status: $driverStatus'),
                          );
                        }

                        final driverData = driverSnapshot.data!;
                        final driverName = driverData.split(',')[0];
                        final driverPhoneNumber = driverData.split(',')[1];

                        return ListTile(
                          title: Text('Driver: $driverName'),
                          subtitle: Text('Phone: $driverPhoneNumber\nStatus: $driverStatus'),
                        );
                      },
                    ),
                  ],
                  // Dropdown menu for selecting drivers
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: getDriverLocationsAndDistances(),
                    builder: (context, driverSnapshot) {
                      if (!driverSnapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final driverData = driverSnapshot.data!;


                      if (driverData.isEmpty) {
                        return ListTile(
                          title: Text('No available drivers nearby'),
                        );
                      }

                      return ListTile(
                        title: Text('Select Driver'),
                        trailing: DropdownButton<String>(
                          hint: Text('Select Driver'),
                          value: selectedDrivers[orderId],
                          items: driverData.map<DropdownMenuItem<String>>((driver) {
                            final driverName = driver['name'];
                            final driverDistance = driver['distance'].toStringAsFixed(2);
                            return DropdownMenuItem<String>(
                              value: driverName,
                              child: Row(
                                children: [
                                  Text(driverName),
                                  SizedBox(width: 8),
                                  Text(
                                    '$driverDistance km',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newDriver) {
                            setState(() {
                              selectedDrivers[orderId] = newDriver;
                              selectedDriverIds[orderId] = driverData.firstWhere((driver) => driver['name'] == newDriver)['id']; // Get the selected driver's ID
                              driverStatuses[orderId] = "awaiting response";
                            });
                            if (selectedDriverIds[orderId] != null) {
                              assignDriverToOrder(selectedDriverIds[orderId]!);
                              updateOrderWithDriver(orderId, selectedDriverIds[orderId]!);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<String> getDriverNameAndPhone(String driverId) async {
    final driverDoc = await FirebaseFirestore.instance.collection('driver_accounts').doc(driverId).get();
    final driverName = driverDoc['name'] ?? 'Unknown Driver';
    final driverPhoneNumber = driverDoc['phoneNumber'] ?? 'N/A';
    return '$driverName,$driverPhoneNumber';



  }

  Future<void> updateOrderItem(String orderDocumentId, String itemId, double itemPrice) async {
    try {

      final orderDocRef = FirebaseFirestore.instance.collection('orders').doc(orderDocumentId);


      final orderSnapshot = await orderDocRef.get();
      if (!orderSnapshot.exists) {
        throw Exception('Order not found');
      }


      Map<String, dynamic> orderData = orderSnapshot.data()!;
      List<dynamic> items = orderData['items'] ?? [];
      double totalPrice = orderData['totalPrice'] ?? 0.0;


      int itemIndex = items.indexWhere((item) => item['itemId'] == itemId);

      if (itemIndex == -1) {
        throw Exception('Item not found in the order');
      }


      Map<String, dynamic> item = items[itemIndex];
      int currentQuantity = item['quantity'];

      if (currentQuantity > 1) {

        items[itemIndex]['quantity'] = currentQuantity - 1;
        totalPrice -= itemPrice;
      } else {

        items.removeAt(itemIndex);
        totalPrice -= itemPrice;
      }

      if (totalPrice < 0) {
        totalPrice = 0.0;
      }

      await orderDocRef.update({
        'items': items,
        'totalPrice': totalPrice,
      });

      print('Updated order $orderDocumentId: Item $itemId processed successfully.');
    } catch (e) {
      print('Error updating order item: $e');
      rethrow;
    }
  }

}
