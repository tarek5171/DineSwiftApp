import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:imgbb_uploader/imgbb.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;

class AddItem extends StatefulWidget {
  @override
  _AddItemState createState() => _AddItemState();
}

class _AddItemState extends State<AddItem> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountController = TextEditingController();

  File? _itemPictureFile;
  final _picker = ImagePicker();
  final _imgbbApiKey = "53f956fdea73233bb0f0a0804716c3d9";

  List<String> _sections = [];
  String? _selectedSection;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchSections();
  }

  Future<void> _fetchSections() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _sections = List<String>.from(doc['sections'] ?? []);
        });
      }
    } catch (e) {
      _showSnackBar('Error fetching sections: $e');
    }
  }

  Future<String?> _uploadImageToImgbb(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) throw 'Invalid image format.';

      final resizedImage = img.copyResize(image, width: 200, height: 200);
      final resizedFile = File('${imageFile.parent.path}/resized_image.jpg')
        ..writeAsBytesSync(img.encodeJpg(resizedImage));

      final uploader = ImgbbUploader(_imgbbApiKey);
      final response = await uploader.uploadImageFile(
        imageFile: resizedFile,
        name: 'uploaded_item_image',
      );

      if (response?.status == 200) {
        _showSnackBar("Image uploaded successfully!");
        return response?.data?.url;
      } else {
        throw 'Image upload failed.';
      }
    } catch (e) {
      _showSnackBar('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _saveItemData() async {
    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not authenticated.';

      if (_itemPictureFile == null) throw 'Please upload an item picture.';
      if (_selectedSection == null) throw 'Please select a section.';

      final imageUrl = await _uploadImageToImgbb(_itemPictureFile!);
      if (imageUrl == null) throw 'Image upload failed.';

      await FirebaseFirestore.instance.collection('items').add({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'discount': double.parse(_discountController.text.trim()),
        'picture': imageUrl,
        'section': _selectedSection,
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'hide': 'no',
        'availability': 'yes',
        'isDeleted': 'no',
      });

      _showSnackBar('Item added successfully!');
      _resetForm();
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _resetForm() {
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _discountController.clear();
    setState(() {
      _itemPictureFile = null;
      _selectedSection = null;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Item')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Item Name',
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter an item name'
                    : null,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a description'
                    : null,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _priceController,
                label: 'Price',
                keyboardType: TextInputType.number,
                validator: (value) => _validateNumber(value, 'price'),
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _discountController,
                label: 'Discount (%)',
                keyboardType: TextInputType.number,
                validator: (value) => _validateNumber(value, 'discount'),
              ),
              const SizedBox(height: 10),
              _buildDropdown(),
              const SizedBox(height: 10),
              _buildImagePicker(),
              const SizedBox(height: 20),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSection,
      items: _sections.map((section) {
        return DropdownMenuItem(value: section, child: Text(section));
      }).toList(),
      onChanged: (value) => setState(() => _selectedSection = value),
      decoration: const InputDecoration(labelText: "Select Section"),
      validator: (value) =>
      value == null || value.isEmpty ? 'Please select a section' : null,
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            final pickedFile =
            await _picker.pickImage(source: ImageSource.gallery);
            if (pickedFile != null) {
              setState(() => _itemPictureFile = File(pickedFile.path));
            }
          },
          child: const Text("Upload Item Picture"),
        ),
        if (_itemPictureFile != null)
          Image.file(
            _itemPictureFile!,
            height: 200,
            width: 200,
            fit: BoxFit.cover,
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting
          ? null
          : () {
        if (_formKey.currentState!.validate()) {
          _saveItemData();
        }
      },
      child: _isSubmitting
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text("Submit"),
    );
  }

  String? _validateNumber(String? value, String field) {
    if (value == null || value.isEmpty) {
      return 'Please enter a $field';
    }
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    return null;
  }
}

