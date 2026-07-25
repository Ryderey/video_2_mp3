import 'package:flutter/services.dart';

/// SAF 文件信息服务
class SafFileInfo {
  final String uri;
  final String name;

  SafFileInfo({required this.uri, required this.name});

  factory SafFileInfo.fromMap(Map<dynamic, dynamic> map) {
    return SafFileInfo(
      uri: map['uri'] as String,
      name: map['name'] as String,
    );
  }
}

/// SAF 文件夹选择结果
class SafFolderResult {
  final String treeUri;
  final String displayName;

  SafFolderResult({required this.treeUri, required this.displayName});
}

/// 文件服务：通过 MethodChannel 调用 Android SAF 原生操作
class FileService {
  static const _channel = MethodChannel('com.mp4tool.mp4_to_mp3_flutter/saf');

  /// 选择输入文件夹（ACTION_OPEN_DOCUMENT_TREE）
  /// 返回 null 表示用户取消
  static Future<SafFolderResult?> pickFolder() async {
    final result = await _channel.invokeMethod('pickFolder');
    if (result == null) return null;
    final map = result as Map<dynamic, dynamic>;
    return SafFolderResult(
      treeUri: map['uri'] as String,
      displayName: map['name'] as String,
    );
  }

  /// 选择单个/多个 MP4 文件（ACTION_OPEN_DOCUMENT）
  /// 返回 null 表示用户取消
  static Future<List<SafFileInfo>?> pickFiles() async {
    final result = await _channel.invokeMethod('pickFile');
    if (result == null) return null;
    final list = result as List<dynamic>;
    return list
        .map((e) => SafFileInfo.fromMap(e as Map<dynamic, dynamic>))
        .toList();
  }

  /// 选择输出目录（ACTION_OPEN_DOCUMENT_TREE，读写权限）
  /// 返回 null 表示用户取消
  static Future<SafFolderResult?> pickOutputDir() async {
    final result = await _channel.invokeMethod('pickOutputDir');
    if (result == null) return null;
    final map = result as Map<dynamic, dynamic>;
    return SafFolderResult(
      treeUri: map['uri'] as String,
      displayName: map['name'] as String,
    );
  }

  /// 列出文件夹中的 MP4 文件
  static Future<List<SafFileInfo>> listMp4Files({
    required String treeUri,
    required bool recursive,
  }) async {
    final result = await _channel.invokeMethod<List<dynamic>>('listMp4Files', {
      'treeUri': treeUri,
      'recursive': recursive,
    });
    if (result == null) return [];
    return result
        .map((e) => SafFileInfo.fromMap(e as Map<dynamic, dynamic>))
        .toList();
  }

  /// 将 content:// URI 复制到应用缓存目录，返回缓存文件的绝对路径
  static Future<String> copyToCache({
    required String contentUri,
    required String fileName,
  }) async {
    final path = await _channel.invokeMethod<String>('copyToCache', {
      'contentUri': contentUri,
      'fileName': fileName,
    });
    if (path == null) throw Exception('复制文件到缓存失败');
    return path;
  }

  /// 将缓存中的 MP3 文件写入 SAF 输出目录
  static Future<void> writeOutputToTree({
    required String treeUri,
    required String fileName,
    required String cacheFilePath,
  }) async {
    await _channel.invokeMethod('writeOutputToTree', {
      'treeUri': treeUri,
      'fileName': fileName,
      'cacheFilePath': cacheFilePath,
    });
  }

  /// 释放 URI 持久化权限
  static Future<void> releasePermission(String uri) async {
    await _channel.invokeMethod('releasePermission', {'uri': uri});
  }
}
