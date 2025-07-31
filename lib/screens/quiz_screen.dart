import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../models/question_model.dart';
import '../services/firestore_service.dart';
import '../services/user_service.dart';
import '../widgets/question_card.dart';
import '../widgets/arrange_sentence_card.dart';
import '../utils/lottie_loader.dart';

class QuizScreen extends StatefulWidget {
  final String lessonId;

  QuizScreen({required this.lessonId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final UserService _userService = UserService();
  final FirestoreService _firestoreService = FirestoreService();

  late Future<List<dynamic>> _dataLoadingFuture;
  int _initialLevel = 1;

  int currentIndex = 0;
  int score = 0;
  bool quizFinished = false;
  bool showWrong = false;
  String correctAnswer = '';
  List<Question> questions = [];

  @override
  void initState() {
    super.initState();
    _dataLoadingFuture = Future.wait([
      _firestoreService.getQuestions(widget.lessonId),
      _userService.getUserData(),
    ]);
  }

  void _showLevelUpDialog(BuildContext context, int newLevel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(child: Text('NAIK LEVEL!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[800]))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset('assets/lottie/level_up.json', width: 150, height: 150, repeat: false),
            SizedBox(height: 16),
            Text('Selamat! Anda mencapai Level $newLevel', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
          ],
        ),
        actions: [
          Center(child: TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Lanjutkan'))),
        ],
      ),
    );
  }

  void checkAnswer(String userAnswer, String correctAnswer) async {
    if (userAnswer.toLowerCase().trim() == correctAnswer.toLowerCase().trim()) {
      setState(() {
        score++;
        _moveToNextQuestion();
      });
    } else {
      setState(() {
        showWrong = true;
        this.correctAnswer = correctAnswer;
      });
      await Future.delayed(Duration(seconds: 2));
      setState(() {
        showWrong = false;
        _moveToNextQuestion();
      });
    }
  }

  void _moveToNextQuestion() {
    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
      });
    } else {
      setState(() {
        quizFinished = true;
      });
    }
  }

  void _handleQuizCompletion(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // --- BAGIAN YANG DIPERBAIKI ---
      // Menambahkan parameter 'isPerfectScore' yang dibutuhkan oleh UserService
      await _userService.updateUserProgress(
        lessonId: widget.lessonId,
        xpGained: score * 10,
        isPerfectScore: score == questions.length, // <-- BARIS KUNCI
      );
      // -----------------------------

      final updatedUserData = await _userService.getUserData();
      final newLevel = updatedUserData?['level'] ?? _initialLevel;
      if (newLevel > _initialLevel) {
        if(mounted) _showLevelUpDialog(context, newLevel);
      }
    });
  }

  void _resetQuiz() {
    setState(() {
      currentIndex = 0;
      score = 0;
      quizFinished = false;
      questions = [];
      _dataLoadingFuture = Future.wait([
        _firestoreService.getQuestions(widget.lessonId),
        _userService.getUserData(),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kuis')),
      body: FutureBuilder<List<dynamic>>(
        future: _dataLoadingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return LottieLoader(path: 'assets/lottie/loading.json');
          } else if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Gagal memuat soal: ${snapshot.error}'));
          }

          if (questions.isEmpty) {
            questions = snapshot.data![0] as List<Question>;
            final userData = snapshot.data![1] as Map<String, dynamic>?;
            if (userData != null) {
              _initialLevel = userData['level'] ?? 1;
            }
          }

          if (quizFinished) {
            _handleQuizCompletion(context);
            return Container(
              padding: EdgeInsets.all(24.0),
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Lottie.asset(
                    score == questions.length ? 'assets/lottie/success.json' : 'assets/lottie/wrong.json',
                    height: 180,
                  ),
                  SizedBox(height: 24),
                  Text(
                    score == questions.length ? 'Kerja Bagus!' : 'Nyaris Sempurna!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Skor Anda: $score / ${questions.length}',
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Selesai'),
                    ),
                  ),
                  SizedBox(height: 12),
                  if (score < questions.length)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _resetQuiz,
                        child: Text('Ulangi Kuis'),
                        style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.orange)),
                      ),
                    ),
                ],
              ),
            );
          }

          if (showWrong) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LottieLoader(path: 'assets/lottie/wrong.json'),
                SizedBox(height: 16),
                Text('Jawaban Salah!', style: TextStyle(fontSize: 20, color: Colors.red, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Jawaban yang benar: $correctAnswer', style: TextStyle(fontSize: 16)),
              ],
            );
          }

          final currentQuestion = questions[currentIndex];
          Widget questionWidget;

          if (currentQuestion.type == 'arrange_sentence') {
            questionWidget = ArrangeSentenceCard(
              wordOptions: currentQuestion.options,
              onCheckAnswer: (userAnswer) {
                checkAnswer(userAnswer, currentQuestion.answer);
              },
            );
          } else {
            questionWidget = QuestionCard(
              question: currentQuestion,
              onAnswerSelected: (selectedOption) {
                checkAnswer(selectedOption, currentQuestion.answer);
              },
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
                  child: Text('Soal ${currentIndex + 1} dari ${questions.length}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                questionWidget,
              ],
            ),
          );
        },
      ),
    );
  }
}