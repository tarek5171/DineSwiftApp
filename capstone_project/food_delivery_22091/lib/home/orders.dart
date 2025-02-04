import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:food_delivery_22091/services/etaService.dart';
import 'tracking.dart';

class OrdersPage extends StatefulWidget {
  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late double longLTD;
  late double longLGD;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<List<Map<String, dynamic>>> _ordersStream;
  String _currentTab = 'active';
  final String _googleMapsApiKey = 'AIzaSyAF5wS2S_ToE1tHlO58YuRy39lj9wvKhTI';

  @override
  void initState() {
    super.initState();
    _loadUserOrders();
  }


  void _loadUserOrders() {
    final user = _auth.currentUser;
    if (user != null) {
      final userId = user.uid;

      _ordersStream = FirebaseFirestore.instance
          .collection('orders')
          .where('uid', isEqualTo: userId)
          .snapshots()
          .map((querySnapshot) {
        return querySnapshot.docs.map((doc) {
          return {
            'orderId': doc.id,
            'timestamp': doc['timestamp'],
            'status': doc['status'],
            'totalPrice': doc['totalPrice'],
            'items': List<Map<String, dynamic>>.from(doc['items']),
            'addressId': doc['addressId'],
            'driverId': doc['driverId'],
            'driverStatus': doc['driverStatus'],
            'restaurantId': doc['restaurantId'],
          };
        }).toList();
      });
    }
  }

  Future<String?> _fetchETA(String driverId, String addressId) async {
    try {
      final driverSnapshot = await FirebaseFirestore.instance
          .collection('driver_accounts')
          .doc(driverId)
          .get();

      if (!driverSnapshot.exists) {
        return 'Driver location unavailable';
      }

      final driverLocation = driverSnapshot['location'];
      final driverLat = driverLocation['latitude'];
      final driverLng = driverLocation['longitude'];



      final addressSnapshot = await FirebaseFirestore.instance
          .collection('addresses')
          .doc(addressId)
          .get();

      if (!addressSnapshot.exists) {
        return 'Address location unavailable';
      }

      final addressLocation = addressSnapshot['location'];
      final addressLat = addressLocation['latitude'];
      final addressLng = addressLocation['longitude'];

      final driverLatLng = LatLng(driverLat, driverLng);
      final addressLatLng = LatLng(addressLat, addressLng);

      final etaService = ETAService();
      final etaData = await etaService.getETAAndRoute(
        driverLocation: driverLatLng,
        userLocation: addressLatLng,
      );

      if (etaData != null) {
        return etaData['eta'];
      }
    } catch (e) {
      print('Error fetching ETA: $e');
    }
    return 'ETA unavailable';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Orders'),
      ),
      body: Column(
        children: [
          Container(
            color: Color(0xFFA5D6A7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _currentTab = 'active';
                    });
                  },
                  child: Text(
                    'Active Orders',
                    style: TextStyle(
                      color: _currentTab == 'active' ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _currentTab = 'completed';
                    });
                  },
                  child: Text(
                    'Completed Orders',
                    style: TextStyle(
                      color: _currentTab == 'completed' ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _ordersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No orders available.'));
                }

                List<Map<String, dynamic>> orders = snapshot.data!;

                orders = orders.where((order) {
                  final status = order['status'];
                  return _currentTab == 'completed'
                      ? (status == 'completed' || status == 'canceled')
                      : (status != 'completed' && status != 'canceled');
                }).toList();

                if (orders.isEmpty) {
                  return Center(
                    child: Text(
                      _currentTab == 'completed'
                          ? 'No completed or canceled orders.'
                          : 'No active orders.',
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final restaurantId = order['restaurantId'];
                    final addressId = order['addressId'];
                    final driverId = order['driverId'];
                    final orderStatus = order['status'];

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('restaurants')
                          .doc(restaurantId)
                          .get(),
                      builder: (context, restaurantSnapshot) {
                        if (!restaurantSnapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          );
                        }

                        final restaurantData = restaurantSnapshot.data!;
                        final restaurantName = restaurantData['name'] ?? 'Unknown Restaurant';
                        final restaurantLogo = restaurantData['logo'] ?? 'https://via.placeholder.com/150';

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('addresses')
                              .doc(addressId)
                              .get(),
                          builder: (context, addressSnapshot) {
                            if (!addressSnapshot.hasData) {
                              return const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              );
                            }

                            final addressData = addressSnapshot.data!;
                            final addressName = addressData['addressName'] ?? 'Unknown Address';
                            final city = addressData['city'] ?? 'Unknown City';

                            return Card(
                              margin: EdgeInsets.all(8),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundImage: NetworkImage(restaurantLogo),
                                          radius: 24,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          restaurantName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Order ID: ${order['orderId']}',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text('Status: $orderStatus'),
                                    Text('Total Price: \$${order['totalPrice']}'),
                                    Text('Address: $addressName, $city'),
                                    SizedBox(height: 10),


                                    if (driverId != "not selected")
                                      FutureBuilder<DocumentSnapshot>(
                                        future: FirebaseFirestore.instance
                                            .collection('driver_accounts')
                                            .doc(driverId)
                                            .get(),
                                        builder: (context, driverSnapshot) {
                                          if (!driverSnapshot.hasData) {
                                            return Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: CircularProgressIndicator(),
                                            );
                                          }

                                          final driverData = driverSnapshot.data!;
                                          final driverName = driverData['name'] ?? 'Not Available';
                                          final driverPhoneNumber = driverData['phoneNumber'] ?? 'Not Available';

                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Driver: $driverName'),
                                              Text('Phone: $driverPhoneNumber'),
                                              SizedBox(height: 10),
                                            ],
                                          );
                                        },
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

                                    if (orderStatus != 'completed' && orderStatus != 'canceled')
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (orderStatus == 'out for delivery')
                                            FutureBuilder<String?>(
                                              future: _fetchETA(driverId, addressId),
                                              builder: (context, etaSnapshot) {
                                                final eta = etaSnapshot.data ?? 'Calculating...';

                                                return Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text('ETA: $eta'),
                                                    SizedBox(height: 10),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        final addressLat = addressData['location']['latitude'];
                                                        final addressLng = addressData['location']['longitude'];

                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) => DriverLiveLocationPage(
                                                              driverId: driverId,
                                                              addressId: addressId,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      child: Text('Track Order'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            )
                                          else
                                            Text(
                                              'Tracking unavailable',
                                              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                                            ),
                                        ],
                                      ),

                                  ],
                                ),
                              ),
                            );


                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
