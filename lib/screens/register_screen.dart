// File: lib/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class RegisterScreen extends StatelessWidget {
  final nicknameController = TextEditingController(); // <-- KONTROLER BARU
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  void register(BuildContext context) async {
    // Validasi sederhana agar nama panggilan tidak kosong
    if (nicknameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nama panggilan tidak boleh kosong!')),
      );
      return;
    }

    final user = await _authService.register(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    if (user != null) {
      // Saat buat data awal, sertakan juga nama panggilan
      await _userService.createInitialUserData(
        user: user,
        nickname: nicknameController.text.trim(), // <-- KIRIM NAMA PANGGILAN
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registrasi berhasil. Silakan login!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registrasi gagal')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF3E0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Lottie.asset(
                'assets/lottie/login_ilus.json',
                height: 180, // Sedikit lebih kecil
              ),
              SizedBox(height: 16),
              Text('Daftar Akun Baru ✨', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
              SizedBox(height: 8),
              Text('Yuk mulai belajar dengan akun baru!', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14)),
              SizedBox(height: 32),

              // --- KOLOM ISIAN NAMA PANGGILAN (BARU) ---
              TextField(
                controller: nicknameController,
                decoration: InputDecoration(
                  labelText: 'Nama Panggilan',
                  prefixIcon: Icon(Icons.person_outline),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              SizedBox(height: 16),
              // ------------------------------------------

              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => register(context),
                child: Text('Daftar'),
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Sudah punya akun? Masuk', style: GoogleFonts.poppins(color: Colors.deepOrange)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}