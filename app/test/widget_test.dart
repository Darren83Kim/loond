import 'package:flutter_test/flutter_test.dart';
import 'package:loond/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('LoondApp builds and shows region gate when unset', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const LoondApp());
    await tester.pump(); // first frame
    // Asset / prefs async — gate or loading
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('지역 선택'), findsOneWidget);
  });
}
