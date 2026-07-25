/// 转换任务模型
class ConversionTask {
  /// SAF content:// URI（输入文件）
  final String contentUri;

  /// 显示名称
  final String fileName;

  /// 复制到缓存后的本地路径（FFmpeg 使用）
  String? cachedInputPath;

  /// 输出文件名（不含路径）
  final String outputFileName;

  /// 输出目录 tree URI（为空则与输入同目录）
  final String? outputTreeUri;

  /// 输出文件的本地缓存路径（FFmpeg 写入此处，再转存到 SAF）
  String? cachedOutputPath;

  ConversionStatus status;

  ConversionTask({
    required this.contentUri,
    required this.fileName,
    required this.outputFileName,
    this.outputTreeUri,
    this.status = ConversionStatus.pending,
  });
}

enum ConversionStatus {
  pending,
  converting,
  success,
  failed,
}
