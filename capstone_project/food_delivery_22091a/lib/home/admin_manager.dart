import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminManagerPage extends StatefulWidget {
  @override
  _AdminManagerPageState createState() => _AdminManagerPageState();
}

class _AdminManagerPageState extends State<AdminManagerPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  String _currentStatusFilter = 'accepted';


  Stream<List<Map<String, dynamic>>> _getFilteredAdmins() async* {
    final querySnapshot = await _firestore.collection('admin_accounts').snapshots();
    await for (final snapshot in querySnapshot) {
      List<Map<String, dynamic>> admins = [];
      for (var doc in snapshot.docs) {
        final adminData = doc.data();
        final adminId = adminData['uid'];
        final adminStatus = adminData['status'] ?? 'pending';

        if (_searchQuery.isNotEmpty &&
            !(adminData['name'] ?? '')
                .toLowerCase()
                .contains(_searchQuery.toLowerCase())) {
          continue;
        }


        if (_currentStatusFilter == 'accepted' && adminStatus == 'accepted' ||
            _currentStatusFilter == 'pending' && adminStatus == 'pending' ||
            _currentStatusFilter == 'rejected' && adminStatus == 'rejected') {

          adminData['id'] = doc.id;
          adminData['status'] = adminStatus;

          admins.add(adminData);
        }
      }
      yield admins;
    }
  }

  void _changeStatusFilter(String status) {
    setState(() {
      _currentStatusFilter = status;
    });
  }




  Future<void> _updateAdminStatus(String adminId, String newStatus) async {
    try {
      await _firestore.collection('admin_accounts').doc(adminId).update({
        'status': newStatus,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Admin status updated to $newStatus'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to update admin status: $e'),
      ));
    }
  }

  @override
  void initState() {
    super.initState();

    _currentStatusFilter = 'accepted';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Manager'),
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


            ],
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getFilteredAdmins(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          final admins = snapshot.data ?? [];
          if (admins.isEmpty) {
            return const Center(child: Text('No admins found'));
          }

          return ListView.builder(
            itemCount: admins.length,
            itemBuilder: (context, index) {
              final admin = admins[index];
              final adminStatus = admin['status'] ?? 'pending';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(admin['name'] ?? 'No Name'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email: ${admin['email'] ?? 'N/A'}'),
                          Text('Phone: ${admin['phoneNumber'] ?? 'N/A'}'),
                          Text('Status: $adminStatus'),
                          Text('Created At: ${admin['createdAt']?.toDate()?.toString() ?? 'N/A'}'),
                        ],
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          ElevatedButton(
                            onPressed: () => _updateAdminStatus(admin['id'], 'accepted'),
                            child: const Text('Accept'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _updateAdminStatus(admin['id'], 'rejected'),
                            child: const Text('Reject'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
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
