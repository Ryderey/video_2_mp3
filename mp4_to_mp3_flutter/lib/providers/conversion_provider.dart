import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversion_task.dart';
import '../services/ffmpeg_service.dart';
import '../services/file_service.dart';

/// 转换状态管理（业务层）
/// 职责：生成 FFmpeg 命令参数、管理任务状态机、统一错误信息封装。
/// 不直接调用 FFmpegKit API，不处理 SAF URI 转换。
class ConversionProvider extends ChangeNotifier {
  final FfmpegService _ffmpegService = FfmpegService();

  // ===== 持久化 key =====
  static const _keyUseCustomOutDir = 'use_custom_out_dir';
  static const _keyOutputTreeUri = 'output_tree_uri';
  static const _keyOutputDisplayName = 'output_display_name';

  /// 从 SharedPreferences 恢复持久化设置
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _useCustomOutDir = prefs.getBool(_keyUseCustomOutDir) ?? false;
    _outputTreeUri = prefs.getString(_keyOutputTreeUri) ?? '';
    _outputDisplayName = prefs.getString(_keyOutputDisplayName) ?? '';
    notifyListeners();
  }

  /// 持久化输出目录设置
  Future<void> _persistOutputDirSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseCustomOutDir, _useCustomOutDir);
    await prefs.setString(_keyOutputTreeUri, _outputTreeUri);
    await prefs.setString(_keyOutputDisplayName, _outputDisplayName);
  }

  // ===== 文件选择状态 =====
  String _inputTreeUri = ''; // 输入文件夹 tree URI
  String _inputDisplayName = ''; // 输入文件夹显示名
  List<SafFileInfo> _mp4Files = []; // 扫描到的 MP4 文件列表

  // ===== 设置 =====
  int _bitrate = 192;
  bool _recursive = true;
  int _skipStart = 5;
  int _skipEnd = 3;
  bool _repeat2 = true;
  bool _useCustomOutDir = false;
  String _outputTreeUri = ''; // 输出目录 tree URI
  String _outputDisplayName = '';

  // ===== 转换状态 =====
  bool _isConverting = false;
  int _completedCount = 0;
  int _successCount = 0;
  int _failCount = 0;
  double _currentFileProgress = 0.0;
  List<ConversionTask> _tasks = [];
  List<String> _logs = [];

  // ===== Getters =====
  String get inputTreeUri => _inputTreeUri;
  String get inputDisplayName => _inputDisplayName;
  List<SafFileInfo> get mp4Files => _mp4Files;
  int get fileCount => _mp4Files.length;
  int get bitrate => _bitrate;
  bool get recursive => _recursive;
  int get skipStart => _skipStart;
  int get skipEnd => _skipEnd;
  bool get repeat2 => _repeat2;
  bool get useCustomOutDir => _useCustomOutDir;
  String get outputTreeUri => _outputTreeUri;
  String get outputDisplayName => _outputDisplayName;
  bool get isConverting => _isConverting;
  int get completedCount => _completedCount;
  int get successCount => _successCount;
  int get failCount => _failCount;
  int get totalCount => _tasks.length;
  double get currentFileProgress => _currentFileProgress;
  List<ConversionTask> get tasks => _tasks;
  List<String> get logs => _logs;
  double get progress =>
      _tasks.isEmpty ? 0.0 : _completedCount / _tasks.length;

  /// 显示路径（用于 UI）
  String get displayPath {
    if (_inputTreeUri.isEmpty) return '';
    return _inputDisplayName;
  }

  // ===== Setters =====
  set bitrate(int value) {
    _bitrate = value;
    notifyListeners();
  }

  set skipStart(int value) {
    _skipStart = value < 0 ? 0 : value;
    notifyListeners();
  }

  set skipEnd(int value) {
    _skipEnd = value < 0 ? 0 : value;
    notifyListeners();
  }

  set repeat2(bool value) {
    _repeat2 = value;
    notifyListeners();
  }

  set useCustomOutDir(bool value) {
    _useCustomOutDir = value;
    if (!value) {
      _outputTreeUri = '';
      _outputDisplayName = '';
    }
    _persistOutputDirSettings();
    notifyListeners();
  }

  /// 切换包含子文件夹并重新扫描
  Future<void> setRecursive(bool value) async {
    _recursive = value;
    notifyListeners();
    if (_inputTreeUri.isNotEmpty) {
      await rescan();
    }
  }

  /// 选择文件夹并扫描（无需权限前置检查）
  Future<void> pickFolder() async {
    final result = await FileService.pickFolder();
    if (result == null) return;

    _inputTreeUri = result.treeUri;
    _inputDisplayName = result.displayName;
    addLog('选择文件夹: ${result.displayName}');

    await _scanFiles();
    notifyListeners();
  }

  /// 选择单个或多个 MP4 文件（无需权限前置检查）
  Future<void> pickFiles() async {
    final files = await FileService.pickFiles();
    if (files == null || files.isEmpty) return;

    _inputTreeUri = ''; // 单文件模式无 tree URI
    _inputDisplayName = files.length == 1
        ? files.first.name
        : '${files.length} 个文件';
    _mp4Files = files;
    addLog('选择文件: $_inputDisplayName');
    addLog('共 ${_mp4Files.length} 个 MP4 文件');
    notifyListeners();
  }

  /// 重新扫描
  Future<void> rescan() async {
    if (_inputTreeUri.isEmpty) return;
    await _scanFiles();
    notifyListeners();
  }

  Future<void> _scanFiles() async {
    _mp4Files = await FileService.listMp4Files(
      treeUri: _inputTreeUri,
      recursive: _recursive,
    );
    addLog('扫描完成: 发现 ${_mp4Files.length} 个 MP4 文件');
  }

  /// 选择输出目录
  Future<void> pickOutputDir() async {
    final result = await FileService.pickOutputDir();
    if (result == null) return;
    _outputTreeUri = result.treeUri;
    _outputDisplayName = result.displayName;
    _useCustomOutDir = true;
    _persistOutputDirSettings();
    addLog('输出目录: ${result.displayName}');
    notifyListeners();
  }

  /// 清零高级选项
  void resetAdvanced() {
    _skipStart = 0;
    _skipEnd = 0;
    _repeat2 = false;
    notifyListeners();
  }

  /// 添加日志
  void addLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    _logs.add('[$timestamp] $message');
    if (_logs.length > 500) {
      _logs = _logs.sublist(_logs.length - 400);
    }
    notifyListeners();
  }

  /// 构建音频滤镜链（业务层：纯参数生成）
  static String buildAudioFilter({
    required int skipStart,
    required int skipEnd,
    required bool repeat2,
  }) {
    final parts = <String>[];
    if (skipStart > 0) {
      parts.add('atrim=start=$skipStart');
      parts.add('asetpts=PTS-STARTPTS');
    }
    if (skipEnd > 0) {
      parts.add('areverse');
      parts.add('atrim=start=$skipEnd');
      parts.add('asetpts=PTS-STARTPTS');
      parts.add('areverse');
    }
    if (repeat2) {
      parts.add('aloop=loop=1:size=2000000000');
      parts.add('asetpts=PTS-STARTPTS');
    }
    return parts.join(',');
  }

  /// 构建 FFmpeg 命令（业务层：生成参数，使用本地缓存路径）
  String _buildCommand(String localInput, String localOutput, String audioFilter) {
    final sb = StringBuffer();
    sb.write('-y -i "$localInput" -vn');
    if (audioFilter.isNotEmpty) sb.write(' -af "$audioFilter"');
    sb.write(' -acodec libmp3lame -ab ${_bitrate}k "$localOutput"');
    return sb.toString();
  }

  /// 从文件名生成输出文件名
  static String _toOutputFileName(String inputName) {
    final dot = inputName.lastIndexOf('.');
    final base = dot > 0 ? inputName.substring(0, dot) : inputName;
    return '$base.mp3';
  }

  /// 开始转换
  Future<void> startConversion() async {
    if (_mp4Files.isEmpty) return;

    _isConverting = true;
    _completedCount = 0;
    _successCount = 0;
    _failCount = 0;
    _currentFileProgress = 0.0;

    // 确定输出 tree URI
    final outTreeUri = _useCustomOutDir ? _outputTreeUri : _inputTreeUri;

    // 构建任务列表
    _tasks = _mp4Files.map((file) {
      return ConversionTask(
        contentUri: file.uri,
        fileName: file.name,
        outputFileName: _toOutputFileName(file.name),
        outputTreeUri: outTreeUri.isNotEmpty ? outTreeUri : null,
      );
    }).toList();

    // 构建音频滤镜
    final audioFilter = buildAudioFilter(
      skipStart: _skipStart,
      skipEnd: _skipEnd,
      repeat2: _repeat2,
    );

    final outDesc = _useCustomOutDir ? _outputDisplayName : '与源文件同目录';
    addLog('---- 开始转换，共 ${_tasks.length} 个文件，音质 ${_bitrate}kbps ----');
    addLog('输出目录: $outDesc');
    if (_skipStart > 0) addLog('跳过前面 $_skipStart 秒');
    if (_skipEnd > 0) addLog('跳过后面 $_skipEnd 秒');
    if (_repeat2) addLog('剪切后重复拼接成 2 遍');
    notifyListeners();

    // 逐文件转换
    for (var i = 0; i < _tasks.length; i++) {
      final task = _tasks[i];
      task.status = ConversionStatus.converting;
      _currentFileProgress = 0.0;
      notifyListeners();

      String? cacheInput;
      String? cacheOutput;

      try {
        // 1. 复制输入文件到缓存
        addLog('正在缓存: ${task.fileName}');
        cacheInput = await FileService.copyToCache(
          contentUri: task.contentUri,
          fileName: task.fileName,
        );
        task.cachedInputPath = cacheInput;

        // 2. 准备输出缓存路径
        cacheOutput = '$cacheInput.output.mp3';
        task.cachedOutputPath = cacheOutput;

        // 3. 获取媒体时长
        final duration = await _ffmpegService.getMediaDuration(cacheInput);

        // 4. 构建命令并执行
        final command = _buildCommand(cacheInput, cacheOutput, audioFilter);
        final result = await _ffmpegService.execute(
          command: command,
          totalDuration: duration,
          onProgress: (pct) {
            _currentFileProgress = pct;
            notifyListeners();
          },
        );

        // 5. 处理结果
        if (result.cancelled) {
          task.status = ConversionStatus.pending;
          addLog('---- 用户手动停止了转换 ----');
          _cleanupCache(cacheInput, cacheOutput);
          break;
        } else if (result.success) {
          // 6. 将输出写入 SAF 目录
          if (task.outputTreeUri != null && task.outputTreeUri!.isNotEmpty) {
            await FileService.writeOutputToTree(
              treeUri: task.outputTreeUri!,
              fileName: task.outputFileName,
              cacheFilePath: cacheOutput,
            );
          }
          task.status = ConversionStatus.success;
          _successCount++;
          addLog('[OK]  ${task.fileName}');
        } else {
          task.status = ConversionStatus.failed;
          _failCount++;
          addLog('[FAIL] ${task.fileName}: ${result.errorMessage ?? "未知错误"}');
        }
      } catch (e) {
        task.status = ConversionStatus.failed;
        _failCount++;
        addLog('[FAIL] ${task.fileName}: $e');
      } finally {
        // 7. 清理缓存
        _cleanupCache(cacheInput, cacheOutput);
      }

      _completedCount++;
      _currentFileProgress = 0.0;
      notifyListeners();
    }

    // 转换结束
    _isConverting = false;
    if (_successCount + _failCount > 0) {
      addLog('---- 全部结束：成功 $_successCount 个，失败 $_failCount 个 ----');
    }
    notifyListeners();
  }

  /// 清理缓存文件
  void _cleanupCache(String? inputPath, String? outputPath) {
    try {
      if (inputPath != null) File(inputPath).deleteSync();
    } catch (_) {}
    try {
      if (outputPath != null) File(outputPath).deleteSync();
    } catch (_) {}
  }

  /// 停止转换
  void stopConversion() {
    _ffmpegService.cancel();
  }

  /// 获取输出目录显示名（用于完成后提示）
  String getOutputDisplayName() {
    if (_useCustomOutDir && _outputDisplayName.isNotEmpty) {
      return _outputDisplayName;
    }
    return _inputDisplayName;
  }
}
