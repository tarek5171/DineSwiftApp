import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementPage extends StatefulWidget {
  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';


  Stream<List<Map<String, dynamic>>> _getFilteredUsers() async* {
    final querySnapshot = await _firestore.collection('user_accounts').snapshots();
    await for (final snapshot in querySnapshot) {
      List<Map<String, dynamic>> users = [];

      for (var doc in snapshot.docs) {
        final userData = doc.data();
        userData['id'] = doc.id;

        if (_searchQuery.isNotEmpty &&
            !(userData['name'] ?? '')
                .toLowerCase()
                .contains(_searchQuery.toLowerCase())) {
          continue;
        }

        users.add(userData);
      }

      yield users;
    }
  }


  Future<String> _getRestaurantName(String restaurantId) async {
    final restaurantSnapshot = await _firestore
        .collection('restaurants')
        .where('userId', isEqualTo: restaurantId)
        .limit(1)
        .get();

    if (restaurantSnapshot.docs.isNotEmpty) {
      return restaurantSnapshot.docs.first.data()['name'] ?? 'No Name';
    } else {
      return 'No Restaurant Found';
    }
  }


  Future<Map<String, dynamic>> _getDriverDetails(String driverId) async {
    final driverSnapshot = await _firestore
        .collection('driver_accounts')
        .doc(driverId)
        .get();

    if (driverSnapshot.exists) {
      return driverSnapshot.data()!;
    } else {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _getUserOrders(String userId) async {
    final querySnapshot = await _firestore
        .collection('orders')
        .where('uid', isEqualTo: userId)
        .get();

    List<Map<String, dynamic>> orders = [];
    for (var doc in querySnapshot.docs) {
      final orderData = doc.data();
      orderData['id'] = doc.id;

      final addressId = orderData['addressId'];
      if (addressId != null) {
        final addressSnapshot = await _firestore.collection('addresses').doc(addressId).get();
        if (addressSnapshot.exists) {
          orderData['address'] = addressSnapshot.data();
        } else {
          orderData['address'] = null;
        }
      }

      orders.add(orderData);
    }

    return orders;
  }

  void _toggleBlockUser(String userId, bool currentStatus) async {
    try {
      await _firestore.collection('user_accounts').doc(userId).update({
        'isBlocked': !currentStatus,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'User ${currentStatus ? "unblocked" : "blocked"} successfully!'),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update user status: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Management'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _getFilteredUsers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Something went wrong'));
            }

            final users = snapshot.data ?? [];

            if (users.isEmpty) {
              return Center(child: Text('No users found'));
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final isBlocked = user['isBlocked'] ?? false;

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text(user['name'] ?? 'No Name'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user['email'] ?? 'No Email'),
                        Text('Phone: ${user['phoneNumber'] ?? 'N/A'}'),
                        Text('Status: ${isBlocked ? "Blocked" : "Active"}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () => _toggleBlockUser(user['id'], isBlocked),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isBlocked ? Colors.green : Colors.red,
                          ),
                          child: Text(isBlocked ? 'Unblock' : 'Block'),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final orders = await _getUserOrders(user['id']);

                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text("User Orders"),
                                content: orders.isEmpty
                                    ? Text("No orders found for this user.")
                                    : SingleChildScrollView(
                                  child: Column(
                                    children: orders.map((order) {
                                      return Card(
                                        margin: EdgeInsets.symmetric(vertical: 8),
                                        child: Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              FutureBuilder<String>(
                                                future: _getRestaurantName(order['restaurantId']),
                                                builder: (context, restaurantSnapshot) {
                                                  if (restaurantSnapshot.connectionState == ConnectionState.waiting) {
                                                    return CircularProgressIndicator();
                                                  }
                                                  return Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        "Restaurant: ${restaurantSnapshot.data ?? 'Not Found'}",
                                                        style: TextStyle(fontWeight: FontWeight.bold),
                                                      ),
                                                      Text(
                                                        "Status: ${order['status'] ?? 'N/A'}",
                                                        style: TextStyle(fontStyle: FontStyle.italic),
                                                      ),
                                                      Text("Restaurant ID: ${order['restaurantId'] ?? 'N/A'}"),
                                                    ],
                                                  );
                                                },
                                              ),
                                              SizedBox(height: 8),

                                              Text(
                                                "Address: ${order['address'] != null ? "${order['address']['addressName']}, ${order['address']['street']}, ${order['address']['city']}" : 'No Address'}",
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              SizedBox(height: 8),

                                              FutureBuilder<Map<String, dynamic>>(
                                                future: _getDriverDetails(order['driverId']),
                                                builder: (context, driverSnapshot) {
                                                  if (driverSnapshot.connectionState == ConnectionState.waiting) {
                                                    return CircularProgressIndicator();
                                                  }

                                                  final driverData = driverSnapshot.data;
                                                  return Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text("Driver Status: ${order['driverStatus'] ?? 'N/A'}"),
                                                      Text("Driver Name: ${driverData?['name'] ?? 'N/A'}"),
                                                      Text("Driver ID: ${driverData?['uid'] ?? 'N/A'}"),
                                                    ],
                                                  );
                                                },
                                              ),
                                              SizedBox(height: 8),

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
                                              SizedBox(height: 8),

                                              Text(
                                                'Total Price: \$${order['totalPrice']?.toStringAsFixed(2) ?? 'N/A'}',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text("Close"),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Text('View Orders'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
