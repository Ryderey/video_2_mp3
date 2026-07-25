import 'dart:async';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

/// 进度回调：percent 范围 0.0 ~ 1.0
typedef ProgressCallback = void Function(double percent);

/// 转换结果
class ConversionResult {
  final bool success;
  final bool cancelled;
  final String? errorMessage;

  ConversionResult({
    required this.success,
    this.cancelled = false,
    this.errorMessage,
  });
}

/// FFmpeg 平台层服务
/// 职责：封装 ffmpeg_kit_flutter_new API，处理 SAF URI、执行、进度、取消、超时。
/// 不关心业务逻辑。
class FfmpegService {
  int? _currentSessionId;

  /// 将 SAF content:// URI 转为 FFmpeg 可读路径。
  /// 若输入已是文件路径则原样返回。
  Future<String> resolveInputPath(String uriOrPath) async {
    if (uriOrPath.startsWith('content://')) {
      final safPath = await FFmpegKitConfig.getSafParameterForRead(uriOrPath);
      return safPath ?? uriOrPath;
    }
    return uriOrPath;
  }

  /// 将输出路径转为 SAF 可写路径（仅当目标是 content:// 时）。
  /// 若输入已是文件路径则原样返回。
  Future<String> resolveOutputPath(String uriOrPath) async {
    if (uriOrPath.startsWith('content://')) {
      final safPath = await FFmpegKitConfig.getSafParameterForWrite(uriOrPath);
      return safPath ?? uriOrPath;
    }
    return uriOrPath;
  }

  /// 获取媒体时长（秒），用于计算进度百分比。
  /// 返回 null 表示无法获取。
  Future<double?> getMediaDuration(String path) async {
    try {
      final resolvedPath = await resolveInputPath(path);
      final session = await FFprobeKit.getMediaInformation(resolvedPath);
      final information = session.getMediaInformation();
      if (information == null) return null;

      final durationStr = information.getDuration();
      if (durationStr == null || durationStr.isEmpty) return null;

      final duration = double.tryParse(durationStr);
      return duration;
    } catch (_) {
      return null;
    }
  }

  /// 执行 FFmpeg 命令（异步，带进度回调和超时）。
  ///
  /// [command] 完整的 ffmpeg 参数字符串（不含 "ffmpeg" 前缀）
  /// [onProgress] 进度回调 0.0~1.0（需要 [totalDuration] 才能计算）
  /// [totalDuration] 输入媒体总时长（秒），用于计算进度百分比
  /// [timeout] 单文件超时时间
  Future<ConversionResult> execute({
    required String command,
    ProgressCallback? onProgress,
    double? totalDuration,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final completer = Completer<ConversionResult>();

    // 超时定时器
    Timer? timeoutTimer;

    late FFmpegSession session;

    session = await FFmpegKit.executeAsync(
      command,
      // completeCallback
      (completedSession) async {
        timeoutTimer?.cancel();
        if (completer.isCompleted) return;

        final returnCode = await completedSession.getReturnCode();
        _currentSessionId = null;

        if (ReturnCode.isSuccess(returnCode)) {
          completer.complete(ConversionResult(success: true));
        } else if (ReturnCode.isCancel(returnCode)) {
          completer.complete(ConversionResult(
            success: false,
            cancelled: true,
            errorMessage: '用户取消',
          ));
        } else {
          // 获取失败日志
          String? errorMsg;
          try {
            final logs = await completedSession.getLogs();
            if (logs.isNotEmpty) {
              // 取最后几条日志作为错误信息
              final lastLogs = logs.length > 3
                  ? logs.sublist(logs.length - 3)
                  : logs;
              errorMsg = lastLogs.map((l) => l.getMessage()).join('\n');
            }
          } catch (_) {}
          completer.complete(ConversionResult(
            success: false,
            errorMessage: errorMsg ?? '转换失败 (code: $returnCode)',
          ));
        }
      },
      // logCallback
      null,
      // statisticsCallback
      (statistics) {
        if (onProgress != null && totalDuration != null && totalDuration > 0) {
          final timeInMs = statistics.getTime();
          final percent = (timeInMs / 1000.0) / totalDuration;
          onProgress(percent.clamp(0.0, 1.0));
        }
      },
    );

    _currentSessionId = session.getSessionId();

    // 设置超时
    timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        FFmpegKit.cancel(_currentSessionId);
        completer.complete(ConversionResult(
          success: false,
          errorMessage: '转换超时（超过 ${timeout.inMinutes} 分钟）',
        ));
      }
    });

    return completer.future;
  }

  /// 取消当前会话
  void cancel() {
    if (_currentSessionId != null) {
      FFmpegKit.cancel(_currentSessionId);
    }
  }
}
