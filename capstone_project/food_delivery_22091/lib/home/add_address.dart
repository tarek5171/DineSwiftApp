import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:food_delivery_22091/services/maps/location_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';

class AddAddress extends StatefulWidget {
  @override
  _AddAddressState createState() => _AddAddressState();
}

class _AddAddressState extends State<AddAddress> {
  final TextEditingController _addressNameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _buildingController = TextEditingController();
  LatLng? _selectedLocation;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Address'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _addressNameController,
              decoration: const InputDecoration(
                labelText: 'Address Name',
                hintText: 'e.g., Home, Office',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                hintText: 'Enter your city',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _streetController,
              decoration: const InputDecoration(
                labelText: 'Street',
                hintText: 'Enter your street',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _buildingController,
              decoration: const InputDecoration(
                labelText: 'Building / Apartment No.',
                hintText: 'Enter your building or apartment number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                final location = await Navigator.push<LatLng>(
                  context,
                  MaterialPageRoute(builder: (context) => LocationPicker()),
                );
                if (location != null) {
                  setState(() {
                    _selectedLocation = location;
                  });
                }
              },
              icon: const Icon(Icons.map),
              label: const Text('Pick Location on Map'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
            ),
            const SizedBox(height: 20),
            if (_selectedLocation != null)
              Text(
                'Selected Location: ${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () async {
                  if (_addressNameController.text.isEmpty ||
                      _cityController.text.isEmpty ||
                      _streetController.text.isEmpty ||
                      _buildingController.text.isEmpty ||
                      _selectedLocation == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Please fill in all fields and pick a location.'),
                      ),
                    );
                    return;
                  }

                  setState(() {
                    _isSaving = true;
                  });

                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      throw 'User not logged in.';
                    }

                    final userId = user.uid;

                    final newAddress = await FirebaseFirestore.instance
                        .collection('addresses')
                        .add({
                      'userId': userId,
                      'deleted': 'no',
                      'addressName': _addressNameController.text,
                      'city': _cityController.text,
                      'street': _streetController.text,
                      'building': _buildingController.text,
                      'location': {
                        'latitude': _selectedLocation!.latitude,
                        'longitude': _selectedLocation!.longitude,
                      },
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    await FirebaseFirestore.instance
                        .collection('user_accounts')
                        .doc(userId)
                        .update({'address': newAddress.id});

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Address added successfully.'),
                      ),
                    );

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => HomePage()),
                          (route) => false,
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error saving address: $e'),
                      ),
                    );
                  } finally {
                    setState(() {
                      _isSaving = false;
                    });
                  }
                },
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Address'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _addressNameController.dispose();
    _cityController.dispose();
    _streetController.dispose();
    _buildingController.dispose();
    super.dispose();
  }
}
