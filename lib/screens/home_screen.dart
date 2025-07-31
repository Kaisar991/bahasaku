// File: lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/user_service.dart';
import '../services/mission_service.dart';
import '../widgets/daily_missions_card.dart';
import 'quiz_screen.dart';
import 'package:lottie/lottie.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService firestoreService = FirestoreService();
  final UserService userService = UserService();
  final MissionService missionService = MissionService(); // Ditambahkan

  String? selectedCategory;

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'salam & sapa':
        return Icons.waving_hand;
      case 'percakapan dasar':
        return Icons.message_outlined; // Ikon diubah agar lebih sesuai
      case 'kosakata dasar':
        return Icons.menu_book;
      case 'latihan tata bahasa':
        return Icons.edit_note;
      default:
        return Icons.school;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BahasaKu'),
        backgroundColor: Colors.orange.shade400,
        actions: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: firestoreService.getFriendRequestsStream(),
            builder: (context, snapshot) {
              final requestCount = snapshot.data?.length ?? 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.pushNamed(context, '/notifications').then((_) => setState(() {}));
                    },
                  ),
                  if (requestCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                        constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text('$requestCount', style: TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.leaderboard),
            onPressed: () => Navigator.pushNamed(context, '/leaderboard'),
          ),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile').then((_) {
                setState(() {});
              });
            },
          ),
        ],
      ),
      // --- BODY UTAMA DIPERBAIKI ---
      // Menggunakan FutureBuilder utama untuk mengambil semua data pengguna sekali saja
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: FutureBuilder<Map<String, dynamic>?>(
          future: userService.getUserData(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final userData = userSnapshot.data ?? {};
            final xp = userData['xp'] ?? 0;
            final level = userData['level'] ?? 1;
            // Ambil completedLessons dari snapshot yang sudah siap pakai
            final completedLessons = List<String>.from(userData['completedLessons'] ?? []);

            // Menggunakan ListView agar bisa di-scroll
            return ListView(
              children: [
                SizedBox(height: 12),
                SizedBox(height: 140, child: Lottie.asset('assets/lottie/home_ilus.json')),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Card(
                    color: Colors.yellow.shade100,
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Level: $level', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('XP: $xp', style: TextStyle(fontSize: 18)),
                        ],
                      ),
                    ),
                  ),
                ),

                // --- BAGIAN MISI HARIAN (BARU) ---
                FutureBuilder<List<Mission>>(
                  future: missionService.getOrGenerateDailyMissions(),
                  builder: (context, missionSnapshot) {
                    if (missionSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: Padding(padding: const EdgeInsets.all(8.0), child: CircularProgressIndicator()));
                    }
                    if (!missionSnapshot.hasData || missionSnapshot.data!.isEmpty) {
                      return SizedBox.shrink();
                    }
                    return DailyMissionsCard(
                      missions: missionSnapshot.data!,
                      onClaim: () => setState(() {}),
                    );
                  },
                ),

                SizedBox(height: 10),

                // Bagian Kategori
                FutureBuilder<List<String>>(
                  future: firestoreService.getLessonCategories(),
                  builder: (context, categorySnapshot) {
                    if (!categorySnapshot.hasData) return SizedBox(height: 50);
                    final categories = categorySnapshot.data!;
                    if (selectedCategory == null && categories.isNotEmpty) {
                      Future.microtask(() => setState(() => selectedCategory = categories.first));
                    }
                    return SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final isSelected = selectedCategory == cat;
                          return GestureDetector(
                            onTap: () => setState(() => selectedCategory = cat),
                            child: Container(
                              margin: EdgeInsets.only(right: 12),
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(color: isSelected ? Colors.orange : Colors.grey.shade300, borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                children: [
                                  Icon(_getIconForCategory(cat), color: isSelected ? Colors.white : Colors.black87, size: 20),
                                  SizedBox(width: 8),
                                  Text(cat, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                SizedBox(height: 10),

                // Bagian Daftar Pelajaran
                if (selectedCategory != null)
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: firestoreService.getLessonsByCategory(selectedCategory!),
                    builder: (context, lessonSnapshot) {
                      if (lessonSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (!lessonSnapshot.hasData || lessonSnapshot.data!.isEmpty) {
                        return Padding(padding: const EdgeInsets.all(20.0), child: Center(child: Text('Belum ada pelajaran di kategori ini.')));
                      }
                      final lessons = lessonSnapshot.data!;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        itemCount: lessons.length,
                        itemBuilder: (context, index) {
                          final lesson = lessons[index];
                          final lessonId = lesson['id'];
                          final title = lesson['title'] ?? 'Pelajaran';
                          // Gunakan 'completedLessons' yang sudah siap dari atas
                          final isUnlocked = index == 0 || (index > 0 && completedLessons.contains(lessons[index - 1]['id']));
                          return Card(
                            color: isUnlocked ? Colors.lightGreen.shade100 : Colors.grey.shade200,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isUnlocked ? Colors.black : Colors.grey[600])),
                              trailing: Icon(isUnlocked ? Icons.arrow_forward_ios : Icons.lock_outline, color: isUnlocked ? Colors.orange : Colors.grey),
                              enabled: isUnlocked,
                              onTap: isUnlocked ? () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(lessonId: lessonId))).then((_) {
                                  setState(() {});
                                });
                              } : null,
                            ),
                          );
                        },
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}