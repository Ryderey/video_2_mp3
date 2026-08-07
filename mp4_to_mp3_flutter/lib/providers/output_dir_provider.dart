import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/file_service.dart';

/// 输出目录设置（两个 Tab 共用，持久化到 SharedPreferences）
///
/// 开启『输出到指定目录』时，转换结果写入用户选择的 SAF 目录；
/// 关闭时由各自的业务层决定默认输出位置（本地：与源文件同目录；糖豆：系统音乐目录）。
class OutputDirProvider extends ChangeNotifier {
  static const _keyUseCustomOutDir = 'use_custom_out_dir';
  static const _keyOutputTreeUri = 'output_tree_uri';
  static const _keyOutputDisplayName = 'output_display_name';

  bool _useCustomOutDir = false;
  String _outputTreeUri = '';
  String _outputDisplayName = '';

  bool get useCustomOutDir => _useCustomOutDir;
  String get outputTreeUri => _outputTreeUri;
  String get outputDisplayName => _outputDisplayName;

  /// 是否已选定可用的自定义输出目录
  bool get hasCustomOutput => _useCustomOutDir && _outputTreeUri.isNotEmpty;

  /// 从 SharedPreferences 恢复持久化设置
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _useCustomOutDir = prefs.getBool(_keyUseCustomOutDir) ?? false;
    _outputTreeUri = prefs.getString(_keyOutputTreeUri) ?? '';
    _outputDisplayName = prefs.getString(_keyOutputDisplayName) ?? '';
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseCustomOutDir, _useCustomOutDir);
    await prefs.setString(_keyOutputTreeUri, _outputTreeUri);
    await prefs.setString(_keyOutputDisplayName, _outputDisplayName);
  }

  set useCustomOutDir(bool value) {
    _useCustomOutDir = value;
    if (!value) {
      _outputTreeUri = '';
      _outputDisplayName = '';
    }
    _persist();
    notifyListeners();
  }

  /// 选择输出目录（ACTION_OPEN_DOCUMENT_TREE，读写权限）
  Future<void> pickOutputDir() async {
    final result = await FileService.pickOutputDir();
    if (result == null) return;
    _outputTreeUri = result.treeUri;
    _outputDisplayName = result.displayName;
    _useCustomOutDir = true;
    await _persist();
    notifyListeners();
  }
}
