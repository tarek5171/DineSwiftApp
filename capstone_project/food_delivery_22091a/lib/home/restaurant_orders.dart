import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrdersPage extends StatefulWidget {
  final String restaurantId;

  OrdersPage({required this.restaurantId});

  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
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
        .doc(widget.restaurantId)
        .get();

    final restaurantData = restaurantSnapshot.data();
    final restaurantLatitude = restaurantData?['location']['latitude'];
    final restaurantLongitude = restaurantData?['location']['longitude'];

    if (restaurantLatitude == null || restaurantLongitude == null) {
      return [];
    }


    final driverSnapshot = await FirebaseFirestore.instance
        .collection('driver_accounts')
        .where('availability', isEqualTo: 'available')
        .get();

    final drivers = driverSnapshot.docs;
    List<Map<String, dynamic>> driverWithDistances = [];

    for (var driver in drivers) {
      final driverLatitude = driver['location']['latitude'];
      final driverLongitude = driver['location']['longitude'];

      if (driverLatitude != null && driverLongitude != null) {
        final driverDistance = calculateDistance(
          restaurantLatitude,
          restaurantLongitude,
          driverLatitude,
          driverLongitude,
        );


        if (driverDistance < 10) {
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
      appBar: AppBar(title: Text("Orders")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('restaurantId', isEqualTo: widget.restaurantId)
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
                          'under preperaton',
                          'out for delivery',
                          'completed'
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
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
                                    return CircularProgressIndicator();
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
                                          style: TextStyle(
                                            decoration: TextDecoration.lineThrough,
                                            color: Colors.red,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          '\$${discountedPrice.toStringAsFixed(2)}',
                                          style: TextStyle(color: Colors.green),
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
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('user_accounts')
                          .doc(userId)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }

                        final userData = userSnapshot.data!;
                        final userName = userData['name'] ?? 'Unknown User';
                        final userPhoneNumber = userData['phoneNumber'] ?? 'N/A';

                        return ListTile(
                          title: Text('Customer: $userName'),
                          subtitle: Text('Phone: $userPhoneNumber'),
                        );
                      },
                    ),
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('addresses')
                          .doc(addressId)
                          .get(),
                      builder: (context, addressSnapshot) {
                        if (!addressSnapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }

                        final addressData = addressSnapshot.data!;
                        final addressName = addressData['addressName'] ?? 'Unknown Address Name';
                        final city = addressData['city'] ?? 'Unknown City';
                        final street = addressData['street'] ?? 'Unknown Street';
                        final building = addressData['building'] ?? 'Unknown Building';
                        final location = addressData['location'] ?? {};

                        return ListTile(
                          title: Text('Address: $addressName'),
                          subtitle: Text(
                              'Street: $street, Building: $building, City: $city\nLatitude: ${location['latitude']}, Longitude: ${location['longitude']}'),
                        );
                      },
                    ),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: getDriverLocationsAndDistances(),
                      builder: (context, driverSnapshot) {
                        if (!driverSnapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }

                        final drivers = driverSnapshot.data!;

                        String? selectedDriverId = selectedDriverIds[orderId] ?? driverId;

                        if (selectedDriverId != null && !drivers.any((driver) => driver['id'] == selectedDriverId)) {
                          selectedDriverId = null;
                        }

                        return ListTile(
                          title: Text('Assign a Driver'),
                          trailing: DropdownButton<String>(
                            value: selectedDriverId,
                            onChanged: (String? newDriverId) {
                              if (newDriverId != null) {
                                setState(() {
                                  selectedDriverIds[orderId] = newDriverId;
                                  selectedDrivers[orderId] = drivers
                                      .firstWhere((driver) => driver['id'] == newDriverId)['name'];
                                  driverStatuses[orderId] = 'assigned';
                                });

                                assignDriverToOrder(newDriverId);
                              }
                            },
                            items: drivers.map<DropdownMenuItem<String>>((driver) {
                              return DropdownMenuItem<String>(
                                value: driver['id'],
                                child: Text('${driver['name']} - ${driver['distance'].toStringAsFixed(2)} km'),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    )

                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
