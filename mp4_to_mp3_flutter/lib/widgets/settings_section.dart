import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/conversion_provider.dart';

/// 设置与高级选项区域
class SettingsSection extends StatefulWidget {
  const SettingsSection({super.key});

  @override
  State<SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<SettingsSection> {
  bool _showAdvanced = true;
  late TextEditingController _skipStartCtrl;
  late TextEditingController _skipEndCtrl;

  @override
  void initState() {
    super.initState();
    _skipStartCtrl = TextEditingController(text: '5');
    _skipEndCtrl = TextEditingController(text: '3');
  }

  @override
  void dispose() {
    _skipStartCtrl.dispose();
    _skipEndCtrl.dispose();
    super.dispose();
  }

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
            // 自定义输出目录
            _buildOutputDirSettings(provider),
            const SizedBox(height: 12),
            // 高级选项切换按钮
            _buildAdvancedToggle(),
            // 高级选项面板
            if (_showAdvanced) ...[
              const SizedBox(height: 12),
              _buildAdvancedPanel(provider),
            ],
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '音质：',
              style: TextStyle(
                fontSize: AppTheme.fontSizeBody,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF8A94A0), width: 2),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: provider.bitrate,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeBody,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                  items: const [
                    DropdownMenuItem(value: 128, child: Text('128 kbps')),
                    DropdownMenuItem(value: 192, child: Text('192 kbps')),
                    DropdownMenuItem(value: 320, child: Text('320 kbps')),
                  ],
                  onChanged: provider.isConverting
                      ? null
                      : (v) {
                          if (v != null) provider.bitrate = v;
                        },
                ),
              ),
            ),
          ],
        ),
        // 包含子文件夹
        _buildSwitchTile(
          label: '包含子文件夹',
          value: provider.recursive,
          onChanged: provider.isConverting
              ? null
              : (v) => provider.setRecursive(v),
        ),
      ],
    );
  }

  /// 自定义输出目录设置
  Widget _buildOutputDirSettings(ConversionProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSwitchTile(
              label: '输出到指定目录',
              value: provider.useCustomOutDir,
              onChanged: provider.isConverting
                  ? null
                  : (v) {
                      provider.useCustomOutDir = v;
                      if (v && provider.outputTreeUri.isEmpty) {
                        provider.pickOutputDir();
                      }
                    },
            ),
            if (provider.useCustomOutDir) ...[
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed:
                    provider.isConverting ? null : () => provider.pickOutputDir(),
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
        if (provider.useCustomOutDir && provider.outputTreeUri.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 8),
            child: Text(
              provider.outputDisplayName,
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

  /// 高级选项切换按钮
  Widget _buildAdvancedToggle() {
    return TextButton(
      onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        backgroundColor: const Color(0xFFF0F4F7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFA5B0BA)),
        ),
      ),
      child: Text(
        _showAdvanced ? '收起高级选项 ▲' : '显示高级选项 ▼',
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Color(0xFF3A4750),
        ),
      ),
    );
  }

  /// 高级选项面板
  Widget _buildAdvancedPanel(ConversionProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC3CDD5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '高级选项（默认无需修改）',
            style: TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          // 跳过前面/后面
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              _buildNumberInput(
                label: '跳过前面',
                controller: _skipStartCtrl,
                unit: '秒',
                enabled: !provider.isConverting,
                onChanged: (v) => provider.skipStart = v,
              ),
              _buildNumberInput(
                label: '跳过后面',
                controller: _skipEndCtrl,
                unit: '秒',
                enabled: !provider.isConverting,
                onChanged: (v) => provider.skipEnd = v,
              ),
              // 清零按钮
              ElevatedButton(
                onPressed: provider.isConverting
                    ? null
                    : () {
                        _skipStartCtrl.text = '0';
                        _skipEndCtrl.text = '0';
                        provider.resetAdvanced();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.textColor,
                  side: const BorderSide(color: Color(0xFF8A94A0), width: 2),
                  minimumSize: const Size(90, 52),
                ),
                child: const Text('清零'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '（填 0 表示不跳过，只支持整数秒）',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7680),
            ),
          ),
          const SizedBox(height: 12),
          // 重复拼接
          _buildSwitchTile(
            label: '剪切后再重复拼接成 2 遍',
            value: provider.repeat2,
            onChanged:
                provider.isConverting ? null : (v) => provider.repeat2 = v,
          ),
          const SizedBox(height: 8),
          // 删除源文件
          _buildSwitchTile(
            label: '转换成功后删除原 MP4 文件',
            value: provider.deleteSource,
            onChanged: provider.isConverting
                ? null
                : (v) => _onDeleteSourceToggle(context, provider, v),
          ),
        ],
      ),
    );
  }

  /// 删除源文件开关（需二次确认）
  Future<void> _onDeleteSourceToggle(
    BuildContext context,
    ConversionProvider provider,
    bool value,
  ) async {
    if (value) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(
            '提示',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            '勾选后，转换成功的 MP4 源文件将被删除（无法恢复）。\n\n确定要勾选吗？',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                '取消',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                '确定删除',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
      provider.deleteSource = confirmed ?? false;
    } else {
      provider.deleteSource = false;
    }
  }

  /// 数字输入框
  Widget _buildNumberInput({
    required String label,
    required TextEditingController controller,
    required String unit,
    required bool enabled,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppTheme.fontSizeSmall,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            ),
            onChanged: (v) {
              final n = int.tryParse(v) ?? 0;
              onChanged(n);
            },
          ),
        ),
        const SizedBox(width: 8),
        Text(
          unit,
          style: const TextStyle(
            fontSize: AppTheme.fontSizeSmall,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 开关组件（大触控区域）
  Widget _buildSwitchTile({
    required String label,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return InkWell(
      onTap: onChanged != null ? () => onChanged(!value) : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: value,
              onChanged: onChanged,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeSmall,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
