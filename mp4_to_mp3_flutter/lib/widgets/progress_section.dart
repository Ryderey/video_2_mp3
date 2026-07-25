import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/conversion_provider.dart';

/// 进度条 + 状态显示区域
class ProgressSection extends StatelessWidget {
  const ProgressSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConversionProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 进度条
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 30,
                child: LinearProgressIndicator(
                  value: provider.progress,
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
              _getStatusText(provider),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
          ],
        );
      },
    );
  }

  String _getStatusText(ConversionProvider provider) {
    if (provider.isConverting) {
      return '${provider.completedCount} / ${provider.totalCount} 已完成';
    }
    if (provider.completedCount > 0 && provider.completedCount == provider.totalCount) {
      return '转换完成：成功 ${provider.successCount} 个，失败 ${provider.failCount} 个';
    }
    if (provider.totalCount > 0 && provider.completedCount > 0) {
      return '已停止（完成 ${provider.completedCount} / ${provider.totalCount}）';
    }
    return '等待开始';
  }
}
