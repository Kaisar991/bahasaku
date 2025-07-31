// File: lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/question_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Fungsi Terkait Pelajaran (Sudah Benar) ---

  Future<List<Question>> getQuestions(String lessonId) async {
    final snapshot = await _db
        .collection('lessons')
        .doc(lessonId)
        .collection('questions')
        .get();
    return snapshot.docs.map((doc) => Question.fromMap(doc.data())).toList();
  }

  Future<List<String>> getLessonCategories() async {
    final snapshot = await _db.collection('lessons').get();
    final categories = snapshot.docs
        .map((doc) => doc['category'] as String?)
        .where((cat) => cat != null)
        .toSet()
        .cast<String>()
        .toList();
    return categories;
  }

  Future<List<Map<String, dynamic>>> getLessonsByCategory(String category) async {
    final snapshot = await _db
        .collection('lessons')
        .where('category', isEqualTo: category)
        .orderBy('title')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // --- Fungsi Terkait Pengguna & Papan Peringkat (Sudah Benar) ---

  Future<List<Map<String, dynamic>>> getUsersForLeaderboard() async {
    final snapshot = await _db
        .collection('users')
        .orderBy('xp', descending: true)
        .limit(100)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // --- Fungsi Terkait Fitur Sosial & Pertemanan ---

  Future<List<Map<String, dynamic>>> searchUsersByNickname(String query) async {
    if (query.isEmpty) {
      return [];
    }
    final snapshot = await _db
        .collection('users')
        .where('nickname', isGreaterThanOrEqualTo: query)
        .where('nickname', isLessThanOrEqualTo: query + '\uf8ff')
        .limit(10)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> sendFriendRequest(String recipientId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final recipientRef = _db.collection('users').doc(recipientId);
    await recipientRef.collection('friendRequests').doc(currentUser.uid).set({
      'senderId': currentUser.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // --- FUNGSI YANG DIPERBAIKI (MENGGUNAKAN STREAM) ---
  // Ganti getFriendRequests() yang lama dengan ini
  Stream<List<Map<String, dynamic>>> getFriendRequestsStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _db.collection('users').doc(currentUser.uid).collection('friendRequests').snapshots().asyncMap((snapshot) async {
      List<Map<String, dynamic>> requestsWithNickname = [];
      for (var doc in snapshot.docs) {
        final senderId = doc.data()['senderId'];
        final senderDoc = await _db.collection('users').doc(senderId).get();
        if (senderDoc.exists) {
          requestsWithNickname.add({
            'senderId': senderId,
            'senderNickname': senderDoc.data()?['nickname'] ?? 'Pengguna',
          });
        }
      }
      return requestsWithNickname;
    });
  }
  // ----------------------------------------------------

  Future<void> acceptFriendRequest(String senderId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final currentUserId = currentUser.uid;
    await _db.collection('users').doc(currentUserId).collection('friends').doc(senderId).set({'friendSince': Timestamp.now()});
    await _db.collection('users').doc(senderId).collection('friends').doc(currentUserId).set({'friendSince': Timestamp.now()});
    await _db.collection('users').doc(currentUserId).collection('friendRequests').doc(senderId).delete();
  }

  Future<void> declineFriendRequest(String senderId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    await _db.collection('users').doc(currentUser.uid).collection('friendRequests').doc(senderId).delete();
  }

  Future<List<Map<String, dynamic>>> getFriendsList() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];
    final friendsSnapshot = await _db.collection('users').doc(currentUser.uid).collection('friends').get();
    if (friendsSnapshot.docs.isEmpty) {
      return [];
    }
    List<String> friendIds = friendsSnapshot.docs.map((doc) => doc.id).toList();
    final friendsDataSnapshot = await _db.collection('users').where(FieldPath.documentId, whereIn: friendIds).get();
    return friendsDataSnapshot.docs.map((doc) => doc.data()).toList();
  }
}