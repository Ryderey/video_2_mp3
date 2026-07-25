import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/conversion_provider.dart';
import '../widgets/header_bar.dart';
import '../widgets/file_picker_section.dart';
import '../widgets/settings_section.dart';
import '../widgets/convert_controls.dart';
import '../widgets/progress_section.dart';
import '../widgets/log_section.dart';

/// 主页面
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _wasConverting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ConversionProvider>(
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

          return Column(
            children: [
              // 顶部标题栏
              const HeaderBar(),
              // 内容区
              Expanded(
                child: _buildContent(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent() {
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
                  const ConvertControls(),
                  const SizedBox(height: 20),
                  // 进度区
                  const ProgressSection(),
                  const SizedBox(height: 20),
                  // 日志区
                  const LogSection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 转换完成弹窗
  void _showCompletionDialog(
      BuildContext context, ConversionProvider provider) {
    final message = provider.successCount == provider.totalCount
        ? '全部转换成功！\n共 ${provider.successCount} 个文件。'
        : '转换完成！\n成功 ${provider.successCount} 个，失败 ${provider.failCount} 个。';

    final outLocation = '\n\n输出位置: ${provider.getOutputDisplayName()}';

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
