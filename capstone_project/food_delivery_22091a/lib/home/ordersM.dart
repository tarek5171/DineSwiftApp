import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:food_delivery_22091a/services/etaService.dart';
import 'tracking.dart';

class AdminOrdersPage extends StatefulWidget {
  @override
  _AdminOrdersPageState createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  late double longLTD;
  late double longLGD;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<List<Map<String, dynamic>>> _ordersStream;
  String _currentTab = 'active';
  final String _googleMapsApiKey = 'AIzaSyAF5wS2S_ToE1tHlO58YuRy39lj9wvKhTI';

  @override
  void initState() {
    super.initState();
    _loadAllOrders();
  }

  void _loadAllOrders() {
    _ordersStream = FirebaseFirestore.instance
        .collection('orders')
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





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin - Orders'),
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
                TextButton(
                  onPressed: () {
                    setState(() {
                      _currentTab = 'canceled';
                    });
                  },
                  child: Text(
                    'Canceled Orders',
                    style: TextStyle(
                      color: _currentTab == 'canceled' ? Colors.white : Colors.grey,
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
                  if (_currentTab == 'active') {
                    return status != 'completed' && status != 'canceled';
                  }
                  if (_currentTab == 'completed') {
                    return status == 'completed';
                  }
                  return status == 'canceled';
                }).toList();

                if (orders.isEmpty) {
                  return Center(
                    child: Text(
                      _currentTab == 'canceled'
                          ? 'No canceled orders.'
                          : _currentTab == 'completed'
                          ? 'No completed orders.'
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

                                    FutureBuilder<DocumentSnapshot>(
                                      future: FirebaseFirestore.instance
                                          .collection('orders')
                                          .doc(order['orderId'])
                                          .get(),
                                      builder: (context, orderSnapshot) {
                                        if (!orderSnapshot.hasData) {
                                          return Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: CircularProgressIndicator(),
                                          );
                                        }

                                        final orderData = orderSnapshot.data!;
                                        final deliveryFee = orderData['deliveryFee'] ?? 'Not Available';
                                        final commissionAmount = orderData['commissionAmount'] ?? 'Not Available';

                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Delivery Fee: \$${deliveryFee.toString()}'),
                                            Text('Commission Amount: \$${commissionAmount.toString()}'),
                                            SizedBox(height: 10),
                                          ],
                                        );
                                      },
                                    ),

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


                                    FutureBuilder<DocumentSnapshot>(
                                      future: FirebaseFirestore.instance
                                          .collection('orders')
                                          .doc(order['orderId'])
                                          .get(),
                                      builder: (context, orderSnapshot) {
                                        if (!orderSnapshot.hasData) {
                                          return Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: CircularProgressIndicator(),
                                          );
                                        }

                                        final orderData = orderSnapshot.data!;
                                        final userUid = orderData['uid'];

                                        if (userUid == null) {
                                          return Text('User not found');
                                        }

                                        return FutureBuilder<DocumentSnapshot>(
                                          future: FirebaseFirestore.instance
                                              .collection('user_accounts')
                                              .doc(userUid)
                                              .get(),
                                          builder: (context, userSnapshot) {
                                            if (!userSnapshot.hasData) {
                                              return Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: CircularProgressIndicator(),
                                              );
                                            }

                                            final userData = userSnapshot.data!;
                                            if (!userData.exists) {
                                              return Text('User not found');
                                            }

                                            final userName = userData['name'] ?? 'Not Available';
                                            final userPhoneNumber = userData['phoneNumber'] ?? 'Not Available';

                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('User: $userName'),
                                                Text('Phone: $userPhoneNumber'),
                                                SizedBox(height: 10),
                                              ],
                                            );
                                          },
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
                                              future: null,
                                              builder: (context, etaSnapshot) {


                                                return Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [

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
