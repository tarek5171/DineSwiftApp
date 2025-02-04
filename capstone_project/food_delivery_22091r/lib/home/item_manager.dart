import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_item.dart';
import 'modify_item.dart';
import 'restaurant_demo_form.dart';

class ItemManager extends StatefulWidget {
  @override
  _ItemManagerState createState() => _ItemManagerState();
}

class _ItemManagerState extends State<ItemManager> {
  String restaurantStatus = "Inactive";
  late String userId;
  late Stream<DocumentSnapshot> restaurantStream;


  Stream<DocumentSnapshot> fetchRestaurantInfo() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    userId = user.uid;
    DocumentReference restaurantRef =
    FirebaseFirestore.instance.collection('restaurants').doc(userId);
    return restaurantRef.snapshots();
  }


  Stream<String> fetchRestaurantStatus() {
    return FirebaseAuth.instance.authStateChanges().asyncMap((user) async {
      if (user == null) {
        return "Inactive";
      }

      String userId = user.uid;
      DocumentReference restaurantAccountRef =
      FirebaseFirestore.instance.collection('restaurants_accounts').doc(userId);

      DocumentSnapshot restaurantAccountDoc = await restaurantAccountRef.get();

      if (restaurantAccountDoc.exists) {

        return restaurantAccountDoc['activity'] ?? "Inactive";
      } else {
        return "Inactive";
      }
    });
  }


  Stream<Map<String, List<DocumentSnapshot>>> fetchItemsGroupedBySection() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value({});
    }

    userId = user.uid;
    DocumentReference restaurantRef = FirebaseFirestore.instance
        .collection('restaurants')
        .doc(userId);

    return restaurantRef.snapshots().asyncMap((restaurantDoc) async {
      if (!restaurantDoc.exists) {
        return {};
      }

      List<dynamic> sections = restaurantDoc['sections'];
      Map<String, List<DocumentSnapshot>> groupedItems = {};

      for (String section in sections) {
        QuerySnapshot sectionItems = await FirebaseFirestore.instance
            .collection('items')
            .where('section', isEqualTo: section)
            .where('userId', isEqualTo: userId)
            .get();

        groupedItems[section] = sectionItems.docs;
      }

      return groupedItems;
    });
  }


  Future<void> addSection(String sectionName) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated.')),
        );
        return;
      }

      String userId = user.uid;
      DocumentReference userRef =
      FirebaseFirestore.instance.collection('restaurants').doc(userId);

      DocumentSnapshot userDoc = await userRef.get();

      if (userDoc.exists) {
        await userRef.update({
          'sections': FieldValue.arrayUnion([sectionName]),
        });
      } else {
        await userRef.set({
          'sections': [sectionName],
        }, SetOptions(merge: true));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Section added successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding section: $e')),
      );
    }
  }

  void promptAddSection() {
    TextEditingController sectionNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Section'),
          content: TextField(
            controller: sectionNameController,
            decoration: const InputDecoration(
              labelText: 'Section Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                String sectionName = sectionNameController.text.trim();
                if (sectionName.isNotEmpty) {
                  addSection(sectionName);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Section name cannot be empty.')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    restaurantStream = fetchRestaurantInfo();


    fetchRestaurantStatus().listen((status) {
      setState(() {
        restaurantStatus = status;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Manager Page'),
        backgroundColor: Colors.blueGrey,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RestaurantDemoForm()),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blueGrey.shade700,
            ),
            child: const Text('Modify Restaurant'),
          ),
          const SizedBox(width: 20),
          TextButton(
            onPressed: () async {
              try {
                User? user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  throw Exception('User not authenticated');
                }

                String userId = user.uid;
                DocumentReference restaurantAccountRef =
                FirebaseFirestore.instance.collection('restaurants_accounts').doc(userId);


                String newStatus = restaurantStatus == "Inactive" ? "Active" : "Inactive";


                await restaurantAccountRef.set({
                  'activity': newStatus,
                }, SetOptions(merge: true));

                setState(() {
                  restaurantStatus = newStatus;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Restaurant status updated to $newStatus.')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating status: $e')),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blueGrey.shade700,
            ),
            child: Text('Restaurant Status: $restaurantStatus'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
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

                return Column(
                  children: [

                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
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
                    ),
                  ],
                );



              },
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Please price your items according to the commission set.',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddItem()),
                      ).then((_) {
                        setState(() {});
                      });
                    },
                    icon: const Icon(
                      Icons.add,
                      size: 16,
                    ),
                    label: const Text(
                      'Add Item',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 6.0,
                        horizontal: 10.0,
                      ),
                      minimumSize: Size(90, 30),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: promptAddSection,
                    icon: const Icon(
                      Icons.add,
                      size: 16,
                    ),
                    label: const Text(
                      'Add Section',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 6.0,
                        horizontal: 10.0,
                      ),
                      minimumSize: Size(90, 30),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('items')
                    .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                    .where('isDeleted', isEqualTo: 'no')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No items available.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }


                  Map<String, List<DocumentSnapshot>> groupedItems = {};
                  for (var doc in snapshot.data!.docs) {
                    String section = doc['section'];
                    if (groupedItems[section] == null) {
                      groupedItems[section] = [];
                    }
                    groupedItems[section]!.add(doc);
                  }

                  return ListView.builder(
                    itemCount: groupedItems.keys.length,
                    itemBuilder: (context, index) {
                      String sectionName = groupedItems.keys.elementAt(index);
                      List<DocumentSnapshot> sectionItems = groupedItems[sectionName]!;

                      return ExpansionTile(
                        title: Text(
                          sectionName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        children: sectionItems.map((item) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(8.0),
                              title: Row(
                                children: [
                                  Image.network(
                                    item['picture'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'],
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        Text(
                                          item['description'],
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                        Text(
                                          '\$${item['price']}',
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                        onPressed: () async {
                                          try {
                                            String documentId = item.id;
                                            await FirebaseFirestore.instance
                                                .collection('items')
                                                .doc(documentId)
                                                .update({'isDeleted': 'yes'});
                                            print('Item with ID $documentId marked as deleted');
                                          } catch (e) {
                                            print('Error updating item: $e');
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          item['hide'] == 'yes'
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          size: 20,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () async {
                                          final itemRef =
                                          FirebaseFirestore.instance.collection('items').doc(item.id);

                                          try {
                                            final docSnapshot = await itemRef.get();
                                            if (docSnapshot.exists) {
                                              final currentData = docSnapshot.data() as Map<String, dynamic>?;
                                              if (currentData != null) {
                                                final hideStatus = currentData['hide'] ?? 'no';
                                                final newHideStatus = hideStatus == 'yes' ? 'no' : 'yes';
                                                await itemRef.update({'hide': newHideStatus});
                                                print('Hide status for ${item.id} updated to $newHideStatus');
                                              }
                                            } else {
                                              await itemRef.set({'hide': 'yes'}, SetOptions(merge: true));
                                              print('Hide status for ${item.id} set to yes');
                                            }
                                          } catch (e) {
                                            print('Error updating Firestore for ${item.id}: $e');
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          item['availability'] == 'yes'
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          size: 20,
                                          color: item['availability'] == 'yes'
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                        onPressed: () async {
                                          final itemRef =
                                          FirebaseFirestore.instance.collection('items').doc(item.id);

                                          try {
                                            final docSnapshot = await itemRef.get();
                                            if (docSnapshot.exists) {
                                              final currentData = docSnapshot.data() as Map<String, dynamic>?;
                                              if (currentData != null) {
                                                final availabilityStatus = currentData['availability'] ?? 'no';
                                                final newAvailabilityStatus =
                                                availabilityStatus == 'yes' ? 'no' : 'yes';
                                                await itemRef.update({'availability': newAvailabilityStatus});
                                                print(
                                                    'Availability status for ${item.id} updated to $newAvailabilityStatus');
                                              }
                                            } else {
                                              await itemRef.set({'availability': 'yes'}, SetOptions(merge: true));
                                              print('Availability status for ${item.id} set to yes');
                                            }
                                          } catch (e) {
                                            print('Error updating Firestore for ${item.id}: $e');
                                          }
                                        },
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          print('Modify button pressed for item with ID ${item.id}');

                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ModifyItem(itemId: item.id),
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          'Modify',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  );
                },
              ),
            ),

          ],
        ),
      ),
    );
  }
}
