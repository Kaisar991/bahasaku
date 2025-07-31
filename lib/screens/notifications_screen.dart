// File: lib/screens/notifications_screen.dart

import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifikasi Pertemanan'),
        backgroundColor: Colors.green,
      ),
      // --- GANTI FutureBuilder MENJADI StreamBuilder ---
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.getFriendRequestsStream(), // Gunakan fungsi stream yang baru
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'Tidak ada permintaan pertemanan saat ini.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final requests = snapshot.data!;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final senderNickname = request['senderNickname'] ?? 'Pengguna';

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$senderNickname ingin berteman dengan Anda!',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () async {
                              // Tidak perlu setState karena stream akan otomatis update UI
                              await _firestoreService.declineFriendRequest(request['senderId']);
                            },
                            child: Text('Tolak'),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              // Tidak perlu setState karena stream akan otomatis update UI
                              await _firestoreService.acceptFriendRequest(request['senderId']);
                            },
                            child: Text('Terima'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}