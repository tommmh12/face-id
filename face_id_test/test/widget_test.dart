// This is a basic Flutter widget test for Face Recognition App.

import 'package:flutter_test/flutter_test.dart';

import 'package:face_id_test/main.dart';

void main() {
  testWidgets('App initializes correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FaceRecognitionApp());

    // Verify that the app bar title is present
    expect(find.text('Face Recognition Attendance'), findsOneWidget);

    // Verify that Quick Actions section is present
    expect(find.text('Quick Actions'), findsOneWidget);
  });
}
