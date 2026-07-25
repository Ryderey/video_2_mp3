import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/conversion_provider.dart';

/// 转换控制按钮区域
class ConvertControls extends StatelessWidget {
  const ConvertControls({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Consumer<ConversionProvider>(
      builder: (context, provider, child) {
        if (isTablet) {
          // 平板：按钮横向排列
          return Row(
            children: [
              _buildStartButton(provider),
              const SizedBox(width: 20),
              _buildStopButton(provider),
            ],
          );
        }
        // 手机：按钮纵向排列，更宽
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: _buildStartButton(provider),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: _buildStopButton(provider),
            ),
          ],
        );
      },
    );
  }

  /// 开始转换按钮
  Widget _buildStartButton(ConversionProvider provider) {
    return ElevatedButton.icon(
      onPressed: (provider.isConverting || provider.fileCount == 0)
          ? null
          : () => provider.startConversion(),
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
  Widget _buildStopButton(ConversionProvider provider) {
    return ElevatedButton.icon(
      onPressed: provider.isConverting ? () => provider.stopConversion() : null,
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
