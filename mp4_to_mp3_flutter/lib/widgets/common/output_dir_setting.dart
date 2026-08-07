import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../providers/output_dir_provider.dart';
import 'advanced_options_panel.dart';

/// 『输出到指定目录』设置（开关 + 选择目录），两个 Tab 共用
///
/// 绑定共享的 [OutputDirProvider]（持久化到 SharedPreferences）。
class OutputDirSetting extends StatelessWidget {
  final bool enabled;

  const OutputDirSetting({super.key, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    final outputDir = context.watch<OutputDirProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            buildSwitchTile(
              label: '输出到指定目录',
              value: outputDir.useCustomOutDir,
              onChanged: !enabled
                  ? null
                  : (v) {
                      outputDir.useCustomOutDir = v;
                      if (v && outputDir.outputTreeUri.isEmpty) {
                        outputDir.pickOutputDir();
                      }
                    },
            ),
            if (outputDir.useCustomOutDir) ...[
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: enabled ? () => outputDir.pickOutputDir() : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.textColor,
                  side: const BorderSide(color: Color(0xFF8A94A0), width: 2),
                  minimumSize: const Size(120, 52),
                ),
                child: const Text('选择目录'),
              ),
            ],
          ],
        ),
        if (outputDir.useCustomOutDir && outputDir.outputTreeUri.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 8),
            child: Text(
              outputDir.outputDisplayName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}
