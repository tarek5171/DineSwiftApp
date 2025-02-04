import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'items_page.dart';

class RestaurantsPage extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> places;

  const RestaurantsPage({required this.title, required this.places});

  @override
  _RestaurantsPageState createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends State<RestaurantsPage> {
  String searchQuery = '';
  late List<Map<String, dynamic>> filteredPlaces;

  @override
  void initState() {
    super.initState();
    filteredPlaces = widget.places;
  }

  void _updateSearch(String query) {
    setState(() {
      searchQuery = query;
      filteredPlaces = widget.places
          .where((place) =>
      place["name"]!.toLowerCase().contains(query.toLowerCase()) ||
          place["description"]!.toLowerCase().contains(query.toLowerCase()) ||
          place["address"]!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 0,
      ),
      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _updateSearch,
              decoration: InputDecoration(
                hintText: 'Search for restaurants or dishes',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          Expanded(
            child: filteredPlaces.isEmpty
                ? const Center(
              child: Text(
                "No restaurants match your search.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
                : ListView.builder(
              itemCount: filteredPlaces.length,
              itemBuilder: (context, index) {
                final place = filteredPlaces[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemsPage(
                            restaurantId: place["userId"]!,
                          ),
                        ),
                      );
                    },
                    title: Row(
                      children: [
                        Image.network(
                          place["restaurantPicture"]!,
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
                                place["name"]!,
                                style: const TextStyle(fontSize: 18),
                              ),
                              Text(
                                place["description"]!,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              Text(
                                place["address"]!,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
