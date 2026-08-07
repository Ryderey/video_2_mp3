import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/conversion_provider.dart';
import '../providers/output_dir_provider.dart';
import '../widgets/file_picker_section.dart';
import '../widgets/settings_section.dart';
import '../widgets/common/convert_buttons.dart';
import '../widgets/progress_section.dart';
import '../widgets/log_section.dart';

/// 本地视频转 MP3 Tab 页
class LocalConvertTab extends StatefulWidget {
  const LocalConvertTab({super.key});

  @override
  State<LocalConvertTab> createState() => _LocalConvertTabState();
}

class _LocalConvertTabState extends State<LocalConvertTab>
    with AutomaticKeepAliveClientMixin {
  bool _wasConverting = false;

  // 完成弹窗展示用：转换开始时快照输出目录显示名
  String? _lastOutputDisplayName;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<ConversionProvider>(
      builder: (context, provider, _) {
        // 检测转换从进行中变为完成
        if (_wasConverting && !provider.isConverting && provider.totalCount > 0) {
          _wasConverting = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showCompletionDialog(context, provider);
          });
        } else if (provider.isConverting) {
          _wasConverting = true;
        }

        return _buildContent(provider);
      },
    );
  }

  Widget _buildContent(ConversionProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 平板适配：内容区最大宽度 720dp，居中
        final maxWidth = constraints.maxWidth >= 600 ? 720.0 : double.infinity;
        final horizontalPadding = constraints.maxWidth >= 600 ? 32.0 : 20.0;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 20,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 文件选择区
                  const FilePickerSection(),
                  const SizedBox(height: 20),
                  // 设置区
                  const SettingsSection(),
                  const SizedBox(height: 24),
                  // 转换控制按钮
                  ConvertButtons(
                    startEnabled: provider.fileCount > 0,
                    isConverting: provider.isConverting,
                    onStart: _startConversion,
                    onStop: provider.stopConversion,
                  ),
                  const SizedBox(height: 20),
                  // 进度区
                  ProgressSection(
                    progress: provider.progress,
                    isConverting: provider.isConverting,
                    completedCount: provider.completedCount,
                    totalCount: provider.totalCount,
                    successCount: provider.successCount,
                    failCount: provider.failCount,
                  ),
                  const SizedBox(height: 20),
                  // 日志区
                  LogSection(logs: provider.logs),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _startConversion() {
    final outputDir = context.read<OutputDirProvider>();
    _lastOutputDisplayName =
        outputDir.hasCustomOutput ? outputDir.outputDisplayName : null;
    context.read<ConversionProvider>().startConversion(
          customOutputTreeUri:
              outputDir.hasCustomOutput ? outputDir.outputTreeUri : null,
        );
  }

  /// 转换完成弹窗
  void _showCompletionDialog(
      BuildContext context, ConversionProvider provider) {
    final message = provider.successCount == provider.totalCount
        ? '全部转换成功！\n共 ${provider.successCount} 个文件。'
        : '转换完成！\n成功 ${provider.successCount} 个，失败 ${provider.failCount} 个。';

    final outLocation =
        '\n\n输出位置: ${provider.getOutputDisplayName(customOutputDisplayName: _lastOutputDisplayName)}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          '转换完成',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        content: Text(
          '$message$outLocation',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(100, 56),
            ),
            child: const Text(
              '好的',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
