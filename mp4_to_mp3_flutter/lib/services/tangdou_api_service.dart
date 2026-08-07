import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// 糖豆 API 返回的视频信息
class TangdouVideoInfo {
  final String vid;
  final String title;
  final String url;
  final String? error;

  TangdouVideoInfo._({
    required this.vid,
    required this.title,
    required this.url,
    this.error,
  });

  factory TangdouVideoInfo.ok(String vid, String title, String url) {
    return TangdouVideoInfo._(vid: vid, title: title, url: url);
  }

  factory TangdouVideoInfo.fail(String vid, String error) {
    return TangdouVideoInfo._(vid: vid, title: '', url: '', error: error);
  }

  bool get success => error == null;
}

/// 糖豆 API 服务：链接解析 + 视频信息获取
///
/// 注意：糖豆 CDN（aqiniushare.tangdou.com）强制校验 Referer 请求头，
/// 缺失时会被 302 到一个约 400KB 的假默认视频，因此 [referer] 必须携带。
class TangdouApiService {
  static const String referer = 'https://www.tangdoucdn.com/';
  static const String _apiBase =
      'http://api-h5.tangdou.com/sample/share/main?vid=';
  static const String _userAgent =
      'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

  /// 从一行输入中解析 vid：
  /// 纯数字 / 链接中的 vid= 参数 / 路径中的 10 位以上数字段（兜底）
  static String? parseVid(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    if (RegExp(r'^\d+$').hasMatch(trimmed)) return trimmed;
    final m = RegExp(r'[?&]vid=(\d+)', caseSensitive: false)
        .firstMatch(trimmed);
    if (m != null) return m.group(1);
    final m2 = RegExp(r'/(\d{10,})').firstMatch(trimmed);
    if (m2 != null) return m2.group(1);
    return null;
  }

  /// 调用糖豆 API 获取视频标题与直链
  static Future<TangdouVideoInfo> fetchVideoInfo(String vid) async {
    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);
      final request = await client.getUrl(Uri.parse('$_apiBase$vid'));
      request.headers.set(
          HttpHeaders.acceptHeader, 'application/json, text/plain, */*');
      request.headers.set(HttpHeaders.acceptLanguageHeader, 'zh,zh-CN;q=0.9');
      request.headers.set(HttpHeaders.refererHeader, referer);
      request.headers.set(HttpHeaders.userAgentHeader, _userAgent);

      final response =
          await request.close().timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        return TangdouVideoInfo.fail(
            vid, 'API请求失败，状态码: ${response.statusCode}');
      }

      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 15));

      Map<String, dynamic> json;
      try {
        json = jsonDecode(body) as Map<String, dynamic>;
      } catch (_) {
        return TangdouVideoInfo.fail(vid, 'API返回数据解析失败');
      }

      final code = json['code'];
      if (code != 0 && code != 200) {
        final msg = json['msg'] ?? json['message'] ?? '未知错误';
        return TangdouVideoInfo.fail(vid, 'API返回错误: $msg');
      }

      final data = json['data'];
      if (data is! Map || data['video_url'] == null ||
          data['video_url'].toString().isEmpty) {
        return TangdouVideoInfo.fail(vid, 'API未返回视频地址（视频可能已删除）');
      }

      final title = (data['title'] ?? '').toString();
      return TangdouVideoInfo.ok(
        vid,
        title.isEmpty ? 'tangdou_$vid' : title,
        data['video_url'].toString(),
      );
    } on TimeoutException {
      return TangdouVideoInfo.fail(vid, '网络请求超时');
    } catch (e) {
      return TangdouVideoInfo.fail(vid, '网络请求异常: $e');
    } finally {
      client?.close(force: true);
    }
  }

  /// 过滤文件名中的非法字符
  static String safeName(String name) {
    return name
        .replaceAll(RegExp(r'[\\/:*?"<>|()!]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
