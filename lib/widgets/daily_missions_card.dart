// File: lib/widgets/daily_missions_card.dart (FILE BARU)

import 'package:flutter/material.dart';
import '../services/mission_service.dart';

class DailyMissionsCard extends StatefulWidget {
  final List<Mission> missions;
  final VoidCallback onClaim; // Fungsi untuk refresh setelah klaim

  const DailyMissionsCard({Key? key, required this.missions, required this.onClaim}) : super(key: key);

  @override
  _DailyMissionsCardState createState() => _DailyMissionsCardState();
}

class _DailyMissionsCardState extends State<DailyMissionsCard> {
  final MissionService _missionService = MissionService();

  void _claimReward(Mission mission) async {
    // Panggil fungsi untuk klaim hadiah
    await _missionService.claimMissionReward(mission);

    // Beri tahu HomeScreen untuk refresh
    widget.onClaim();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Hadiah 25 XP berhasil diklaim!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Misi Harian 🎯',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ...widget.missions.map((mission) {
              final progress = (mission.progress / mission.target).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(mission.title, style: TextStyle(fontWeight: FontWeight.w500)),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: progress,
                                  borderRadius: BorderRadius.circular(8),
                                  minHeight: 8,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('${mission.progress}/${mission.target}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    // Tombol Klaim
                    ElevatedButton(
                      onPressed: mission.isCompleted && !mission.isClaimed
                          ? () => _claimReward(mission)
                          : null, // Nonaktifkan jika belum selesai atau sudah diklaim
                      child: Text(mission.isClaimed ? 'Selesai' : 'Klaim'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mission.isClaimed ? Colors.grey : Colors.amber,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}