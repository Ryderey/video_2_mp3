import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/output_dir_provider.dart';
import '../providers/tangdou_provider.dart';
import '../widgets/common/advanced_options_panel.dart';
import '../widgets/common/bitrate_dropdown.dart';
import '../widgets/common/convert_buttons.dart';
import '../widgets/common/output_dir_setting.dart';
import '../widgets/log_section.dart';
import '../widgets/progress_section.dart';

/// 糖豆链接转 MP3 Tab 页
class TangdouConvertTab extends StatefulWidget {
  const TangdouConvertTab({super.key});

  @override
  State<TangdouConvertTab> createState() => _TangdouConvertTabState();
}

class _TangdouConvertTabState extends State<TangdouConvertTab>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _urlCtrl = TextEditingController();
  bool _wasConverting = false;

  // 完成弹窗展示用：转换开始时快照输出目录显示名
  String? _lastOutputDisplayName;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<TangdouProvider>(
      builder: (context, provider, _) {
        // provider 侧修改输入框（粘贴/清理/自动清理成功链接）时同步到控制器
        if (_urlCtrl.text != provider.urlText) {
          final text = provider.urlText;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_urlCtrl.text != text) _urlCtrl.text = text;
          });
        }

        // 检测转换从进行中变为完成
        if (_wasConverting &&
            !provider.isConverting &&
            provider.totalCount > 0) {
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

  Widget _buildContent(TangdouProvider provider) {
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
                  // 链接输入区
                  _buildUrlInputSection(provider),
                  const SizedBox(height: 20),
                  // 设置区
                  _buildSettingsSection(provider),
                  const SizedBox(height: 24),
                  // 转换控制按钮
                  ConvertButtons(
                    startEnabled: provider.hasInput,
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

  /// 链接输入区：多行输入 + 粘贴/清理按钮
  Widget _buildUrlInputSection(TangdouProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            const Text(
              '粘贴糖豆视频链接（每行一个）：',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                fontWeight: FontWeight.bold,
              ),
            ),
            _buildSmallButton(
              label: '粘贴',
              enabled: !provider.isConverting,
              onPressed: provider.pasteLinks,
            ),
            _buildSmallButton(
              label: '清理',
              enabled: !provider.isConverting,
              onPressed: provider.clearLinks,
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          '例如：https://www.tangdouddn.com/h5/play?vid=20000011230835 或直接输入 vid 编号',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7680),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _urlCtrl,
          enabled: !provider.isConverting,
          maxLines: 5,
          minLines: 3,
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'monospace',
            height: 1.5,
          ),
          decoration: const InputDecoration(
            hintText: '在此粘贴糖豆视频分享链接，每行一个...',
            alignLabelWithHint: true,
          ),
          onChanged: provider.setUrlText,
        ),
      ],
    );
  }

  /// 设置区：音质 + 输出目录（共用）+ 高级选项
  Widget _buildSettingsSection(TangdouProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 24,
          runSpacing: 12,
          children: [
            BitrateDropdown(
              value: provider.bitrate,
              enabled: !provider.isConverting,
              onChanged: (v) => provider.bitrate = v,
            ),
            const Text(
              '（糖豆CDN仅有单一画质，始终按原始画质下载）',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7680),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        OutputDirSetting(enabled: !provider.isConverting),
        if (!context.watch<OutputDirProvider>().hasCustomOutput)
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 8),
            child: Text(
              '未选择目录时，MP3 默认保存到手机的音乐目录',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7680),
              ),
            ),
          ),
        const SizedBox(height: 12),
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
  }

  /// 小号按钮（粘贴/清理）
  Widget _buildSmallButton({
    required String label,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textColor,
        side: const BorderSide(color: Color(0xFF8A94A0), width: 2),
        minimumSize: const Size(90, 48),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
      child: Text(label),
    );
  }

  void _startConversion() {
    final outputDir = context.read<OutputDirProvider>();
    _lastOutputDisplayName =
        outputDir.hasCustomOutput ? outputDir.outputDisplayName : null;
    context.read<TangdouProvider>().startConversion(
          outputTreeUri:
              outputDir.hasCustomOutput ? outputDir.outputTreeUri : null,
        );
  }

  /// 转换完成弹窗
  void _showCompletionDialog(
      BuildContext context, TangdouProvider provider) {
    final message = provider.successCount == provider.totalCount
        ? '全部转换成功！\n共 ${provider.successCount} 个文件。'
        : '转换完成！\n成功 ${provider.successCount} 个，失败 ${provider.failCount} 个。';

    final outLocation =
        '\n\n输出位置: ${_lastOutputDisplayName ?? "手机音乐目录"}';

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
