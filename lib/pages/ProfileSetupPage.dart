import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert'; // For Base64 encoding
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _doctorNameController = TextEditingController();
  final TextEditingController _doctorNumberController = TextEditingController();
  final TextEditingController _diseaseController = TextEditingController();
  final TextEditingController _emergencyNameController = TextEditingController();
  final TextEditingController _emergencyContactController = TextEditingController();
  String _gender = 'Male';
  String _bloodType = 'A+';
  Uint8List? _webImageBytes;
  File? _image;
  final int _selectedIndex = 3; // Set default to Profile tab

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          // Handle web platform
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImageBytes = bytes;
          });
        } else {
          // Handle mobile platform
          setState(() {
            _image = File(pickedFile.path);
          });
        }
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _saveProfileData() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );

          // Convert image to Base64
          String? base64Image;
          if (kIsWeb && _webImageBytes != null) {
            base64Image = base64Encode(_webImageBytes!);
          } else if (!kIsWeb && _image != null) {
            final bytes = await _image!.readAsBytes();
            base64Image = base64Encode(bytes);
          }

          // Save to Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'name': _nameController.text.trim(),
            'age': int.parse(_ageController.text.trim()),
            'gender': _gender,
            'bloodType': _bloodType,
            'disease': _diseaseController.text.trim(),
            'address': _addressController.text.trim(),
            'contact': _contactController.text.trim(),
            'doctorName': _doctorNameController.text.trim(),
            'doctorNumber': _doctorNumberController.text.trim(),
            'emergencyName': _emergencyNameController.text.trim(),
            'emergencyContact': _emergencyContactController.text.trim(),
            'photoBase64': base64Image,
            'email': user.email,
            'timestamp': FieldValue.serverTimestamp(),
          });

          if (!mounted) return;
          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushReplacementNamed(context, '/ProfileDisplayPage');
        } catch (e) {
          print('Error saving profile: $e');
          if (!mounted) return;
          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving profile: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.green),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          labelStyle: TextStyle(color: Colors.grey.shade600),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.green),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          labelStyle: TextStyle(color: Colors.grey.shade600),
        ),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.green),
      ),
    );
  }

  Widget _buildImageWidget() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 60,
        backgroundColor: Colors.green.withOpacity(0.1),
        backgroundImage: kIsWeb && _webImageBytes != null
            ? MemoryImage(_webImageBytes!)
            : (_image != null ? FileImage(_image!) as ImageProvider : null),
        child: (_webImageBytes == null && _image == null)
            ? const Icon(
                Icons.person,
                size: 60,
                color: Colors.white,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Profile Setup',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Profile Image Picker
                    GestureDetector(
                      onTap: _pickImage,
                      child: _buildImageWidget(),
                    ),
                  ],
                ),
              ),
              // Form fields with updated style
              Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildInputField(
                        controller: _nameController,
                        label: 'Name',
                        icon: Icons.person,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      _buildInputField(
                        controller: _ageController,
                        label: 'Age',
                        icon: Icons.cake,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your age';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      _buildDropdownField(
                        label: 'Gender',
                        value: _gender,
                        items: const ['Male', 'Female', 'Other'],
                        onChanged: (value) {
                          setState(() {
                            _gender = value!;
                          });
                        },
                        icon: Icons.people,
                      ),
                      _buildDropdownField(
                        label: 'Blood Type',
                        value: _bloodType,
                        items: const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
                        onChanged: (value) {
                          setState(() {
                            _bloodType = value!;
                          });
                        },
                        icon: Icons.bloodtype,
                      ),
                      _buildInputField(
                        controller: _diseaseController,
                        label: 'Disease',
                        icon: Icons.medical_information,
                      ),
                      _buildInputField(
                        controller: _addressController,
                        label: 'Address',
                        icon: Icons.location_on,
                        maxLines: 2,
                      ),
                      _buildInputField(
                        controller: _contactController,
                        label: 'Contact',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      _buildInputField(
                        controller: _doctorNameController,
                        label: 'Doctor Name',
                        icon: Icons.medical_services,
                      ),
                      _buildInputField(
                        controller: _doctorNumberController,
                        label: 'Doctor Contact Number',
                        icon: Icons.local_hospital,
                        keyboardType: TextInputType.phone,
                      ),
                      _buildInputField(
                        controller: _emergencyNameController,
                        label: 'Emergency Contact Name',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        controller: _emergencyContactController,
                        label: 'Emergency Contact Number',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 24),
                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveProfileData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Save Profile',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
