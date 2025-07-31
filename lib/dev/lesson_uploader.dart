import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LessonUploader extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- DATA DENGAN TIPE SOAL YANG SUDAH DICAMPUR ---
  final List<Map<String, dynamic>> lessons = [
    {
      "id": "lesson1",
      "title": "Salam Dasar",
      "category": "Salam & Sapa",
      "questions": [
        {
          "type": "multiple_choice",
          "question": "Apa arti \"HALO\"",
          "options": ["halo", "selamat tinggal", "maaf"],
          "answer": "halo"
        },
        // Soal Susun Kalimat disisipkan di sini
        {
          "type": "arrange_sentence",
          "answer": "selamat pagi",
          "options": ["pagi", "selamat"],
        },
        {
          "type": "multiple_choice",
          "question": "Apa arti \"TERIMA KASIH\"",
          "options": ["selamat", "terima kasih", "iya"],
          "answer": "terima kasih"
        },
      ]
    },
    {
      "id": "lesson2",
      "title": "Salam Lanjut",
      "category": "Salam & Sapa",
      "questions": [
        {
          "type": "multiple_choice",
          "question": "Apa arti \"MAAF\"",
          "options": ["maaf", "terima kasih", "iya"],
          "answer": "maaf"
        },
        {
          "type": "arrange_sentence",
          "answer": "sampai jumpa lagi",
          "options": ["lagi", "sampai", "jumpa"],
        },
      ]
    },
    {
      "id": "lesson3",
      "title": "Perkenalan Diri",
      "category": "Percakapan Dasar",
      "questions": [
        {
          "type": "multiple_choice",
          "question": "Bagaimana Anda menanyakan nama seseorang?",
          "options": ["Siapa nama kamu?", "Dari mana kamu?", "Apa kabar?"],
          "answer": "Siapa nama kamu?"
        },
        {
          "type": "arrange_sentence",
          "answer": "nama saya budi",
          "options": ["budi", "nama", "saya"],
        },
        {
          "type": "multiple_choice",
          "question": "Kalimat 'Saya berasal dari Indonesia' digunakan untuk...",
          "options": ["Menyatakan asal", "Menyatakan umur", "Memberi salam"],
          "answer": "Menyatakan asal"
        },
      ]
    },
    // Anda bisa melanjutkan pola ini untuk pelajaran lainnya
  ];

  void uploadLessons(BuildContext context) async {
    final WriteBatch batch = _firestore.batch();
    try {
      // Hapus semua data lama untuk memastikan kebersihan data
      final snapshot = await _firestore.collection('lessons').get();
      for (var doc in snapshot.docs) {
        // Anda juga perlu menghapus subkoleksi questions secara manual atau dengan script terpisah
        // Untuk sekarang, kita fokus pada upload data baru
        batch.delete(doc.reference);
      }

      for (var lessonData in lessons) {
        final lessonId = lessonData['id'];
        final lessonDocRef = _firestore.collection('lessons').doc(lessonId);
        batch.set(lessonDocRef, {
          'title': lessonData['title'],
          'category': lessonData['category'],
        });
        final questions = lessonData['questions'] as List<Map<String, dynamic>>;
        for (var questionData in questions) {
          final questionDocRef = lessonDocRef.collection('questions').doc();
          batch.set(questionDocRef, questionData);
        }
      }
      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Pelajaran dengan tipe soal campuran berhasil diunggah!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Gagal mengunggah: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Uploader Pelajaran')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => uploadLessons(context),
          child: Text('Unggah Ulang Semua Pelajaran'),
        ),
      ),
    );
  }
}