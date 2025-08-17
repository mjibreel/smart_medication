import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class ProfileDisplayPage extends StatelessWidget {
  const ProfileDisplayPage({super.key});

  @override
  Widget build(BuildContext context) {
    print('ProfileDisplayPage build called');
    
    // Check if user is logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // If not logged in, navigate to sign in page
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/signin');
      });
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid) // Now we can safely use user.uid
            .snapshots(),
        builder: (context, snapshot) {
          print('StreamBuilder state: ${snapshot.connectionState}');
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No profile data found'),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/ProfileSetupPage');
                    },
                    child: const Text('Create Profile'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header with profile image
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Profile',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/ProfileSetupPage');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Profile Image
                      _buildProfileImage(data['photoBase64']),
                      const SizedBox(height: 16),
                      Text(
                        data['name'] ?? 'No Name',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        data['email'] ?? 'No Email',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                // Personal Information
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoTile(
                        icon: Icons.cake,
                        title: 'Age',
                        value: '${data['age'] ?? 'Not set'}',
                      ),
                      _buildInfoTile(
                        icon: Icons.people,
                        title: 'Gender',
                        value: data['gender'] ?? 'Not set',
                      ),
                      _buildInfoTile(
                        icon: Icons.bloodtype,
                        title: 'Blood Type',
                        value: data['bloodType'] ?? 'Not set',
                      ),
                      _buildInfoTile(
                        icon: Icons.medical_information,
                        title: 'Disease',
                        value: data['disease'] ?? 'None',
                      ),
                      _buildInfoTile(
                        icon: Icons.location_on,
                        title: 'Address',
                        value: data['address'] ?? 'Not set',
                      ),
                      _buildInfoTile(
                        icon: Icons.phone,
                        title: 'Contact',
                        value: data['contact'] ?? 'Not set',
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Medical Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoTile(
                        icon: Icons.medical_services,
                        title: 'Doctor Name',
                        value: data['doctorName'] ?? 'Not set',
                      ),
                      _buildInfoTile(
                        icon: Icons.local_hospital,
                        title: 'Doctor Contact',
                        value: data['doctorNumber'] ?? 'Not set',
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Emergency Contact',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoTile(
                        icon: Icons.contact_emergency,
                        title: 'Name',
                        value: data['emergencyName'] ?? 'Not set',
                      ),
                      _buildInfoTile(
                        icon: Icons.phone_callback,
                        title: 'Contact Number',
                        value: data['emergencyNumber'] ?? 'Not set',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileImage(String? base64Image) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.green,
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
        backgroundImage: base64Image != null && base64Image.isNotEmpty
            ? MemoryImage(base64Decode(base64Image))
            : null,
        child: base64Image == null || base64Image.isEmpty
            ? const Icon(Icons.person, size: 60, color: Colors.green)
            : null,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.green),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
