import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/diary_entry.dart';
import '../services/diary_service.dart';
import '../services/firebase_auth_service.dart';
import 'Widget/btn_create_diary_widget.dart';
import 'Widget/liquid_glass.dart';
import 'app_create_screen.dart';
import 'app_diaryfull_screen.dart';

class AppDiaryScreen extends StatefulWidget {
  const AppDiaryScreen({super.key});

  @override
  State<AppDiaryScreen> createState() => _AppDiaryScreenState();
}

class _AppDiaryScreenState extends State<AppDiaryScreen> {
  final DiaryService _diaryService = DiaryService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy - HH:mm');

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Bạn chưa đăng nhập.')));
    }

    return Scaffold(
      body: LiquidGlassBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 88),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Nhật ký của bạn',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Đăng xuất',
                          onPressed: () => _authService.signOut(),
                          icon: const Icon(Icons.logout),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: StreamBuilder<List<DiaryEntry>>(
                        stream: _diaryService.watchDiaries(user.uid),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Lỗi tải dữ liệu: ${snapshot.error}'),
                            );
                          }

                          final diaries = snapshot.data ?? <DiaryEntry>[];
                          if (diaries.isEmpty) {
                            return const Center(
                              child: Text(
                                'Chưa có nhật ký nào.\nBấm "Tạo nhật ký" để bắt đầu.',
                                textAlign: TextAlign.center,
                              ),
                            );
                          }

                          return ListView.separated(
                            itemCount: diaries.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final diary = diaries[index];
                              return ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AppDiaryFullScreen(diaryId: diary.id),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.all(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      diary.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _dateFormat.format(diary.eventTime),
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      diary.content,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 16,
                bottom: 16,
                child: BtnCreateDiaryWidget(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AppCreateScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
