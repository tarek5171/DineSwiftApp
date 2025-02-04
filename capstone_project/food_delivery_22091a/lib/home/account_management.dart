import 'package:flutter/material.dart';

import '../authenticate/registerR.dart';

class AccountManagementPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account Management'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OptionCard(
                  icon: Icons.person_add,
                  label: "Register Drivers",
                  onTap: () {
                  },
                ),
                OptionCard(
                  icon: Icons.person_add,
                  label: "Register Restaurants",
                  onTap: () {

                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterR()),
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
                  icon: Icons.admin_panel_settings,
                  label: "Register Admins",
                  onTap: () {

                  },
                ),
                OptionCard(
                  icon: Icons.manage_accounts,
                  label: "Account Managing",
                  onTap: () {

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
