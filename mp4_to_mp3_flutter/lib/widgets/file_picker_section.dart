import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/conversion_provider.dart';

/// 文件选择区域（无需权限前置检查，直接调用 SAF）
class FilePickerSection extends StatelessWidget {
  const FilePickerSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Consumer<ConversionProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 按钮行
            if (isTablet)
              Row(children: _buildButtons(provider))
            else
              Wrap(spacing: 12, runSpacing: 12, children: _buildButtons(provider)),
            const SizedBox(height: 12),
            // 路径/名称显示
            if (provider.displayPath.isNotEmpty)
              Text(
                provider.displayPath,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            const SizedBox(height: 8),
            // 发现文件数量
            Text(
              '发现 ${provider.fileCount} 个 MP4 文件',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildButtons(ConversionProvider provider) {
    return [
      ElevatedButton.icon(
        onPressed: provider.isConverting ? null : () => provider.pickFolder(),
        icon: const Icon(Icons.folder_open, size: 28),
        label: const Text('选择文件夹'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.textColor,
          side: const BorderSide(color: Color(0xFF8A94A0), width: 2),
        ),
      ),
      ElevatedButton.icon(
        onPressed: provider.isConverting ? null : () => provider.pickFiles(),
        icon: const Icon(Icons.video_file, size: 28),
        label: const Text('选择文件'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.textColor,
          side: const BorderSide(color: Color(0xFF8A94A0), width: 2),
        ),
      ),
    ];
  }
}
