import 'package:flutter_test/flutter_test.dart';
import 'package:majong_taiwan_android/main.dart';

void main() {
  testWidgets('App starts and shows title', (WidgetTester tester) async {
    await tester.pumpWidget(const MahjongApp());
    expect(find.text('台灣十六張麻將'), findsOneWidget);
  });
}
