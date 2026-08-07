import 'package:flutter/material.dart';
import '../app_theme.dart';

/// 进度条 + 状态显示区域，两个 Tab 共用（纯参数化）
class ProgressSection extends StatelessWidget {
  final double progress;
  final bool isConverting;
  final int completedCount;
  final int totalCount;
  final int successCount;
  final int failCount;

  const ProgressSection({
    super.key,
    required this.progress,
    required this.isConverting,
    required this.completedCount,
    required this.totalCount,
    required this.successCount,
    required this.failCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 进度条
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 30,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.success),
              minHeight: 30,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // 状态文字
        Text(
          _getStatusText(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
      ],
    );
  }

  String _getStatusText() {
    if (isConverting) {
      return '$completedCount / $totalCount 已完成';
    }
    if (completedCount > 0 && completedCount == totalCount) {
      return '转换完成：成功 $successCount 个，失败 $failCount 个';
    }
    if (totalCount > 0 && completedCount > 0) {
      return '已停止（完成 $completedCount / $totalCount）';
    }
    return '等待开始';
  }
}
