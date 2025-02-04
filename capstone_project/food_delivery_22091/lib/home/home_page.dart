import 'package:flutter/material.dart';
import 'package:food_delivery_22091/home/profile.dart';
import 'Contact.dart';
import 'groceries_page.dart';
import 'items_search.dart';
import 'restaurants_page.dart';
import 'promotion_card.dart';
import 'option_card.dart';
import 'package:food_delivery_22091/services/auth.dart';
import 'package:food_delivery_22091/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_address.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'orders.dart';
import 'package:food_delivery_22091/home/items_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseService _dbService = DatabaseService();
  String? _selectedAddress;
  bool _isLoading = true;
  late Stream<List<Map<String, dynamic>>> _userAddressesStream;
  late Future<String?> _userSelectedAddressFuture;
  int _selectedIndex = 0;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserAddresses();
    _loadUserSelectedAddress();
    _loadUserName();
  }


  void _loadUserAddresses() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userId = user.uid;
      _userAddressesStream = FirebaseFirestore.instance
          .collection('addresses')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((querySnapshot) {
        return querySnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'addressName': doc['addressName'],
            'city': doc['city'],
            'street': doc['street'],
            'building': doc['building'],
          };
        }).toList();
      });
    }
  }


  void _loadUserSelectedAddress() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userId = user.uid;
      _userSelectedAddressFuture = FirebaseFirestore.instance
          .collection('user_accounts')
          .doc(userId)
          .get()
          .then((doc) {
        if (doc.exists) {
          return doc['address'];
        }
        return null;
      });
    }
  }


  void _loadUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userId = user.uid;
      FirebaseFirestore.instance.collection('user_accounts')
          .doc(userId)
          .get()
          .then((doc) {
        if (doc.exists && doc['name'] != null) {
          setState(() {
            _userName = doc['name'];
          });
        }
      });
    }
  }
  Future<void> _deleteAddress(String addressId) async {
    try {
      await FirebaseFirestore.instance.collection('addresses').doc(addressId).update({
        'deleted': 'yes',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Address marked as deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking address as deleted: $e')),
      );
    }
  }


  Future<void> _updateUserAddress(String addressId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userId = user.uid;

        await FirebaseFirestore.instance.collection('user_accounts').doc(userId).update({
          'address': addressId,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Address updated successfully!')),
        );
      }
    } catch (e) {
      print('Error updating user address: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update address.')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90,
        leadingWidth: 100,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Container(
            width: 80,
            height: 80,
            child: Image.asset(
              'assets/dinedwitft-removebg-preview.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, $_userName',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _userAddressesStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Text(
                          "No Address Available",
                          style: TextStyle(fontSize: 12),
                        );
                      }

                      final addresses = snapshot.data!;

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('addresses')
                            .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                            .where('deleted', isEqualTo: 'no')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          }

                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Text("No Address Available");
                          }

                          final addresses = snapshot.data!.docs.map((doc) {
                            return {
                              'id': doc.id,
                              'addressName': doc['addressName'],
                              'city': doc['city'],
                              'street': doc['street'],
                              'building': doc['building'],
                            };
                          }).toList();

                          return FutureBuilder<String?>(
                            future: _userSelectedAddressFuture,
                            builder: (context, addressSnapshot) {
                              if (addressSnapshot.connectionState == ConnectionState.waiting) {
                                return CircularProgressIndicator();
                              }

                              if (addressSnapshot.hasError) {
                                return Text('Error: ${addressSnapshot.error}');
                              }

                              final selectedAddress = addressSnapshot.data;

                              return DropdownButton<String>(
                                value: selectedAddress,
                                hint: Text("Select Address"),
                                onChanged: (String? newAddress) async {
                                  setState(() {
                                    _selectedAddress = newAddress;
                                  });

                                  if (newAddress != null) {
                                    await _updateUserAddress(newAddress);
                                  }
                                },
                                items: addresses.map((address) {
                                  bool isSelected = address['id'] == selectedAddress;

                                  return DropdownMenuItem<String>(
                                    value: address['id'],
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(address['addressName']),
                                        if (!isSelected)
                                          IconButton(
                                            icon: Icon(Icons.delete, color: Colors.red),
                                            onPressed: () async {
                                              if (!isSelected) {
                                                await _deleteAddress(address['id']);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Address deleted successfully')),
                                                );
                                              }
                                            },
                                          ),


                                      ],
                                    ),
                                  );
                                }).toList(),
                              );

                            },
                          );
                        },
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddAddress(),
                        ),
                      );
                    },
                  ),
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
            ],
          ),
        ),
      ),


      body: IndexedStack(
        index: _selectedIndex,
        children: [
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _dbService.fetchRestaurants(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No restaurants available'));
              }

              List<Map<String, dynamic>> restaurants = snapshot.data!;

              return Column(
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OptionCard(
                          icon: Icons.shopping_bag,
                          label: "Items",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ItemsSearchPage(),
                              ),
                            );
                          },
                        ),


                        OptionCard(
                          icon: Icons.restaurant,
                          label: "Restaurants",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RestaurantsPage(
                                  title: "Nearby Restaurants",
                                  places: restaurants,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Promotions',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('items')
                                .orderBy('discount', descending: true)
                                .limit(10)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Center(child: CircularProgressIndicator());
                              }

                              if (snapshot.hasError) {
                                return Center(child: Text('Error: ${snapshot.error}'));
                              }

                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                return Center(child: Text('No promotions available'));
                              }

                              final items = snapshot.data!.docs.map((doc) {
                                return {
                                  'name': doc['name'],
                                  'discount': doc['discount'],
                                  'picture': doc['picture'],
                                  'userId': doc['userId'],
                                  'isDeleted': doc['isDeleted'],
                                  'hide': doc['hide'],
                                  'availability': doc['availability'],
                                };
                              }).toList();


                              final filteredItems = items.where((item) {
                                return item['isDeleted'] != true &&
                                    item['hide'] != 'yes' &&
                                    item['availability'] == 'yes';
                              }).toList();

                              if (filteredItems.isEmpty) {
                                return Center(child: Text('No promotions available'));
                              }

                              return FutureBuilder<List<Map<String, dynamic>>>(
                                future: _dbService.fetchRestaurants(),
                                builder: (context, restaurantSnapshot) {
                                  if (restaurantSnapshot.connectionState == ConnectionState.waiting) {
                                    return Center(child: CircularProgressIndicator());
                                  }

                                  if (restaurantSnapshot.hasError) {
                                    return Center(child: Text('Error: ${restaurantSnapshot.error}'));
                                  }

                                  if (!restaurantSnapshot.hasData || restaurantSnapshot.data!.isEmpty) {
                                    return Center(child: Text('No restaurants available'));
                                  }

                                  List<String> restaurantUserIds = restaurantSnapshot.data!
                                      .map((restaurant) => restaurant['userId'] as String)
                                      .toList();

                                  final finalFilteredItems = filteredItems.where((item) {
                                    return restaurantUserIds.contains(item['userId']);
                                  }).toList();

                                  if (finalFilteredItems.isEmpty) {
                                    return Center(child: Text('No promotions for your nearby restaurants'));
                                  }

                                  return ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: finalFilteredItems.length,
                                    itemBuilder: (context, index) {
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ItemsPage(restaurantId: finalFilteredItems[index]['userId']),
                                            ),
                                          );
                                        },
                                        child: PromotionCard(
                                          title: finalFilteredItems[index]['name'],
                                          discount: "${finalFilteredItems[index]['discount']}% OFF",
                                          image: finalFilteredItems[index]['picture'],
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                ],
              );
            },
          ),
          OrdersPage(),
          Profile(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
