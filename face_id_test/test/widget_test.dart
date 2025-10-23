// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:face_id_test/main.dart';

void main() {
  testWidgets('Face Recognition App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FaceRecognitionApp());

    // Verify that our app loads successfully.
    expect(find.text('Face Recognition'), findsOneWidget);
    expect(find.text('Chấm công vào ca'), findsOneWidget);
    expect(find.text('Chấm công ra ca'), findsOneWidget);
  });
}
