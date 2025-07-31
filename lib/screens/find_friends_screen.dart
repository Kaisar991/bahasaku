// File: lib/screens/find_friends_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class FindFriendsScreen extends StatefulWidget {
  @override
  _FindFriendsScreenState createState() => _FindFriendsScreenState();
}

class _FindFriendsScreenState extends State<FindFriendsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  void _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isLoading = true);
    final results = await _firestoreService.searchUsersByNickname(query.trim());
    if (mounted) {
      setState(() {
        _searchResults = results.where((user) => user['uid'] != _currentUserId).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cari Teman'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cari berdasarkan nama panggilan...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0)),
              ),
              onChanged: _searchUsers,
            ),
          ),
          _isLoading
              ? Expanded(child: Center(child: CircularProgressIndicator()))
              : Expanded(
            child: _searchResults.isEmpty && _searchController.text.isNotEmpty
                ? Center(child: Text('Pengguna tidak ditemukan.'))
                : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                final recipientId = user['uid']; // Ambil UID

                // --- BAGIAN YANG DIPERBAIKI ---
                // Cek apakah recipientId ada sebelum menampilkan tombol
                if (recipientId == null) {
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: Icon(Icons.error_outline, color: Colors.red),
                      title: Text(user['nickname'] ?? 'Data Tidak Lengkap'),
                      subtitle: Text('Pengguna ini tidak dapat ditambahkan.'),
                    ),
                  );
                }

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green[100],
                      child: Icon(Icons.person, color: Colors.green),
                    ),
                    title: Text(user['nickname'] ?? 'Tanpa Nama', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(user['email'] ?? ''),
                    trailing: ElevatedButton.icon(
                      onPressed: () async {
                        // Pengecekan ulang untuk keamanan
                        if (recipientId != null) {
                          await _firestoreService.sendFriendRequest(recipientId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Permintaan pertemanan terkirim ke ${user['nickname']}')),
                          );
                        }
                      },
                      icon: Icon(Icons.person_add, size: 18),
                      label: Text('Tambah'),
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