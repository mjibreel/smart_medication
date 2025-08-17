import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class UserHeader extends StatelessWidget {
  const UserHeader({super.key});

  Widget _buildProfileImage(String? base64Image) {
    return CircleAvatar(
      radius: 25,
      backgroundColor: Colors.green.withOpacity(0.1),
      backgroundImage: base64Image != null && base64Image.isNotEmpty
          ? MemoryImage(base64Decode(base64Image))
          : null,
      child: base64Image == null || base64Image.isEmpty
          ? const Icon(Icons.person, size: 25, color: Colors.green)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircleAvatar(
            backgroundColor: Colors.white,
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.grey),
              ),
              SizedBox(width: 10),
              Text(
                'User Name',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final name = data['name'] ?? 'User Name';
        final photoBase64 = data['photoBase64'];

        return Row(
          children: [
            _buildProfileImage(photoBase64),
            const SizedBox(width: 10),
            Text(
              name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
} 