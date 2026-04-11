import 'package:flutter/material.dart';

class BtnCreateDiaryWidget extends StatelessWidget {
  const BtnCreateDiaryWidget({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_circle_outline),
      label: const Text('Tạo nhật ký'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    );
  }
}
