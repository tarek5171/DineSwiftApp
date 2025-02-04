import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_delivery_22091/home/home_page.dart';

class CheckoutPage extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final double totalPrice;
  final String userAddressId;
  final String restaurantId;

  const CheckoutPage({
    Key? key,
    required this.items,
    required this.totalPrice,
    required this.userAddressId,
    required this.restaurantId,
  }) : super(key: key);

  Future<Map<String, dynamic>> fetchAddressDetails(String addressId) async {
    final addressDoc = await FirebaseFirestore.instance
        .collection('addresses')
        .doc(addressId)
        .get();

    if (addressDoc.exists) {
      return addressDoc.data()!;
    } else {
      throw Exception("Address not found");
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

  Future<Map<String, dynamic>?> fetchAddressMap(String addressId) async {
    try {


      final addressesCollection = FirebaseFirestore.instance.collection('addresses');

      DocumentSnapshot addressSnapshot = await addressesCollection.doc(addressId).get();

      if (addressSnapshot.exists) {
        Map<String, dynamic> data = addressSnapshot.data() as Map<String, dynamic>;

        Map<String, dynamic> addressMap = {
          'addressName': data['addressName'] ?? '',
          'building': data['building'] ?? '',
          'city': data['city'] ?? '',
          'location': {
            'latitude': data['location']?['latitude'] ?? 0.0,
            'longitude': data['location']?['longitude'] ?? 0.0,
          },
          'street': data['street'] ?? '',
        };

        return addressMap;
      } else {
        print('No address found for the provided ID.');
        return null;
      }
    } catch (e) {
      print('Error fetching address: $e');
      return null;
    }
  }

  Future<Map<String, String>> fetchUserNameAndNumber() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('user_accounts')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          String name = userDoc['name'];
          String phoneNumber = userDoc['phoneNumber'];

          return {'name': name, 'phoneNumber': phoneNumber};
        }
      } catch (e) {
        print("Error fetching user data: $e");
      }
    }
    return {'name': '', 'phoneNumber': ''};
  }


  Future<void> confirmOrder(BuildContext context) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to log in first.')),
      );
      return;
    }

    try {
      DocumentSnapshot restaurantDoc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .get();

      double commissionRate = 0;
      if (restaurantDoc.exists) {
        commissionRate = (restaurantDoc['commission'] ?? 0).toDouble();
      }

      double deliveryFee = await fetchDeliveryFee();


      double commissionAmount = (totalPrice * commissionRate) / 100;


      Map<String, String> userInfo = await fetchUserNameAndNumber();
      Map<String, dynamic>? addressinfo = await fetchAddressMap(userAddressId);


      if (addressinfo != null) {
        await FirebaseFirestore.instance.collection('orders').add({
          'uid': userId,
          'restaurantId': restaurantId,
          'addressId': userAddressId,
          'items': items.map((item) {
            return {
              'itemId': item['itemId'],
              'quantity': item['count'],
            };
          }).toList(),
          'totalPrice': totalPrice + deliveryFee,
          'deliveryFee': deliveryFee,
          'status': 'awaiting confirmation',
          'driverId': 'not selected',
          'driverStatus': 'not selected',
          'commissionAmount': commissionAmount,
          'timestamp': FieldValue.serverTimestamp(),
          'name': userInfo['name'],
          'phoneNumber': userInfo['phoneNumber'],
          'address': {
            'addressName': addressinfo['addressName'] ?? '',
            'building': addressinfo['building'] ?? '',
            'city': addressinfo['city'] ?? '',
            'location': {
              'latitude': addressinfo['location']?['latitude'] ?? 0.0,
              'longitude': addressinfo['location']?['longitude'] ?? 0.0,
            },
            'street': addressinfo['street'] ?? '',
          },
        });
      } else {
        print('Address information is missing.');
      }




      for (var item in items) {
        await FirebaseFirestore.instance
            .collection('user_accounts')
            .doc(userId)
            .update({
          'items': FieldValue.arrayRemove([
            {
              'itemId': item['itemId'],
              'count': item['count'],
            }
          ]),
        });
      }


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order confirmed!')),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: fetchAddressDetails(userAddressId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text("Error: ${snapshot.error}"),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: Text("No address found."));
        }

        final address = snapshot.data!;
        final fullAddress =
            "${address['addressName']}, ${address['street']}, ${address['building']}, ${address['city']}";

        return FutureBuilder<double>(
          future: fetchDeliveryFee(),
          builder: (context, deliverySnapshot) {
            if (deliverySnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (deliverySnapshot.hasError) {
              return Center(
                child: Text("Error: ${deliverySnapshot.error}"),
              );
            }

            final deliveryFee = deliverySnapshot.data ?? 0;
            final totalWithDelivery = totalPrice + deliveryFee;

            return Scaffold(
              appBar: AppBar(
                title: const Text('Checkout Receipt'),
                backgroundColor: Colors.blueGrey,
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Receipt',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          double discountedPrice =
                              item['price'] - (item['price'] * (item['discount'] / 100));

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Quantity: ${item['count']}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (item['discount'] > 0)
                                        Text(
                                          '\$${item['price'].toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            decoration: TextDecoration.lineThrough,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '\$${discountedPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Delivery Fee:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${deliveryFee.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Grand Total:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${totalWithDelivery.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Delivered to: $fullAddress',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        onPressed: () => confirmOrder(context),
                        child: const Text('Confirm Order'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
