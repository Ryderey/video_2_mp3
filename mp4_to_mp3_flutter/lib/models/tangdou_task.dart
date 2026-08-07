/// 糖豆链接转换任务
enum TangdouTaskStatus { pending, converting, success, failed }

class TangdouTask {
  final String vid;
  final String line; // 原始输入行（用于结束后清理/保留）
  final String title;
  final String url;
  final String outputFileName;
  TangdouTaskStatus status;
  String? errorMessage;

  TangdouTask({
    required this.vid,
    required this.line,
    required this.title,
    required this.url,
    required this.outputFileName,
    this.status = TangdouTaskStatus.pending,
  });
}
