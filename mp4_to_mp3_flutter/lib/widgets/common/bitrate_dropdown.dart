import 'package:flutter/material.dart';
import '../../app_theme.dart';

/// 音质下拉选择（128 / 192 / 320 kbps），两个 Tab 共用
class BitrateDropdown extends StatelessWidget {
  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const BitrateDropdown({
    super.key,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '音质：',
          style: TextStyle(
            fontSize: AppTheme.fontSizeBody,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF8A94A0), width: 2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeBody,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
              items: const [
                DropdownMenuItem(value: 128, child: Text('128 kbps')),
                DropdownMenuItem(value: 192, child: Text('192 kbps')),
                DropdownMenuItem(value: 320, child: Text('320 kbps')),
              ],
              onChanged: enabled
                  ? (v) {
                      if (v != null) onChanged(v);
                    }
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
