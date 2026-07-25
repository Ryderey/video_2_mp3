import 'package:flutter/material.dart';
import '../app_theme.dart';

/// 顶部标题栏
class HeaderBar extends StatelessWidget {
  const HeaderBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        border: Border(
          bottom: BorderSide(color: AppTheme.primaryDark, width: 4),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // 音符图标
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '♪',
                  style: TextStyle(
                    fontSize: 30,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // 标题文字
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MP4 转 MP3',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeTitle,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '把视频里的声音，提取成 MP3 音乐',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFFCFE8E4),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
