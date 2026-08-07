import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/conversion_provider.dart';
import 'common/advanced_options_panel.dart';
import 'common/bitrate_dropdown.dart';
import 'common/output_dir_setting.dart';

/// 本地转换 Tab 的设置与高级选项区域
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConversionProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 音质选择 + 包含子文件夹
            _buildBasicSettings(provider),
            const SizedBox(height: 12),
            // 自定义输出目录（两 Tab 共用）
            OutputDirSetting(enabled: !provider.isConverting),
            const SizedBox(height: 12),
            // 高级选项
            AdvancedOptionsPanel(
              skipStart: provider.skipStart,
              skipEnd: provider.skipEnd,
              repeat2: provider.repeat2,
              enabled: !provider.isConverting,
              onSkipStartChanged: (v) => provider.skipStart = v,
              onSkipEndChanged: (v) => provider.skipEnd = v,
              onRepeat2Changed: (v) => provider.repeat2 = v,
              onReset: provider.resetAdvanced,
            ),
          ],
        );
      },
    );
  }

  /// 基本设置：音质 + 包含子文件夹
  Widget _buildBasicSettings(ConversionProvider provider) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 24,
      runSpacing: 12,
      children: [
        // 音质选择
        BitrateDropdown(
          value: provider.bitrate,
          enabled: !provider.isConverting,
          onChanged: (v) => provider.bitrate = v,
        ),
        // 包含子文件夹
        buildSwitchTile(
          label: '包含子文件夹',
          value: provider.recursive,
          onChanged: provider.isConverting
              ? null
              : (v) => provider.setRecursive(v),
        ),
      ],
    );
  }
}
