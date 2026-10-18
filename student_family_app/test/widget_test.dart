import 'package:flutter_test/flutter_test.dart';
import 'package:student_family_app/main.dart';

void main() {
  testWidgets('EduManageApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EduManageApp());
  });
}