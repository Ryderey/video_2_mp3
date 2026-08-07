import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app_theme.dart';

/// 高级选项面板（跳过前/后 N 秒、重复拼接 2 遍），两个 Tab 共用
///
/// 纯参数化组件，不绑定具体 provider；通过回调通知外部。
class AdvancedOptionsPanel extends StatefulWidget {
  final int skipStart;
  final int skipEnd;
  final bool repeat2;
  final bool enabled;
  final ValueChanged<int> onSkipStartChanged;
  final ValueChanged<int> onSkipEndChanged;
  final ValueChanged<bool> onRepeat2Changed;
  final VoidCallback onReset;

  const AdvancedOptionsPanel({
    super.key,
    required this.skipStart,
    required this.skipEnd,
    required this.repeat2,
    required this.enabled,
    required this.onSkipStartChanged,
    required this.onSkipEndChanged,
    required this.onRepeat2Changed,
    required this.onReset,
  });

  @override
  State<AdvancedOptionsPanel> createState() => _AdvancedOptionsPanelState();
}

class _AdvancedOptionsPanelState extends State<AdvancedOptionsPanel> {
  bool _showAdvanced = true;
  late TextEditingController _skipStartCtrl;
  late TextEditingController _skipEndCtrl;

  @override
  void initState() {
    super.initState();
    _skipStartCtrl = TextEditingController(text: '${widget.skipStart}');
    _skipEndCtrl = TextEditingController(text: '${widget.skipEnd}');
  }

  @override
  void didUpdateWidget(covariant AdvancedOptionsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 外部值变化（如清零）时同步输入框
    if (widget.skipStart.toString() != _skipStartCtrl.text) {
      _skipStartCtrl.text = '${widget.skipStart}';
    }
    if (widget.skipEnd.toString() != _skipEndCtrl.text) {
      _skipEndCtrl.text = '${widget.skipEnd}';
    }
  }

  @override
  void dispose() {
    _skipStartCtrl.dispose();
    _skipEndCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToggle(),
        if (_showAdvanced) ...[
          const SizedBox(height: 12),
          _buildPanel(),
        ],
      ],
    );
  }

  /// 高级选项切换按钮
  Widget _buildToggle() {
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
  Widget _buildPanel() {
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
                onChanged: widget.onSkipStartChanged,
              ),
              _buildNumberInput(
                label: '跳过后面',
                controller: _skipEndCtrl,
                unit: '秒',
                onChanged: widget.onSkipEndChanged,
              ),
              // 清零按钮
              ElevatedButton(
                onPressed: widget.enabled ? widget.onReset : null,
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
            value: widget.repeat2,
            onChanged: widget.enabled ? widget.onRepeat2Changed : null,
          ),
        ],
      ),
    );
  }

  /// 数字输入框
  Widget _buildNumberInput({
    required String label,
    required TextEditingController controller,
    required String unit,
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
            enabled: widget.enabled,
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
  static Widget _buildSwitchTile({
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

/// 开关组件（大触控区域），供其他设置区复用
Widget buildSwitchTile({
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
