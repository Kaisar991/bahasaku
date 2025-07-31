// File: lib/screens/friends_list_screen.dart

import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'profile_screen.dart'; // <-- IMPORT BARU

class FriendsListScreen extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Teman'),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _firestoreService.getFriendsList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'Anda belum memiliki teman.\nCari teman baru untuk ditambahkan!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final friends = snapshot.data!;

          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              final friendId = friend['uid']; // Ambil UID teman

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: Icon(Icons.person, color: Colors.green),
                  ),
                  title: Text(friend['nickname'] ?? 'Pengguna', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Level: ${friend['level'] ?? 1}'),
                  trailing: Text('${friend['xp'] ?? 0} XP', style: TextStyle(color: Colors.amber[800], fontWeight: FontWeight.bold)),
                  // --- TAMBAHAN BARU ---
                  onTap: () {
                    // Navigasi ke ProfileScreen dengan membawa ID teman
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(userId: friendId),
                      ),
                    );
                  },
                  // --------------------
                ),
              );
            },
          );
        },
      ),
    );
  }
}