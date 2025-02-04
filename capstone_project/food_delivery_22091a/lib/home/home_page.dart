import 'package:flutter/material.dart';
import 'package:food_delivery_22091a/home/profile.dart';
import 'package:food_delivery_22091a/home/user_managment.dart';
import 'package:food_delivery_22091a/home/restaurant_manager.dart';
import 'package:food_delivery_22091a/home/driver_manager.dart';
import 'package:food_delivery_22091a/home/support.dart';

import '../services/auth.dart';
import 'admin_manager.dart';
import 'ordersM.dart';

class AdminHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.message),
            onPressed: () {

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SupportPage(),
                ),
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
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OptionCard(
                  icon: Icons.person_outline,
                  label: "User Management",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserManagementPage(),
                      ),
                    );
                  },
                ),
                OptionCard(
                  icon: Icons.restaurant_menu,
                  label: "Restaurant Management",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RestaurantManagerPage(),
                      ),
                    );
                  },
                ),
                OptionCard(
                  icon: Icons.directions_car,
                  label: "Driver Management",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DriverManagerPage(),
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
                  icon: Icons.receipt_long,
                  label: "Order & Transaction Management",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminOrdersPage(),
                      ),
                    );
                  },
                ),
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
                OptionCard(
                  icon: Icons.admin_panel_settings,
                  label: "Admin Management",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminManagerPage(),
                      ),
                    );
                  },
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
