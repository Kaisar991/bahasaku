// File: lib/screens/leaderboard_screen.dart

import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'profile_screen.dart'; // <-- IMPORT BARU

class LeaderboardScreen extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Papan Peringkat 🏆'),
        backgroundColor: Colors.amber,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _firestoreService.getUsersForLeaderboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Belum ada data untuk ditampilkan.'));
          }

          final users = snapshot.data!;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final userId = user['uid']; // Ambil UID pengguna
              final rank = index + 1;
              final nickname = user['nickname'] ?? 'Pengguna';
              final xp = user['xp'] ?? 0;

              Widget rankIcon;
              if (rank == 1) {
                rankIcon = Icon(Icons.emoji_events, color: Colors.amber[700]);
              } else if (rank == 2) {
                rankIcon = Icon(Icons.emoji_events, color: Colors.grey[400]);
              } else if (rank == 3) {
                rankIcon = Icon(Icons.emoji_events, color: Colors.brown[400]);
              } else {
                rankIcon = Text('$rank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16));
              }

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.amber[100],
                    child: rankIcon,
                  ),
                  title: Text(nickname, style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text('$xp XP', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                  // --- TAMBAHAN BARU ---
                  onTap: () {
                    // Navigasi ke ProfileScreen dengan membawa ID pengguna
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(userId: userId),
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