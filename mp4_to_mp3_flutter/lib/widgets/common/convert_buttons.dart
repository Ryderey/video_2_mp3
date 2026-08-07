import 'package:flutter/material.dart';
import '../../app_theme.dart';

/// 开始/停止转换按钮区域，两个 Tab 共用
class ConvertButtons extends StatelessWidget {
  final bool startEnabled;
  final bool isConverting;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const ConvertButtons({
    super.key,
    required this.startEnabled,
    required this.isConverting,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    if (isTablet) {
      // 平板：按钮横向排列
      return Row(
        children: [
          _buildStartButton(),
          const SizedBox(width: 20),
          _buildStopButton(),
        ],
      );
    }
    // 手机：按钮纵向排列，更宽
    return Column(
      children: [
        SizedBox(width: double.infinity, child: _buildStartButton()),
        const SizedBox(height: 14),
        SizedBox(width: double.infinity, child: _buildStopButton()),
      ],
    );
  }

  /// 开始转换按钮
  Widget _buildStartButton() {
    return ElevatedButton.icon(
      onPressed: (isConverting || !startEnabled) ? null : onStart,
      icon: const Icon(Icons.play_arrow, size: 30),
      label: const Text('开始转换'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFE3C9A6),
        disabledForegroundColor: Colors.white70,
        minimumSize: const Size(200, 68),
        textStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 停止转换按钮
  Widget _buildStopButton() {
    return ElevatedButton.icon(
      onPressed: isConverting ? onStop : null,
      icon: const Icon(Icons.stop, size: 30),
      label: const Text('停止转换'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.danger,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFD4A5A0),
        disabledForegroundColor: Colors.white70,
        minimumSize: const Size(200, 68),
        textStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
