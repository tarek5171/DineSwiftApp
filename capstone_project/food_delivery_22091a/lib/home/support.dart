import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SupportPage extends StatefulWidget {
  @override
  _SupportPageState createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'All';


  Stream<List<Map<String, dynamic>>> _getSupportMessages() async* {
    final querySnapshot = await _firestore.collection('support').snapshots();
    await for (final snapshot in querySnapshot) {
      List<Map<String, dynamic>> messages = [];

      for (var doc in snapshot.docs) {
        final messageData = doc.data();
        final uid = messageData['userId'];


        final accountDetails = await _getAccountDetails(uid);
        messageData.addAll(accountDetails);

        if (_selectedFilter == 'All' ||
            messageData['accountType'] == _selectedFilter) {
          messages.add(messageData);
        }
      }

      yield messages;
    }
  }

  Future<Map<String, dynamic>> _getAccountDetails(String uid) async {
    Map<String, dynamic> details = {};

    var userDoc = await _firestore.collection('user_accounts').doc(uid).get();
    if (userDoc.exists) {
      details['accountType'] = 'User';
      details['name'] = userDoc.data()?['name'] ?? 'No name';
      details['phoneNumber'] = userDoc.data()?['phoneNumber'] ?? 'No phone number';
      details['email'] = userDoc.data()?['email'] ?? 'No email';
      return details;
    }

    var driverDoc = await _firestore.collection('driver_accounts').doc(uid).get();
    if (driverDoc.exists) {
      details['accountType'] = 'Driver';
      details['name'] = driverDoc.data()?['name'] ?? 'No name';
      details['phoneNumber'] = driverDoc.data()?['phoneNumber'] ?? 'No phone number';
      details['email'] = driverDoc.data()?['email'] ?? 'No email';
      return details;
    }

    var restaurantDoc = await _firestore.collection('restaurants').doc(uid).get();
    var restaurantAcc = await _firestore.collection('restaurants_accounts').doc(uid).get();
    if (restaurantDoc.exists) {
      details['accountType'] = 'Restaurant';
      details['name'] = restaurantDoc.data()?['name'] ?? 'No name';
      details['phoneNumber'] = restaurantAcc.data()?['phoneNumber'] ?? 'N/A';
      details['email'] = restaurantAcc.data()?['email'] ?? 'N/A';
      return details;
    }

    return details;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Support Messages'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: _selectedFilter,
              onChanged: (newValue) {
                setState(() {
                  _selectedFilter = newValue!;
                });
              },
              items: <String>['All', 'User', 'Driver', 'Restaurant']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getSupportMessages(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Something went wrong'));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(child: Text('No messages found'));
                }

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final userId = message['userId'];
                    final messageText = message['message'];
                    final timestamp = (message['timestamp'] as Timestamp).toDate();
                    final accountType = message['accountType'];
                    final name = message['name'];
                    final phoneNumber = message['phoneNumber'];
                    final email = message['email'];

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text('$accountType - $name'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Phone: $phoneNumber'),
                            Text('Email: $email'),
                            Text('Message: $messageText'),
                            Text('Timestamp: ${timestamp.toLocal()}'),
                          ],
                        ),
                      ),
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
