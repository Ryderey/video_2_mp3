import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'providers/conversion_provider.dart';
import 'providers/output_dir_provider.dart';
import 'providers/tangdou_provider.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 允许横竖屏
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const Mp4ToMp3App());
}

class Mp4ToMp3App extends StatelessWidget {
  const Mp4ToMp3App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConversionProvider()),
        ChangeNotifierProvider(create: (_) => OutputDirProvider()..init()),
        ChangeNotifierProvider(create: (_) => TangdouProvider()..init()),
      ],
      child: MaterialApp(
        title: 'MP4转MP3',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        // 老年手机已开启系统放大模式，App 自身已用大字体适配，
        // 锁定文字缩放为 1.0，避免系统缩放与 App 大字体叠加导致二次放大
        builder: (context, child) => MediaQuery.withNoTextScaling(child: child!),
        home: const HomeScreen(),
      ),
    );
  }
}
