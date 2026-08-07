import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tangdou_task.dart';
import '../services/ffmpeg_service.dart';
import '../services/file_service.dart';
import '../services/tangdou_api_service.dart';
import '../utils/audio_filter.dart';

/// 糖豆链接转 MP3 状态管理（业务层）
/// 职责：解析糖豆链接、调用 API 获取直链、生成 FFmpeg 命令、管理任务状态机。
/// 复用 FfmpegService（执行/进度/超时/取消）与音频滤镜工具。
class TangdouProvider extends ChangeNotifier {
  final FfmpegService _ffmpegService = FfmpegService();

  // ===== 持久化 key =====
  static const _keyBitrate = 'tangdou_bitrate';
  static const _keySkipStart = 'tangdou_skip_start';
  static const _keySkipEnd = 'tangdou_skip_end';
  static const _keyRepeat2 = 'tangdou_repeat2';

  // ===== 设置（糖豆默认：跳过前 5 秒广告、不跳过末尾、不重复）=====
  int _bitrate = 192;
  int _skipStart = 5;
  int _skipEnd = 0;
  bool _repeat2 = false;

  // ===== 输入与转换状态 =====
  String _urlText = '';
  bool _isConverting = false;
  int _completedCount = 0;
  int _successCount = 0;
  int _failCount = 0;
  double _currentFileProgress = 0.0;
  List<TangdouTask> _tasks = [];
  List<String> _logs = [];

  // ===== Getters =====
  int get bitrate => _bitrate;
  int get skipStart => _skipStart;
  int get skipEnd => _skipEnd;
  bool get repeat2 => _repeat2;
  String get urlText => _urlText;
  bool get hasInput => _urlText.trim().isNotEmpty;
  bool get isConverting => _isConverting;
  int get completedCount => _completedCount;
  int get successCount => _successCount;
  int get failCount => _failCount;
  int get totalCount => _tasks.length;
  double get currentFileProgress => _currentFileProgress;
  List<TangdouTask> get tasks => _tasks;
  List<String> get logs => _logs;
  double get progress =>
      _tasks.isEmpty ? 0.0 : _completedCount / _tasks.length;

  /// 从 SharedPreferences 恢复持久化设置
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _bitrate = prefs.getInt(_keyBitrate) ?? 192;
    _skipStart = prefs.getInt(_keySkipStart) ?? 5;
    _skipEnd = prefs.getInt(_keySkipEnd) ?? 0;
    _repeat2 = prefs.getBool(_keyRepeat2) ?? false;
    notifyListeners();
  }

  Future<void> _persistSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBitrate, _bitrate);
    await prefs.setInt(_keySkipStart, _skipStart);
    await prefs.setInt(_keySkipEnd, _skipEnd);
    await prefs.setBool(_keyRepeat2, _repeat2);
  }

  // ===== Setters =====
  set bitrate(int value) {
    _bitrate = value;
    _persistSettings();
    notifyListeners();
  }

  set skipStart(int value) {
    _skipStart = value < 0 ? 0 : value;
    _persistSettings();
    notifyListeners();
  }

  set skipEnd(int value) {
    _skipEnd = value < 0 ? 0 : value;
    _persistSettings();
    notifyListeners();
  }

  set repeat2(bool value) {
    _repeat2 = value;
    _persistSettings();
    notifyListeners();
  }

  /// 更新链接输入框文本（UI 双向绑定）
  void setUrlText(String value) {
    if (_urlText == value) return;
    _urlText = value;
    notifyListeners();
  }

  /// 从剪贴板粘贴链接（追加到输入框）
  Future<void> pasteLinks() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final txt = (data?.text ?? '').trim();
    if (txt.isEmpty) {
      addLog('剪贴板中没有内容，请先在微信里复制视频链接。');
      return;
    }
    var cur = _urlText;
    if (cur.isNotEmpty && !cur.endsWith('\n')) cur += '\n';
    _urlText = cur + txt;
    addLog('已粘贴 ${txt.split(RegExp(r'\r?\n')).length} 行链接。');
    notifyListeners();
  }

  /// 清空链接输入框
  void clearLinks() {
    _urlText = '';
    addLog('已清空链接输入框。');
    notifyListeners();
  }

  /// 清零高级选项
  void resetAdvanced() {
    _skipStart = 0;
    _skipEnd = 0;
    _repeat2 = false;
    _persistSettings();
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

  /// 构建 FFmpeg 命令（ffmpeg 直接网络下载 + 转换）
  ///
  /// 糖豆 CDN 强制校验 Referer，缺失时会被 302 到假视频；
  /// -rw_timeout 防止网络挂起无限等待（与 HTA 版保持一致）。
  String _buildCommand(String url, String localOutput, String audioFilter) {
    final sb = StringBuffer();
    sb.write('-y -referer "${TangdouApiService.referer}"');
    sb.write(' -rw_timeout 30000000');
    sb.write(' -i "$url" -vn');
    if (audioFilter.isNotEmpty) sb.write(' -af "$audioFilter"');
    sb.write(' -acodec libmp3lame -ab ${_bitrate}k "$localOutput"');
    return sb.toString();
  }

  /// 开始转换
  ///
  /// [outputTreeUri] 自定义输出目录 tree URI（来自共享的 OutputDirProvider）；
  /// 为空时保存到系统音乐目录。
  Future<void> startConversion({String? outputTreeUri}) async {
    if (_isConverting) return;

    // 1. 解析输入链接
    final items = <_ParsedLine>[];
    for (final raw in _urlText.split(RegExp(r'\r?\n'))) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final vid = TangdouApiService.parseVid(line);
      if (vid == null) {
        addLog('[跳过] 无法识别的链接: $line');
        continue;
      }
      items.add(_ParsedLine(vid: vid, line: line));
    }
    if (items.isEmpty) {
      addLog('未找到有效的糖豆视频链接，请粘贴包含 vid 参数的链接或直接输入 vid 编号。');
      notifyListeners();
      return;
    }

    // 保存到系统音乐目录时，先确保存储权限（Android 9 及以下需运行时授权），
    // 在下载前检查，避免转换完成后才发现无法保存
    if (outputTreeUri == null || outputTreeUri.isEmpty) {
      final granted = await FileService.ensureStoragePermission();
      if (!granted) {
        addLog('[错误] 未获得存储权限，无法保存到音乐目录。'
            '请在系统弹窗中允许存储权限；若已拒绝，请到系统设置中开启，或开启『输出到指定目录』改用其他目录。');
        notifyListeners();
        return;
      }
    }

    _isConverting = true;
    _completedCount = 0;
    _successCount = 0;
    _failCount = 0;
    _currentFileProgress = 0.0;
    _tasks = [];
    final inputSnapshot = _urlText;
    final keepLines = <String>[]; // 失败行（含 API 解析失败），结束后保留便于重试

    addLog('---- 开始处理，共 ${items.length} 个链接 ----');
    if (_skipStart > 0) addLog('跳过前面 $_skipStart 秒');
    if (_skipEnd > 0) addLog('跳过后面 $_skipEnd 秒');
    if (_repeat2) addLog('剪切后重复拼接成 2 遍');
    notifyListeners();

    // 2. 逐个调用 API 获取视频信息
    final usedNames = <String>{};
    for (var i = 0; i < items.length; i++) {
      addLog('[${i + 1}/${items.length}] 解析 vid: ${items[i].vid}');
      final info = await TangdouApiService.fetchVideoInfo(items[i].vid);
      if (!info.success) {
        addLog('  [失败] ${info.error}');
        keepLines.add(items[i].line);
        continue;
      }

      // 生成安全文件名，批内重名加序号
      var baseName = TangdouApiService.safeName(info.title);
      if (baseName.isEmpty) baseName = 'tangdou_${info.vid}';
      var outName = baseName;
      var n = 1;
      while (usedNames.contains(outName.toLowerCase())) {
        outName = '${baseName}_$n';
        n++;
      }
      usedNames.add(outName.toLowerCase());

      _tasks.add(TangdouTask(
        vid: info.vid,
        line: items[i].line,
        title: info.title,
        url: info.url,
        outputFileName: '$outName.mp3',
      ));
      addLog('  [OK] ${info.title}');
      notifyListeners();
    }

    if (_tasks.isEmpty) {
      addLog('---- 所有链接解析失败，无法继续 ----');
      _isConverting = false;
      _cleanupInputLines(inputSnapshot, keepLines);
      notifyListeners();
      return;
    }

    addLog('成功解析 ${_tasks.length} 个视频，开始下载转换...');
    final audioFilter = buildAudioFilter(
      skipStart: _skipStart,
      skipEnd: _skipEnd,
      repeat2: _repeat2,
    );

    // 3. 逐个下载并转换
    for (final task in _tasks) {
      task.status = TangdouTaskStatus.converting;
      _currentFileProgress = 0.0;
      notifyListeners();

      String? cacheOutput;
      try {
        addLog('正在下载转换: ${task.title}');
        cacheOutput =
            '${Directory.systemTemp.path}${Platform.pathSeparator}tangdou_${task.vid}.mp3';

        // 探测时长用于进度百分比（带 Referer，失败则不显示百分比）
        final duration = await _ffmpegService.getNetworkMediaDuration(
          task.url,
          referer: TangdouApiService.referer,
        );

        final command = _buildCommand(task.url, cacheOutput, audioFilter);
        final result = await _ffmpegService.execute(
          command: command,
          totalDuration: duration,
          onProgress: (pct) {
            _currentFileProgress = pct;
            notifyListeners();
          },
        );

        if (result.cancelled) {
          task.status = TangdouTaskStatus.pending;
          addLog('---- 用户手动停止了转换 ----');
          _cleanupCache(cacheOutput);
          break;
        } else if (result.success) {
          // 写入输出目录：自定义 SAF 目录 或 系统音乐目录
          if (outputTreeUri != null && outputTreeUri.isNotEmpty) {
            await FileService.writeOutputToTree(
              treeUri: outputTreeUri,
              fileName: task.outputFileName,
              cacheFilePath: cacheOutput,
            );
          } else {
            await FileService.saveToMusicDir(
              fileName: task.outputFileName,
              cacheFilePath: cacheOutput,
            );
          }
          task.status = TangdouTaskStatus.success;
          _successCount++;
          addLog('[OK]  ${task.outputFileName}');
        } else {
          task.status = TangdouTaskStatus.failed;
          task.errorMessage = result.errorMessage;
          _failCount++;
          addLog('[FAIL] ${task.title}: ${result.errorMessage ?? "未知错误"}');
        }
      } catch (e) {
        task.status = TangdouTaskStatus.failed;
        task.errorMessage = e.toString();
        _failCount++;
        addLog('[FAIL] ${task.title}: $e');
      } finally {
        _cleanupCache(cacheOutput);
      }

      _completedCount++;
      _currentFileProgress = 0.0;
      notifyListeners();
    }

    // 4. 转换结束
    _isConverting = false;
    if (_successCount + _failCount > 0) {
      addLog('---- 全部结束：成功 $_successCount 个，失败 $_failCount 个 ----');
    }
    _cleanupInputLines(inputSnapshot, keepLines);
    notifyListeners();
  }

  /// 结束后自动清空转换成功的链接，仅保留失败/未完成链接便于重试
  void _cleanupInputLines(String snapshot, List<String> parseFailedLines) {
    if (_urlText != snapshot) {
      addLog('检测到转换期间输入框被修改，已跳过自动清理链接。');
      return;
    }
    final seen = <String>{};
    final keep = <String>[];
    void addLine(String line) {
      if (seen.add(line)) keep.add(line);
    }

    for (final line in parseFailedLines) {
      addLine(line);
    }
    for (final task in _tasks) {
      if (task.status != TangdouTaskStatus.success) addLine(task.line);
    }
    _urlText = keep.join('\n');
    addLog('已自动清空转换成功的链接。');
    if (keep.isNotEmpty) {
      addLog('失败链接已保留在输入框，可直接再次点击「开始转换」重试。');
    }
  }

  /// 清理缓存文件
  void _cleanupCache(String? outputPath) {
    try {
      if (outputPath != null) File(outputPath).deleteSync();
    } catch (_) {}
  }

  /// 停止转换
  void stopConversion() {
    _ffmpegService.cancel();
  }
}

/// 解析后的输入行
class _ParsedLine {
  final String vid;
  final String line;

  _ParsedLine({required this.vid, required this.line});
}
