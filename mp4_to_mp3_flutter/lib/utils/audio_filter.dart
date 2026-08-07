/// 构建音频滤镜链（跳过前 N 秒 / 跳过末尾 N 秒 / 重复拼接 2 遍）
///
/// 本地转换与糖豆链接转换共用的纯参数生成函数。
String buildAudioFilter({
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
