import 'package:flutter/material.dart';
import 'package:food_delivery_22091r/home/profile.dart';
import 'package:food_delivery_22091r/home/support.dart';
import 'item_archive.dart';
import 'item_manager.dart'; // Import the ItemManagerPage
import 'orders.dart';
import 'package:food_delivery_22091r/services/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Ensure this is imported for Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String restaurantId;

  @override
  void initState() {
    super.initState();

    restaurantId = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  Widget build(BuildContext context) {

    if (restaurantId.isEmpty) {
      return Scaffold(
        body: Center(child: Text('User not logged in.')),
      );
    }


    final restaurantStream = FirebaseFirestore.instance
        .collection('restaurants')
        .doc(restaurantId)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text('Restaurant Dashboard'),
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
          // Sign out button
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

          StreamBuilder<DocumentSnapshot>(
            stream: restaurantStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text('Restaurant not found.'));
              }

              var restaurantData = snapshot.data!;
              var name = restaurantData['name'];
              var description = restaurantData['description'];
              var logo = restaurantData['logo'];
              var restaurantPicture = restaurantData['restaurantPicture'];
              var commission = restaurantData['commission'];

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [

                        Stack(
                          children: [

                            Container(
                              width: MediaQuery.of(context).size.width / 3,
                              height: MediaQuery.of(context).size.width / 3,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  restaurantPicture,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                             Positioned(
                              left: 8,
                              top: 8,
                              child: ClipOval(
                                child: Image.network(
                                  logo,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.start,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Commission: $commission%',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

         Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Item Manager Button
                    OptionCard(
                      icon: Icons.fastfood,
                      label: "Restaurant Manager",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ItemManager(), // Navigate to ItemManagerPage
                          ),
                        );
                      },
                    ),
                    // Order Manager Button
                    OptionCard(
                      icon: Icons.receipt,
                      label: "Order Manager",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrdersPage(), // Navigate to OrderManagerPage
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Profile Button
                    OptionCard(
                      icon: Icons.person,
                      label: "Profile",
                      onTap: () {
                        // Navigate to the RestaurantProfile page
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RestaurantProfile()),
                        );
                      },
                    ),
                    // Item Archive Button
                    OptionCard(
                      icon: Icons.archive,
                      label: "Item Archive",
                      onTap: () {
                        // Navigate to the RestaurantProfile page
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ItemArchivePage(restaurantId: restaurantId,)),
                        );
                      },
                    ),
                  ],
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
