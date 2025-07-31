import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';

import '../services/user_service.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final userService = UserService();
  final authService = AuthService();
  Uint8List? profileImageBytes;
  final nicknameController = TextEditingController();
  late Future<Map<String, dynamic>?> _userDataFuture;
  late bool _isMyProfile;

  @override
  void initState() {
    super.initState();
    _isMyProfile = widget.userId == null || widget.userId == FirebaseAuth.instance.currentUser?.uid;

    if (_isMyProfile) {
      _userDataFuture = userService.getUserData();
      loadProfileImage();
    } else {
      _userDataFuture = userService.getUserDataById(widget.userId!);
    }
  }

  Future<void> loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final base64Image = prefs.getString('profile_image_base64');
    if (base64Image != null && mounted) {
      setState(() => profileImageBytes = base64Decode(base64Image));
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      final base64Image = base64Encode(bytes);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_base64', base64Image);
      if (mounted) setState(() => profileImageBytes = bytes);
    }
  }

  Future<void> _showEditNicknameDialog(BuildContext context, String currentNickname) async {
    nicknameController.text = currentNickname;
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ubah Nama Panggilan'),
          content: TextField(controller: nicknameController, decoration: InputDecoration(hintText: "Masukkan nama panggilan baru")),
          actions: <Widget>[
            TextButton(child: Text('Batal'), onPressed: () => Navigator.pop(context)),
            TextButton(
              child: Text('Simpan'),
              onPressed: () async {
                if (nicknameController.text.trim().isNotEmpty) {
                  await userService.updateNickname(nicknameController.text.trim());
                  Navigator.pop(context);
                  setState(() {
                    _userDataFuture = userService.getUserData();
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _logout(BuildContext context) async {
    await authService.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isMyProfile ? 'Profil Kamu' : 'Profil Pengguna', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('Gagal memuat data pengguna.'));
          }

          final data = snapshot.data!;
          final nickname = data['nickname'] ?? 'Pengguna';
          final level = data['level'] ?? 1;
          final xp = data['xp'] ?? 0;
          final streak = data['streak'] ?? 0;
          final progress = (xp % 100) / 100.0;
          final List<String> badges = List<String>.from(data['badges'] ?? []);

          return ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.green[100],
                      backgroundImage: _isMyProfile && profileImageBytes != null ? MemoryImage(profileImageBytes!) : null,
                      child: !_isMyProfile || profileImageBytes == null ? Icon(Icons.person, size: 60, color: Colors.green) : null,
                    ),
                    if (_isMyProfile)
                      GestureDetector(
                        onTap: pickImage,
                        child: CircleAvatar(radius: 20, backgroundColor: Colors.white, child: Icon(Icons.edit, size: 20, color: Colors.green)),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(nickname, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  if (_isMyProfile)
                    IconButton(
                      icon: Icon(Icons.edit, size: 20, color: Colors.grey),
                      onPressed: () => _showEditNicknameDialog(context, nickname),
                    ),
                ],
              ),
              Center(child: Text(data['email'] ?? '', style: TextStyle(fontSize: 14, color: Colors.grey))),
              SizedBox(height: 24),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Icon(Icons.local_fire_department, color: Colors.orange, size: 30),
                          SizedBox(height: 8),
                          Text('$streak Hari', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Streak', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                      Column(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 30),
                          SizedBox(height: 8),
                          Text('Level $level', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Peringkat', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              if (_isMyProfile)
                Row(
                  children: [
                    Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.pushNamed(context, '/friends_list'), icon: Icon(Icons.people), label: Text('Teman'), style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.green), foregroundColor: Colors.green))),
                    SizedBox(width: 10),
                    Expanded(child: ElevatedButton.icon(onPressed: () => Navigator.pushNamed(context, '/find_friends'), icon: Icon(Icons.person_add), label: Text('Cari'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white))),
                  ],
                ),
              if (_isMyProfile) SizedBox(height: 24),
              Text('Progress Level Berikutnya', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              LinearProgressIndicator(value: progress, minHeight: 14, backgroundColor: Colors.grey[300], valueColor: AlwaysStoppedAnimation<Color>(Colors.green), borderRadius: BorderRadius.circular(8)),
              SizedBox(height: 8),
              Center(child: Text('${xp % 100} / 100 XP', style: TextStyle(fontSize: 16))),
              SizedBox(height: 32),
              Text('Pencapaian', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              badges.isEmpty
                  ? Card(
                color: Colors.grey[200],
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Text('Belum ada pencapaian.\nTerus belajar!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                  ),
                ),
              )
                  : GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: badges.length,
                itemBuilder: (context, index) {
                  final badgeName = badges[index];
                  final lottiePath = 'assets/lottie/$badgeName.json';

                  return Column(
                    children: [
                      Expanded(
                        child: Tooltip(
                          message: badgeName.replaceAll('_', ' ').toUpperCase(),
                          child: Lottie.asset(
                            lottiePath,
                            repeat: true,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        badgeName.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
              if (_isMyProfile) ...[
                SizedBox(height: 40),
                TextButton.icon(
                  onPressed: () => _logout(context),
                  icon: Icon(Icons.logout, color: Colors.red),
                  label: Text('Keluar (Logout)', style: TextStyle(color: Colors.red)),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.red.shade100),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
