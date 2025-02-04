import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_delivery_22091a/home/RestaurantMenuPage.dart';
import 'package:food_delivery_22091a/home/restaurant_orders.dart';

class RestaurantManagerPage extends StatefulWidget {
  @override
  _RestaurantManagerPageState createState() => _RestaurantManagerPageState();
}

class _RestaurantManagerPageState extends State<RestaurantManagerPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  String _currentStatusFilter = 'approved';


  Map<String, String> _restaurantFilters = {};

  Stream<List<Map<String, dynamic>>> _getFilteredRestaurants() async* {
    final querySnapshot = await _firestore.collection('restaurants_accounts').snapshots();
    await for (final snapshot in querySnapshot) {
      List<Map<String, dynamic>> restaurants = [];
      for (var doc in snapshot.docs) {
        final accountData = doc.data();
        final restaurantId = accountData['uid'];
        final status = accountData['status'] ?? 'pending';

        final restaurantDoc = await _firestore
            .collection('restaurants')
            .where('userId', isEqualTo: restaurantId)
            .limit(1)
            .get();

        if (restaurantDoc.docs.isNotEmpty) {
          final restaurantData = restaurantDoc.docs.first.data();
          restaurantData['id'] = restaurantDoc.docs.first.id;
          restaurantData['status'] = status;


          if (_searchQuery.isNotEmpty &&
              !(restaurantData['name'] ?? '')
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase())) {
            continue;
          }


          if (_currentStatusFilter == 'pending' && status == 'pending' ||
              _currentStatusFilter == 'approved' && status == 'approved' ||
              _currentStatusFilter == 'rejected' && status == 'rejected') {


            String filter = _restaurantFilters[restaurantData['id']] ?? 'none';
            DateTime? startDate;


            if (filter == 'lastWeek') {
              startDate = DateTime.now().subtract(Duration(days: 7));
            } else if (filter == 'lastMonth') {
              startDate = DateTime.now().subtract(Duration(days: 30));
            } else if (filter == 'last3Months') {
              startDate = DateTime.now().subtract(Duration(days: 90));
            } else if (filter == 'lastYear') {
              startDate = DateTime.now().subtract(Duration(days: 365));
            }


            final ordersQuery = await _firestore
                .collection('orders')
                .where('restaurantId', isEqualTo: restaurantData['id'])
                .where('status', isEqualTo: 'completed')
                .get();

            double totalRevenue = 0;
            double totalCommission = 0;


            for (var order in ordersQuery.docs) {
              final orderData = order.data();
              final timestamp = (orderData['timestamp'] as Timestamp).toDate();

              if (startDate == null || timestamp.isAfter(startDate)) {
                totalRevenue += (orderData['totalPrice'] ?? 0).toDouble();
                totalCommission += (orderData['commissionAmount'] ?? 0).toDouble();
              }
            }

            restaurantData['totalRevenue'] = totalRevenue;
            restaurantData['totalCommission'] = totalCommission;

            restaurants.add(restaurantData);
          }
        }
      }


      yield restaurants;
    }
  }

  void _updateRestaurantFilter(String restaurantId, String filter) {
    setState(() {
      _restaurantFilters[restaurantId] = filter;
    });
  }

  void _updateCommission(String restaurantId, String commission) async {
    try {
      final commissionValue = double.tryParse(commission) ?? 0.0;

      await _firestore.collection('restaurants').doc(restaurantId).set({
        'commission': commissionValue,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Commission updated successfully!')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update commission: $error')),
      );
    }
  }

  void _updateRestaurantStatus(String restaurantId, String newStatus) async {
    try {
      await _firestore
          .collection('restaurants_accounts')
          .doc(restaurantId)
          .set({'status': newStatus}, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restaurant status updated to $newStatus!'),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update restaurant status: $error')),
    );
  }
  }

  void _changeStatusFilter(String status) {
    setState(() {
      _currentStatusFilter = status;
    });
  }

  void _viewMenu(String restaurantId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RestaurantMenuPage(restaurantId: restaurantId),
      ),
    );
  }

  void _viewOrders(String restaurantId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrdersPage(restaurantId: restaurantId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Manager'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () => _changeStatusFilter('approved'),
                    child: const Text('Approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentStatusFilter == 'approved'
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _changeStatusFilter('pending'),
                    child: const Text('Pending'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentStatusFilter == 'pending'
                          ? Colors.blue
                          : Colors.grey,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _changeStatusFilter('rejected'),
                    child: const Text('Rejected'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentStatusFilter == 'rejected'
                          ? Colors.red
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by name...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getFilteredRestaurants(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          final restaurants = snapshot.data ?? [];
          if (restaurants.isEmpty) {
            return const Center(child: Text('No restaurants found'));
          }

          return ListView.builder(
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];
              final currentStatus = restaurant['status'] ?? 'pending';
              final commission =
                  restaurant['commission']?.toString() ?? 'Not Set';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Column(
                  children: [
                    ListTile(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButton<String>(
                            value: _restaurantFilters[restaurant['id']] ?? 'none',
                            items: [
                              DropdownMenuItem(value: 'none', child: Text('None')),
                              DropdownMenuItem(value: 'lastWeek', child: Text('Last Week')),
                              DropdownMenuItem(value: 'lastMonth', child: Text('Last Month')),
                              DropdownMenuItem(value: 'last3Months', child: Text('Last 3 Months')),
                              DropdownMenuItem(value: 'lastYear', child: Text('Last Year')),
                            ],
                            onChanged: (value) => _updateRestaurantFilter(restaurant['id'], value!),
                          ),
                          SizedBox(width: 8),
                          Image.network(
                            restaurant['logo'] ?? 'https://via.placeholder.com/150',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ],
                      ),
                      title: Text(restaurant['name'] ?? 'No Name'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(restaurant['address'] ?? 'No Address'),
                          Text('Status: $currentStatus'),
                          Text('Commission: $commission%'),
                          Text('Total Revenue: ${restaurant['totalRevenue']?.toStringAsFixed(2) ?? '0.00'}'),
                          Text('Total Commission: ${restaurant['totalCommission']?.toStringAsFixed(2) ?? '0.00'}'),
                        ],
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          if (currentStatus != 'approved')
                            ElevatedButton(
                              onPressed: () => _updateRestaurantStatus(restaurant['id'], 'approved'),
                              child: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                          if (currentStatus != 'rejected')
                            ElevatedButton(
                              onPressed: () => _updateRestaurantStatus(restaurant['id'], 'rejected'),
                              child: const Text('Reject'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            ),
                          ElevatedButton(
                            onPressed: () => _viewMenu(restaurant['id']),
                            child: const Text('View Menu'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _viewOrders(restaurant['id']),
                            child: const Text('View Orders'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Set Commission (%)',
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (value) =>
                                  _updateCommission(restaurant['id'], value),
                            ),
                          ),
                        ],
                      ),
                    ),
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
