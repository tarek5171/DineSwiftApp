import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:imgbb_uploader/imgbb.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_delivery_22091r/services/maps/location_picker.dart';
import 'package:image/image.dart' as img;
import 'package:food_delivery_22091r/services/auth.dart';

class RestaurantDemoForm extends StatefulWidget {
  @override
  _RestaurantDemoFormState createState() => _RestaurantDemoFormState();
}

class _RestaurantDemoFormState extends State<RestaurantDemoForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  double commission = 10;
  final AuthService _auth = AuthService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  LatLng? selectedLocation;
  File? logoFile;
  File? restaurantPictureFile;

  final ImagePicker _picker = ImagePicker();
  final String imgbbApiKey = "53f956fdea73233bb0f0a0804716c3d9";
  bool isUploading = false;

  // Helper function to resize images to 200x200
  Future<File> resizeImage(File imageFile) async {
    img.Image? image = img.decodeImage(await imageFile.readAsBytes());
    if (image != null) {
      image = img.copyResize(image, width: 200, height: 200);
      final resizedFile = File(imageFile.path)..writeAsBytesSync(img.encodeJpg(image));
      return resizedFile;
    }
    return imageFile;
  }

  // Helper function to upload image to Imgbb
  Future<String?> uploadImageToImgbb(File imageFile) async {
    try {
      final uploader = ImgbbUploader(imgbbApiKey);
      final response = await uploader.uploadImageFile(
        imageFile: imageFile,
        name: 'uploaded_image',
      );
      if (response != null && response.status == 200) {
        return response.data?.url;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image upload failed.")),
        );
        return null;
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $error")),
      );
      return null;
    }
  }

  Future<void> saveRestaurantData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated.')),
        );
        return;
      }

      String userId = user.uid;
      String? logoUrl = logoFile != null ? await uploadImageToImgbb(logoFile!) : null;
      String? restaurantPicUrl = restaurantPictureFile != null ? await uploadImageToImgbb(restaurantPictureFile!) : null;

      DocumentReference restaurantRef = FirebaseFirestore.instance.collection('restaurants').doc(userId);

      // Create a new restaurant document with the provided data
      await restaurantRef.set({
        'name': nameController.text,
        'address': addressController.text,
        'description': descriptionController.text,
        'location': {
          'latitude': selectedLocation!.latitude,
          'longitude': selectedLocation!.longitude,
        },
        'logo': logoUrl,
        'restaurantPicture': restaurantPicUrl,
        'userId': userId,
        'commission': commission,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restaurant data submitted successfully.')),
      );


    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Registration Form'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.of(context).pushReplacementNamed('/login'); // Navigate to login screen
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [

              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Restaurant Name",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a restaurant name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Address
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: "Address",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Description
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: "Description",
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Logo Upload
              ElevatedButton(
                onPressed: () async {
                  final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      logoFile = File(pickedFile.path);
                    });
                    final resizedLogoFile = await resizeImage(logoFile!);
                    final url = await uploadImageToImgbb(resizedLogoFile);
                    if (url != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Logo uploaded successfully: $url")),
                      );
                    }
                  }
                },
                child: const Text("Upload Logo"),
              ),
              if (logoFile != null)
                Image.file(
                  logoFile!,
                  height: 150,
                  width: 150,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 10),

              // Restaurant Picture Upload
              ElevatedButton(
                onPressed: () async {
                  final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      restaurantPictureFile = File(pickedFile.path);
                    });
                    final resizedRestaurantPicFile = await resizeImage(restaurantPictureFile!);
                    final url = await uploadImageToImgbb(resizedRestaurantPicFile);
                    if (url != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Picture uploaded successfully: $url")),
                      );
                    }
                  }
                },
                child: const Text("Upload Restaurant Picture"),
              ),
              if (restaurantPictureFile != null)
                Image.file(
                  restaurantPictureFile!,
                  height: 150,
                  width: 150,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 10),

              // Location Picker
              selectedLocation == null
                  ? ElevatedButton(
                onPressed: () async {
                  LatLng? location = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocationPicker(),
                    ),
                  );
                  if (location != null) {
                    setState(() {
                      selectedLocation = location;
                    });
                  }
                },
                child: const Text("Pick Location"),
              )
                  : ListTile(
                title: Text(
                  "Location: ${selectedLocation!.latitude}, ${selectedLocation!.longitude}",
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    LatLng? location = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationPicker(),
                      ),
                    );
                    if (location != null) {
                      setState(() {
                        selectedLocation = location;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: isUploading
                    ? null
                    : () {
                  if (_formKey.currentState!.validate() && selectedLocation != null) {
                    saveRestaurantData();
                  } else if (selectedLocation == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a location')),
                    );
                  }
                },
                child: isUploading
                   ? const CircularProgressIndicator()
                    : const Text("Submit"),
              ),
              Text('Restaurant dashboard will be unlocked when your profile is approved'),
            ],
          ),
        ),
      ),
    );
  }
}
