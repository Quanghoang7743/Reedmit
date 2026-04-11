import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/diary_entry.dart';
import '../services/diary_service.dart';
import 'Widget/liquid_glass.dart';
import 'app_diaryfull_screen.dart';

class AppCreateScreen extends StatefulWidget {
  const AppCreateScreen({super.key});

  @override
  State<AppCreateScreen> createState() => _AppCreateScreenState();
}

class _AppCreateScreenState extends State<AppCreateScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final DiaryService _diaryService = DiaryService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final Set<String> _reminderMethods = <String>{};

  DateTime _eventTime = DateTime.now();
  bool _reminderEnabled = false;
  int _reminderLeadDays = 0;
  File? _selectedImage;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) {
      return;
    }
    setState(() => _selectedImage = File(file.path));
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(1980),
      lastDate: DateTime(2100),
      initialDate: _eventTime,
    );

    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_eventTime),
    );

    if (time == null) {
      return;
    }

    setState(() {
      _eventTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _createDiary() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_reminderEnabled && _reminderMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy chọn ít nhất 1 cách nhắc lại.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bạn cần đăng nhập lại.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _diaryService.uploadDiaryImage(
          file: _selectedImage!,
          userId: user.uid,
        );
      }

      final diary = DiaryEntry(
        id: '',
        userId: user.uid,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        eventTime: _eventTime,
        reminderEnabled: _reminderEnabled,
        reminderMethods: _reminderMethods.toList(),
        reminderLeadDays: _reminderLeadDays,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final diaryId = await _diaryService.createDiary(diary);
      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AppDiaryFullScreen(diaryId: diaryId)),
      );
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể tạo nhật ký: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo nhật ký')),
      body: LiquidGlassBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: GlassPanel(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Tiêu đề'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tiêu đề.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contentController,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Nội dung nhật ký',
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng ghi nội dung nhật ký.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _pickDateTime,
                      icon: const Icon(Icons.schedule),
                      label: Text(
                        'Thời gian: ${_dateFormat.format(_eventTime)}',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Chọn hình ảnh'),
                    ),
                    if (_selectedImage != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          _selectedImage!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _reminderEnabled,
                      onChanged: (value) {
                        setState(() {
                          _reminderEnabled = value;
                          if (!value) {
                            _reminderMethods.clear();
                          }
                        });
                      },
                      title: const Text('Nhắc lại kỷ niệm'),
                    ),
                    if (_reminderEnabled) ...[
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _reminderMethods.contains('ringtone'),
                        onChanged: (value) => _toggleMethod('ringtone', value),
                        title: const Text('Nhắc bằng chuông điện thoại'),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _reminderMethods.contains('email'),
                        onChanged: (value) => _toggleMethod('email', value),
                        title: const Text('Nhắc qua email'),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _reminderMethods.contains('notification'),
                        onChanged: (value) =>
                            _toggleMethod('notification', value),
                        title: const Text('Nhắc qua thông báo'),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        initialValue: _reminderLeadDays,
                        decoration: const InputDecoration(
                          labelText: 'Thời điểm nhắc khi gần đến ngày sự kiện',
                        ),
                        items: const [0, 1, 3, 7, 30]
                            .map(
                              (days) => DropdownMenuItem<int>(
                                value: days,
                                child: Text(
                                  days == 0
                                      ? 'Nhắc đúng ngày'
                                      : 'Nhắc trước $days ngày',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _reminderLeadDays = value);
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _createDiary,
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Tạo nhật ký'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleMethod(String method, bool? isSelected) {
    setState(() {
      if (isSelected ?? false) {
        _reminderMethods.add(method);
      } else {
        _reminderMethods.remove(method);
      }
    });
  }
}
