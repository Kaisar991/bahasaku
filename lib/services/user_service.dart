// File: lib/services/user_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'mission_service.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MissionService _missionService = MissionService();

  Future<void> createInitialUserData({
    required User user,
    required String nickname,
  }) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await userRef.get();
    if (!snapshot.exists) {
      await userRef.set({
        'uid': user.uid,
        'email': user.email,
        'nickname': nickname,
        'xp': 0,
        'level': 1,
        'streak': 0,
        'completedLessons': <String>[],
        'badges': <String>[],
        'lastUpdate': null,
      });
    }
  }

  Future<void> updateNickname(String newNickname) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final userRef = _firestore.collection('users').doc(uid);
    await userRef.update({'nickname': newNickname});
  }

  // --- FUNGSI BARU YANG HILANG SEBELUMNYA ---
  // Fungsi untuk mengambil data pengguna berdasarkan ID tertentu
  Future<Map<String, dynamic>?> getUserDataById(String userId) async {
    if (userId.isEmpty) return null;
    final snapshot = await _firestore.collection('users').doc(userId).get();
    return snapshot.data();
  }
  // ---------------------------------------------

  bool _isDifferentDay(DateTime date1, DateTime date2) {
    return date1.year != date2.year || date1.month != date2.month || date1.day != date2.day;
  }

  Future<void> updateUserProgress({
    required String lessonId,
    required int xpGained,
    required bool isPerfectScore,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userRef = _firestore.collection('users').doc(uid);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final now = DateTime.now();

      final currentXP = data['xp'] ?? 0;
      final completedLessons = List<String>.from(data['completedLessons'] ?? []);
      int currentStreak = data['streak'] ?? 0;
      final lastUpdateTimestamp = data['lastUpdate'] as Timestamp?;
      final lastUpdate = lastUpdateTimestamp?.toDate();

      if (lastUpdate != null) {
        if (_isDifferentDay(now, lastUpdate) && now.difference(lastUpdate).inDays == 1) {
          currentStreak++;
        } else if (_isDifferentDay(now, lastUpdate) && now.difference(lastUpdate).inDays > 1) {
          currentStreak = 1;
        }
      } else {
        currentStreak = 1;
      }

      final newXP = currentXP + xpGained;
      final newLevel = 1 + (newXP ~/ 100);
      if (!completedLessons.contains(lessonId)) {
        completedLessons.add(lessonId);
      }

      final missionsRef = userRef.collection('dailyMissions').doc('missions');
      final missionSnapshot = await transaction.get(missionsRef);
      if (missionSnapshot.exists) {
        final missionData = missionSnapshot.data()!;
        final missions = List<Map<String, dynamic>>.from(missionData['missions'])
            .map((m) => Mission.fromMap(m))
            .toList();

        for (var mission in missions) {
          if (!mission.isCompleted) {
            if (mission.id == 'complete_1_lesson') mission.progress += 1;
            if (mission.id == 'earn_50_xp') mission.progress += xpGained;
            if (mission.id == 'perfect_score' && isPerfectScore) mission.progress += 1;
            if (mission.progress >= mission.target) mission.isCompleted = true;
          }
        }
        transaction.update(missionsRef, {'missions': missions.map((m) => m.toMap()).toList()});
      }

      transaction.update(userRef, {
        'xp': newXP,
        'level': newLevel,
        'completedLessons': completedLessons,
        'streak': currentStreak,
        'lastUpdate': Timestamp.fromDate(now),
        // Lencana dan field lain jika ada
      });
    });
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final snapshot = await _firestore.collection('users').doc(uid).get();
    return snapshot.data();
  }
}