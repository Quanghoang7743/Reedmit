import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/diary_entry.dart';
import '../services/diary_service.dart';
import 'Widget/liquid_glass.dart';

class AppDiaryFullScreen extends StatefulWidget {
  const AppDiaryFullScreen({super.key, required this.diaryId});

  final String diaryId;

  @override
  State<AppDiaryFullScreen> createState() => _AppDiaryFullScreenState();
}

class _AppDiaryFullScreenState extends State<AppDiaryFullScreen> {
  final DiaryService _diaryService = DiaryService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  bool _isEditing = false;
  bool _isSaving = false;
  bool _reminderEnabled = false;
  int _reminderLeadDays = 0;
  DateTime _eventTime = DateTime.now();
  final Set<String> _reminderMethods = <String>{};
  File? _newImage;
  String? _activeImageUrl;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _bindEntry(DiaryEntry entry) {
    _titleController.text = entry.title;
    _contentController.text = entry.content;
    _eventTime = entry.eventTime;
    _reminderEnabled = entry.reminderEnabled;
    _reminderLeadDays = entry.reminderLeadDays;
    _reminderMethods
      ..clear()
      ..addAll(entry.reminderMethods);
    _activeImageUrl = entry.imageUrl;
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _eventTime,
      firstDate: DateTime(1980),
      lastDate: DateTime(2100),
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) {
      return;
    }
    setState(() => _newImage = File(picked.path));
  }

  Future<void> _saveDiary(DiaryEntry original) async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tiêu đề và nội dung không được để trống.'),
        ),
      );
      return;
    }

    if (_reminderEnabled && _reminderMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy chọn ít nhất 1 hình thức nhắc lại.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? imageUrl = _activeImageUrl;
      if (_newImage != null) {
        imageUrl = await _diaryService.uploadDiaryImage(
          file: _newImage!,
          userId: original.userId,
        );
      }

      final updated = original.copyWith(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        eventTime: _eventTime,
        reminderEnabled: _reminderEnabled,
        reminderMethods: _reminderMethods.toList(),
        reminderLeadDays: _reminderLeadDays,
        imageUrl: imageUrl,
      );

      await _diaryService.updateDiary(updated);
      if (!mounted) {
        return;
      }

      setState(() {
        _isEditing = false;
        _newImage = null;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể cập nhật nhật ký: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết nhật ký')),
      body: LiquidGlassBackground(
        child: StreamBuilder<DiaryEntry?>(
          stream: _diaryService.watchDiary(widget.diaryId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Lỗi: ${snapshot.error}'));
            }

            final diary = snapshot.data;
            if (diary == null) {
              return const Center(child: Text('Không tìm thấy nhật ký.'));
            }

            if (!_isEditing) {
              _bindEntry(diary);
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _isEditing ? 'Chỉnh sửa nhật ký' : diary.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : () {
                                  setState(() {
                                    _isEditing = !_isEditing;
                                    if (!_isEditing) {
                                      _bindEntry(diary);
                                      _newImage = null;
                                    }
                                  });
                                },
                          child: Text(_isEditing ? 'Hủy' : 'Chỉnh sửa'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_isEditing)
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Tiêu đề'),
                      )
                    else
                      Text(
                        'Thời gian: ${_dateFormat.format(diary.eventTime)}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    const SizedBox(height: 12),
                    if (_isEditing)
                      TextField(
                        controller: _contentController,
                        maxLines: 7,
                        decoration: const InputDecoration(
                          labelText: 'Nội dung nhật ký',
                          alignLabelWithHint: true,
                        ),
                      )
                    else
                      Text(
                        diary.content,
                        style: const TextStyle(fontSize: 16, height: 1.45),
                      ),
                    const SizedBox(height: 16),
                    if (_isEditing)
                      ElevatedButton.icon(
                        onPressed: _pickDateTime,
                        icon: const Icon(Icons.edit_calendar),
                        label: Text(
                          'Thời gian: ${_dateFormat.format(_eventTime)}',
                        ),
                      )
                    else
                      Text(
                        'Cập nhật lần cuối: ${_dateFormat.format(diary.updatedAt)}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    const SizedBox(height: 12),
                    if (_newImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          _newImage!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    else if (_activeImageUrl != null &&
                        _activeImageUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          _activeImageUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    if (_isEditing) ...[
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text('Đổi ảnh'),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: _reminderEnabled,
                        onChanged: (value) =>
                            setState(() => _reminderEnabled = value),
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Nhắc lại kỷ niệm'),
                      ),
                      if (_reminderEnabled) ...[
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _reminderMethods.contains('ringtone'),
                          onChanged: (value) =>
                              _toggleMethod('ringtone', value),
                          title: const Text('Chuông điện thoại'),
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _reminderMethods.contains('email'),
                          onChanged: (value) => _toggleMethod('email', value),
                          title: const Text('Email'),
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _reminderMethods.contains('notification'),
                          onChanged: (value) =>
                              _toggleMethod('notification', value),
                          title: const Text('Thông báo'),
                        ),
                        DropdownButtonFormField<int>(
                          initialValue: _reminderLeadDays,
                          decoration: const InputDecoration(
                            labelText: 'Thời điểm nhắc',
                          ),
                          items: const [0, 1, 3, 7, 30]
                              .map(
                                (day) => DropdownMenuItem<int>(
                                  value: day,
                                  child: Text(
                                    day == 0
                                        ? 'Nhắc đúng ngày'
                                        : 'Nhắc trước $day ngày',
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
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : () => _saveDiary(diary),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Lưu chỉnh sửa'),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      Text(
                        diary.reminderEnabled
                            ? 'Nhắc lại: ${diary.reminderMethods.join(', ')} | Trước ${diary.reminderLeadDays} ngày'
                            : 'Nhắc lại: Tắt',
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _toggleMethod(String key, bool? checked) {
    setState(() {
      if (checked ?? false) {
        _reminderMethods.add(key);
      } else {
        _reminderMethods.remove(key);
      }
    });
  }
}
