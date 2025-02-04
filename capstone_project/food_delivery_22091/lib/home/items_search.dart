import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'items_page.dart';
import 'package:food_delivery_22091/services/database.dart';

class ItemsSearchPage extends StatefulWidget {
  @override
  _ItemsSearchPageState createState() => _ItemsSearchPageState();
}

class _ItemsSearchPageState extends State<ItemsSearchPage> {
  String searchQuery = '';
  late List<Map<String, dynamic>> filteredItems;
  late List<Map<String, dynamic>> allItems;
  bool isLoading = false;
  String? sortBy = 'discount';
  late List<String> validRestaurantIds;
  ScrollController _scrollController = ScrollController();
  bool _isFetchingMore = false;

  @override
  void initState() {
    super.initState();
    filteredItems = [];
    validRestaurantIds = [];
    _scrollController.addListener(_scrollListener);
    _fetchItems();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  _fetchItems({bool isLoadMore = false}) async {
    if (isLoading || _isFetchingMore) return;

    setState(() {
      isLoading = true;
      if (isLoadMore) {
        _isFetchingMore = true;
      }
    });

    List<String> restaurantIds = await _fetchValidRestaurantIds();

    Query query = FirebaseFirestore.instance.collection('items');

    if (sortBy == 'discount') {
      query = query.orderBy('discount', descending: true);
    } else if (sortBy == 'price') {
      query = query.orderBy('price', descending: false);
    }

    QuerySnapshot snapshot = await query.limit(20).get();

    setState(() {
      isLoading = false;
      if (isLoadMore) {
        _isFetchingMore = false;
        allItems.addAll(snapshot.docs.map((doc) {
          return {
            'name': doc['name'],
            'description': doc['description'],
            'price': doc['price'],
            'discount': doc['discount'],
            'picture': doc['picture'],
            'userId': doc['userId'],
            'isDeleted': doc['isDeleted'],
            'hide': doc['hide'],
            'availability': doc['availability'],
          };
        }).toList());
      } else {
        allItems = snapshot.docs.map((doc) {
          return {
            'name': doc['name'],
            'description': doc['description'],
            'price': doc['price'],
            'discount': doc['discount'],
            'picture': doc['picture'],
            'userId': doc['userId'],
            'isDeleted': doc['isDeleted'],
            'hide': doc['hide'],
            'availability': doc['availability'],
          };
        }).toList();
      }

      filteredItems = allItems.where((item) {
        return restaurantIds.contains(item['userId']);
      }).toList();
    });
  }

  Future<List<String>> _fetchValidRestaurantIds() async {
    DatabaseService dbService = DatabaseService();
    List<Map<String, dynamic>> restaurants = await dbService.fetchRestaurants();

    return restaurants.map((restaurant) => restaurant['userId'] as String).toList();
  }

  void _updateSearch(String query) {
    setState(() {
      searchQuery = query;
      filteredItems = allItems
          .where((item) =>
      item["name"]!.toLowerCase().contains(query.toLowerCase()) ||
          item["description"]!.toLowerCase().contains(query.toLowerCase()) ||
          item["price"].toString().contains(query))
          .toList();
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _fetchItems(isLoadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Items'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch<String>(context: context, delegate: ItemSearchDelegate(
                items: allItems,
                onSearchUpdated: _updateSearch,
              ));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _updateSearch,
              decoration: InputDecoration(
                hintText: 'Search for items',
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
            child: filteredItems.isEmpty
                ? const Center(
              child: Text(
                "No items match your search.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              itemCount: filteredItems.length + (_isFetchingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == filteredItems.length) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final item = filteredItems[index];
                if (item['isDeleted'] == true || item['hide'] == 'yes' || item['availability'] == 'no') {
                  return SizedBox();
                }

                final double price = item['price'] ?? 0.0;
                final double discount = item['discount'] ?? 0.0;
                final discountedPrice = price - (price * discount / 100);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemsPage(
                            restaurantId: item["userId"]!,
                          ),
                        ),
                      );
                    },
                    title: Row(
                      children: [
                        Image.network(
                          item["picture"]!,
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
                                item["name"]!,
                                style: const TextStyle(fontSize: 18),
                              ),
                              Text(
                                item["description"]!,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              Row(
                                children: [
                                  if (discount > 0)
                                    Text(
                                      "\$${price.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.red,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  if (discount > 0)
                                    const SizedBox(width: 8),
                                  Text(
                                    "\$${discount > 0 ? discountedPrice.toStringAsFixed(2) : price.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
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

class ItemSearchDelegate extends SearchDelegate<String> {
  final List<Map<String, dynamic>> items;
  final Function(String) onSearchUpdated;

  ItemSearchDelegate({required this.items, required this.onSearchUpdated});

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = items.where((item) {
      return item['name'].toLowerCase().contains(query.toLowerCase()) ||
          item['description'].toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return ListTile(
          title: Text(item['name']),
          onTap: () {
            query = item['name'];
            onSearchUpdated(query);
            showResults(context);
          },
        );
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = items.where((item) {
      return item['name'].toLowerCase().contains(query.toLowerCase()) ||
          item['description'].toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return ListTile(
          title: Text(item['name']),
          onTap: () {
            close(context, item['name']);
          },
        );
      },
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }
}
