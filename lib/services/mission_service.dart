// File: lib/services/mission_service.dart (FILE BARU)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Cetakan untuk sebuah misi
class Mission {
  final String id;
  final String title;
  final int target; // Target yang harus dicapai (misal: selesaikan 3 pelajaran)
  int progress; // Progres saat ini
  bool isCompleted; // Apakah sudah selesai
  bool isClaimed; // Apakah hadiah sudah diambil

  Mission({
    required this.id,
    required this.title,
    required this.target,
    this.progress = 0,
    this.isCompleted = false,
    this.isClaimed = false,
  });

  // Untuk mengubah dari data Firestore menjadi objek Mission
  factory Mission.fromMap(Map<String, dynamic> data) {
    return Mission(
      id: data['id'],
      title: data['title'],
      target: data['target'],
      progress: data['progress'] ?? 0,
      isCompleted: data['isCompleted'] ?? false,
      isClaimed: data['isClaimed'] ?? false,
    );
  }

  // Untuk menyimpan data ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'target': target,
      'progress': progress,
      'isCompleted': isCompleted,
      'isClaimed': isClaimed,
    };
  }
}

class MissionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Daftar semua kemungkinan misi harian
  final List<Mission> _dailyMissionsPool = [
    Mission(id: 'complete_1_lesson', title: 'Selesaikan 1 pelajaran', target: 1),
    Mission(id: 'earn_50_xp', title: 'Dapatkan 50 XP', target: 50),
    Mission(id: 'perfect_score', title: 'Dapat skor sempurna di 1 kuis', target: 1),
  ];

  // Fungsi untuk mendapatkan atau membuat misi harian untuk pengguna
  Future<List<Mission>> getOrGenerateDailyMissions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final userRef = _firestore.collection('users').doc(user.uid);
    final missionsRef = userRef.collection('dailyMissions').doc('missions');
    final missionSnapshot = await missionsRef.get();
    final now = DateTime.now();

    // Cek apakah misi hari ini sudah ada
    if (missionSnapshot.exists) {
      final data = missionSnapshot.data()!;
      final lastGenerated = (data['lastGenerated'] as Timestamp).toDate();

      // Jika tanggalnya masih sama, kembalikan misi yang ada
      if (now.day == lastGenerated.day && now.month == lastGenerated.month && now.year == lastGenerated.year) {
        final missionsData = List<Map<String, dynamic>>.from(data['missions']);
        return missionsData.map((m) => Mission.fromMap(m)).toList();
      }
    }

    // Jika belum ada atau sudah hari baru, buat misi baru
    _dailyMissionsPool.shuffle(); // Acak daftar misi
    final newMissions = _dailyMissionsPool.take(2).toList(); // Ambil 2 misi acak

    await missionsRef.set({
      'lastGenerated': Timestamp.fromDate(now),
      'missions': newMissions.map((m) => m.toMap()).toList(),
    });

    return newMissions;
  }

  Future<void> claimMissionReward(Mission missionToClaim) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    final missionsRef = userRef.collection('dailyMissions').doc('missions');

    await _firestore.runTransaction((transaction) async {
      final missionSnapshot = await transaction.get(missionsRef);
      final userSnapshot = await transaction.get(userRef);

      if (missionSnapshot.exists && userSnapshot.exists) {
        // 1. Update status misi menjadi sudah diklaim
        final missions = List<Map<String, dynamic>>.from(missionSnapshot.data()!['missions'])
            .map((m) => Mission.fromMap(m))
            .toList();

        final missionIndex = missions.indexWhere((m) => m.id == missionToClaim.id);
        if (missionIndex != -1) {
          missions[missionIndex].isClaimed = true;
          transaction.update(missionsRef, {'missions': missions.map((m) => m.toMap()).toList()});
        }

        // 2. Tambahkan hadiah XP ke pengguna
        final currentXP = userSnapshot.data()!['xp'] ?? 0;
        final newXP = currentXP + 25; // Hadiah 25 XP
        transaction.update(userRef, {'xp': newXP});
      }
    });
  }
}