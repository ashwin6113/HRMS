import 'package:flutter_test/flutter_test.dart';
import 'package:hrms/common/constants/constant.dart';
import 'package:hrms/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('HRMS smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('Good '), findsOneWidget);
    expect(find.text('Presents'), findsOneWidget);
    expect(find.text('Recent Leave Application'), findsOneWidget);
    expect(find.text('Total Attendance'), findsOneWidget);
  });
}
