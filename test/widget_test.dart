import 'package:flutter_test/flutter_test.dart';
import 'package:hexcollagepro/main.dart';

void main() {
  testWidgets('HexCollageApp loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HexCollageApp());
    expect(find.text('HEX COLLAGE'), findsOneWidget);
  });
}
