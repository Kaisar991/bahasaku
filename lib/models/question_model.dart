// File: lib/models/question_model.dart

class Question {
  final String? question; // Dibuat opsional (bisa null)
  final List<String> options;
  final String answer;
  final String type; // Field baru untuk tipe soal

  Question({
    this.question,
    required this.options,
    required this.answer,
    required this.type,
  });

  factory Question.fromMap(Map<String, dynamic> data) {
    return Question(
      // Ambil 'type' dari data, default-nya 'multiple_choice' jika tidak ada
      type: data['type'] ?? 'multiple_choice',
      // 'question' bisa null jika tipenya bukan multiple_choice
      question: data['question'],
      options: List<String>.from(data['options']),
      answer: data['answer'],
    );
  }
}