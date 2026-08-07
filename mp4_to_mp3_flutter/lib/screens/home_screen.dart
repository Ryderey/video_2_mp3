import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../widgets/header_bar.dart';
import 'local_convert_tab.dart';
import 'tangdou_convert_tab.dart';

/// 主页面：顶部标题栏 + Tab 切换（本地视频转MP3 / 糖豆链接转MP3）
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Column(
          children: [
            // 顶部标题栏
            const HeaderBar(),
            // Tab 切换栏
            Container(
              color: Colors.white,
              child: const TabBar(
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 4,
                labelStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                tabs: [
                  Tab(text: '本地视频转MP3'),
                  Tab(text: '糖豆链接转MP3'),
                ],
              ),
            ),
            // 内容区（两个 Tab 均保活，切换不打断转换）
            const Expanded(
              child: TabBarView(
                children: [
                  LocalConvertTab(),
                  TangdouConvertTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
