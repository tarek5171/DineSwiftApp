import 'package:flutter/material.dart';
import 'package:food_delivery_22091d/home/acOrders.dart';
import 'package:food_delivery_22091d/home/profile.dart';
import 'package:food_delivery_22091d/home/support.dart';
import 'package:food_delivery_22091d/services/auth.dart';
import 'package:food_delivery_22091d/services/livelocation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'orders.dart';

class HomePage extends StatefulWidget {
  @override
  _DriverHomePageState createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<HomePage> {
  bool isAvailable = false;
  final LiveLocation liveLocation = LiveLocation();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {

    liveLocation.stopLocationUpdates();
    super.dispose();
  }


  Future<void> updateAvailabilityStatus(bool status) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not logged in.");
      }

      await _firestore.collection('driver_accounts').doc(user.uid).update({
        'availability': status ? 'available' : 'unavailable',
      });
      print("Availability status updated to ${status ? 'available' : 'unavailable'}");
    } catch (e) {
      print("Error updating availability status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.support_agent, color: Colors.blue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ContactPage()),
              );
            },
          ),

          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {

              await AuthService().signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Availability Status:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: isAvailable,
                  onChanged: (value) async {
                    setState(() {
                      isAvailable = value;
                    });

                    if (value) {

                      print("Driver is now available. Starting location updates...");
                      await liveLocation.startLocationUpdates();
                    } else {

                      print("Driver is now unavailable. Stopping location updates...");
                      liveLocation.stopLocationUpdates();
                    }


                    await updateAvailabilityStatus(value);
                  },
                  activeColor: Colors.green,
                  inactiveThumbColor: Colors.red,
                  inactiveTrackColor: Colors.redAccent,
                ),
              ],
            ),
          ),

          Expanded(
            child: Column(
              children: [
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OptionCard(
                        icon: Icons.notifications,
                        label: "Requests",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrdersPage(),
                            ),
                          );
                        },
                      ),
                      OptionCard(
                        icon: Icons.receipt,
                        label: "Order Manager",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AcOrdersPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OptionCard(
                        icon: Icons.account_circle,
                        label: "Account Management",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Profile(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class OptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  OptionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4.0,
        child: Container(
          width: 150,
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40),
              SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class OrderManagerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order Manager')),
      body: Center(child: Text('Order Manager Page')),
    );
  }
}

class AccountManagementPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Account Management')),
      body: Center(child: Text('Account Management Page')),
    );
  }
}
