import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_delivery_22091a/home/driver_orders.dart';

class DriverManagerPage extends StatefulWidget {
  @override
  _DriverManagerPageState createState() => _DriverManagerPageState();
}

class _DriverManagerPageState extends State<DriverManagerPage> {
  TextEditingController _deliveryFeeController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  String _currentAvailabilityFilter = 'available';
  String _currentStatusFilter = 'accepted';
  String _selectedRange = 'None';
  double? _commonDeliveryFee;
  Stream<List<Map<String, dynamic>>> _getFilteredDrivers() async* {
    final querySnapshot = await _firestore.collection('driver_accounts').snapshots();
    await for (final snapshot in querySnapshot) {
      List<Map<String, dynamic>> drivers = [];
      for (var doc in snapshot.docs) {
        final driverData = doc.data();
        final driverId = driverData['uid'];
        final availability = driverData['availability'] ?? 'not available';
        final driverStatus = driverData['status'] ?? 'pending';


        final locationData = driverData['location'] ?? {};
        final latitude = locationData['latitude'] ?? 0.0;
        final longitude = locationData['longitude'] ?? 0.0;
        final locationTimestamp = locationData['locationTimestamp']?.toDate() ?? DateTime.now();

        if (_searchQuery.isNotEmpty &&
            !(driverData['name'] ?? '')
                .toLowerCase()
                .contains(_searchQuery.toLowerCase())) {
          continue;
        }

        // Filter by availability
        if (_currentAvailabilityFilter == 'available' && availability == 'available' ||
            _currentAvailabilityFilter == 'not available' && availability == 'not available' ||
            _currentAvailabilityFilter == 'none') {

          // Filter by status
          if (_currentStatusFilter == 'accepted' && driverStatus == 'accepted' ||
              _currentStatusFilter == 'pending' && driverStatus == 'pending' ||
              _currentStatusFilter == 'rejected' && driverStatus == 'rejected') {

            driverData['id'] = doc.id;
            driverData['latitude'] = latitude;
            driverData['longitude'] = longitude;
            driverData['locationTimestamp'] = locationTimestamp;


            final totalDeliveryFee = await _getTotalDeliveryFee(driverId, _selectedRange);
            driverData['totalDeliveryFee'] = totalDeliveryFee;

            drivers.add(driverData);
          }
        }
      }
      yield drivers;
    }
  }

  Future<double> _getTotalDeliveryFee(String driverId, String selectedRange) async {
    double totalFee = 0.0;


    final now = DateTime.now();
    DateTime startDate;

    switch (selectedRange) {
      case '1 week':
        startDate = now.subtract(Duration(days: 7));
        break;
      case '1 month':
        startDate = now.subtract(Duration(days: 30));
        break;
      case '3 months':
        startDate = now.subtract(Duration(days: 90));
        break;
      case '6 months':
        startDate = now.subtract(Duration(days: 180));
        break;
      case '1 year':
        startDate = now.subtract(Duration(days: 365));
        break;
      default:
        startDate = DateTime(1900, 1, 1);
        break;
    }

    // Fetch all orders for this driver
    final ordersSnapshot = await _firestore
        .collection('orders')
        .where('driverId', isEqualTo: driverId)
        .where('driverStatus', isEqualTo: 'completed')
        .get();

    // Filter orders based on timestamp locally
    for (var order in ordersSnapshot.docs) {
      final orderData = order.data();
      final deliveryFee = orderData['deliveryFee'] ?? 0.0;
      final timestamp = orderData['timestamp']?.toDate() ?? DateTime.now();

      // Check if the order's timestamp is within the selected range
      if (timestamp.isAfter(startDate)) {
        totalFee += deliveryFee;
      }
    }

    return totalFee;
  }

  void _changeStatusFilter(String status) {
    setState(() {
      _currentStatusFilter = status;
    });
  }

  void _changeTimeRange(String range) {
    setState(() {
      _selectedRange = range;
    });
  }


  Future<void> _updateDriverStatus(String driverId, String newStatus) async {
    try {
      await _firestore.collection('driver_accounts').doc(driverId).update({
        'status': newStatus,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Driver status updated to $newStatus'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to update driver status: $e'),
      ));
    }
  }

  Future<double> fetchDeliveryFee() async {
    final financeDoc = await FirebaseFirestore.instance
        .collection('finance')
        .doc('deliveryFee')
        .get();

    if (financeDoc.exists) {
      return (financeDoc['amount'] ?? 0).toDouble();
    } else {
      return 0;
    }
  }
  Future<void> _updateDeliveryFee(double newDeliveryFee) async {
    try {
      await FirebaseFirestore.instance
          .collection('finance')
          .doc('deliveryFee')
          .update({
        'amount': newDeliveryFee,
      });
      setState(() {
        _commonDeliveryFee = newDeliveryFee;
      });
    } catch (e) {
      print('Failed to update delivery fee: $e');
    }
  }

  Future<double?> _fetchCommonDeliveryFee() async {
    try {
      final financeDoc = await FirebaseFirestore.instance
          .collection('finance')
          .doc('deliveryFee')
          .get();
      setState(() {
        _commonDeliveryFee = financeDoc['amount']?.toDouble() ?? 0.0;
      });
      return _commonDeliveryFee;
    } catch (e) {
      print('Failed to fetch common delivery fee: $e');
      setState(() {
        _commonDeliveryFee = 0.0;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchCommonDeliveryFee();
    _currentStatusFilter = 'accepted';
    _deliveryFeeController.text = _commonDeliveryFee?.toStringAsFixed(2) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Manager'),
        toolbarHeight: 120,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(140),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () => _changeStatusFilter('accepted'),
                    child: const Text('Accepted'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentStatusFilter == 'accepted'
                          ? Colors.blue
                          : Colors.grey,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _changeStatusFilter('pending'),
                    child: const Text('Pending'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentStatusFilter == 'pending'
                          ? Colors.orange
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: [

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          child: DropdownButton<String>(
                            value: _currentAvailabilityFilter,
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _currentAvailabilityFilter = newValue;
                                });
                              }
                            },
                            items: <String>['available', 'not available', 'none']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                        SizedBox(width: 16),
                        Container(
                          width: 140,
                          child: DropdownButton<String>(
                            value: _selectedRange,
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                _changeTimeRange(newValue);
                              }
                            },
                            items: <String>['None', '1 week', '1 month', '3 months', '6 months', '1 year']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                        SizedBox(width: 16),

                        Container(
                          width: 140,
                          child: TextField(
                            controller: _deliveryFeeController,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Delivery Fee',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),

                        ElevatedButton(
                          onPressed: () {
                            double? newFee = double.tryParse(_deliveryFeeController.text);
                            if (newFee != null) {
                              _updateDeliveryFee(newFee);
                            } else {
                              print("Invalid fee entered.");
                            }
                          },
                          child: Text('Modify'),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),

                    Text(
                      'Delivery Fee: \$${_commonDeliveryFee?.toStringAsFixed(2) ?? '...'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )

            ],
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getFilteredDrivers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          final drivers = snapshot.data ?? [];
          if (drivers.isEmpty) {
            return const Center(child: Text('No drivers found'));
          }

          return ListView.builder(
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final driver = drivers[index];
              final currentAvailability = driver['availability'] ?? 'not available';
              final latitude = driver['latitude'] ?? 0.0;
              final longitude = driver['longitude'] ?? 0.0;
              final locationTimestamp = driver['locationTimestamp']?.toString() ?? 'N/A';
              final totalDeliveryFee = driver['totalDeliveryFee'] ?? 0.0;
              final driverStatus = driver['status'] ?? 'pending';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(driver['name'] ?? 'No Name'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Phone: ${driver['phoneNumber'] ?? 'N/A'}'),
                          Text('Availability: $currentAvailability'),
                          Text('Status: $driverStatus'),
                          Text('Location: $latitude, $longitude'),
                          Text('Last Location Update: $locationTimestamp'),
                          Text('Total Delivery Fee: \$${totalDeliveryFee.toStringAsFixed(2)}'),
                        ],
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          ElevatedButton(
                            onPressed: () => _updateDriverStatus(driver['id'], 'accepted'),
                            child: const Text('Accept'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _updateDriverStatus(driver['id'], 'rejected'),
                            child: const Text('Reject'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _viewOrders(driver['id']),
                            child: const Text('View Orders'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
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

  void _viewOrders(String driverId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrdersPage(driverId: driverId),
      ),
    );
  }
}
