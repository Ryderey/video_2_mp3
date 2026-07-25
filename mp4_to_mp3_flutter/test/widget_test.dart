import 'package:flutter_test/flutter_test.dart';
import 'package:mp4_to_mp3_flutter/main.dart';

void main() {
  testWidgets('App should launch', (WidgetTester tester) async {
    await tester.pumpWidget(const Mp4ToMp3App());
    expect(find.text('MP4 转 MP3'), findsOneWidget);
  });
}
