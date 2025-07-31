// File: lib/widgets/arrange_sentence_card.dart (FILE BARU)

import 'package:flutter/material.dart';

class ArrangeSentenceCard extends StatefulWidget {
  // Kata-kata acak yang akan ditampilkan sebagai pilihan
  final List<String> wordOptions;
  // Fungsi yang akan dipanggil saat pengguna menekan tombol "Periksa"
  final void Function(String userAnswer) onCheckAnswer;

  const ArrangeSentenceCard({
    Key? key,
    required this.wordOptions,
    required this.onCheckAnswer,
  }) : super(key: key);

  @override
  _ArrangeSentenceCardState createState() => _ArrangeSentenceCardState();
}

class _ArrangeSentenceCardState extends State<ArrangeSentenceCard> {
  // Menyimpan kata-kata yang sudah dipilih pengguna
  List<String> _selectedWords = [];
  // Menyimpan kata-kata yang masih tersedia di "bank kata"
  late List<String> _availableWords;

  @override
  void initState() {
    super.initState();
    // Saat widget pertama kali dibuat, semua kata tersedia
    _availableWords = List.from(widget.wordOptions)..shuffle(); // Kita acak agar lebih menantang
  }

  // Fungsi saat pengguna mengetuk kata di "bank kata"
  void _selectWord(String word) {
    setState(() {
      _selectedWords.add(word);
      _availableWords.remove(word);
    });
  }

  // Fungsi saat pengguna mengetuk kata di kotak jawaban (untuk mengembalikan)
  void _unselectWord(String word) {
    setState(() {
      _selectedWords.remove(word);
      _availableWords.add(word);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 1. Kotak Jawaban
          Container(
            height: 100,
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _selectedWords.map((word) {
                return InkWell(
                  onTap: () => _unselectWord(word),
                  child: Chip(
                    label: Text(word),
                    backgroundColor: Colors.green.shade100,
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 24),

          // 2. Bank Kata (Pilihan)
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            alignment: WrapAlignment.center,
            children: _availableWords.map((word) {
              return InkWell(
                onTap: () => _selectWord(word),
                child: Chip(
                  label: Text(word, style: TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.grey.shade200,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 32),

          // 3. Tombol Periksa
          ElevatedButton(
            onPressed: _selectedWords.isEmpty
                ? null // Nonaktifkan tombol jika tidak ada kata yang dipilih
                : () {
              // Gabungkan kata-kata yang dipilih menjadi satu kalimat
              final userAnswer = _selectedWords.join(' ');
              widget.onCheckAnswer(userAnswer);
            },
            child: Text('Periksa Jawaban'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }
}