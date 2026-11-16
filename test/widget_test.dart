import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hrms/common/constants/constant.dart';
import 'package:hrms/main.dart';

void main() {
  testWidgets('HRMS smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Good Morning'), findsOneWidget);
    expect(find.text('Please Choose Services'), findsOneWidget);
    expect(find.text('Recent Leave Application'), findsOneWidget);
    expect(find.text('Todays Attendance'), findsOneWidget);
  });
}
