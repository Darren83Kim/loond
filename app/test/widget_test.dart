import 'package:flutter_test/flutter_test.dart';
import 'package:loond/main.dart';

void main() {
  testWidgets('LoondApp builds', (tester) async {
    await tester.pumpWidget(const LoondApp());
    // Asset load async — just ensure no immediate crash
    expect(find.text('로온드'), findsOneWidget);
  });
}