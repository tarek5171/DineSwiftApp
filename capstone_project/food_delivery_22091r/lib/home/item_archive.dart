import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ItemArchivePage extends StatefulWidget {
  final String restaurantId;

  const ItemArchivePage({required this.restaurantId});

  @override
  _ItemArchivePageState createState() => _ItemArchivePageState();
}

class _ItemArchivePageState extends State<ItemArchivePage> {
  late List<String> sections = []; // Store sections from the restaurant

  @override
  void initState() {
    super.initState();
    fetchSections();
  }


  Future<void> fetchSections() async {
    try {
      DocumentSnapshot restaurantSnapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantId)
          .get();


      List<String> fetchedSections = List<String>.from(restaurantSnapshot['sections'] ?? []);
      setState(() {
        sections = fetchedSections;
      });
    } catch (e) {
      print('Error fetching sections: $e');
    }
  }


  Future<void> restoreItem(String itemId) async {
    try {
      await FirebaseFirestore.instance.collection('items').doc(itemId).update({
        'isDeleted': 'no',
      });
      print('Item with ID $itemId restored');
    } catch (e) {
      print('Error restoring item: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Archive'),
        backgroundColor: Colors.blueGrey,
      ),
      body: sections.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: sections.length,
        itemBuilder: (context, sectionIndex) {
          String section = sections[sectionIndex];



          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('items')
                .where('userId', isEqualTo: widget.restaurantId)
                .where('isDeleted', isEqualTo: 'yes')
                .where('section', isEqualTo: section)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }


              List<DocumentSnapshot> sectionItems = snapshot.data?.docs ?? [];

              return ExpansionTile(
                title: Text(
                  section,
                  style: const TextStyle(fontSize: 18),
                ),
                children: sectionItems.isEmpty
                    ? [
                  const ListTile(
                    title: Text('No deleted items available for this section.'),
                  )
                ]
                    : sectionItems.map(
                      (item) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16.0),
                      title: Row(
                        children: [
                          Image.network(
                            item['picture'],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'],
                                  style: const TextStyle(fontSize: 18),
                                ),
                                Text(
                                  item['description'],
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                Text(
                                  '\$${item['price']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  restoreItem(item.id);
                                },
                                icon: const Icon(Icons.restore, size: 20, color: Colors.green),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
