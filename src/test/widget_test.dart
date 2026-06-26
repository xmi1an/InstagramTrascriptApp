import 'package:flutter_test/flutter_test.dart';

import 'package:insta_transcript_app/main.dart';

void main() {
  testWidgets('renders transcript home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const App());

    expect(find.text('Instagram Transcript'), findsOneWidget);
    expect(find.text('Generate'), findsOneWidget);
    expect(find.text('Paste'), findsOneWidget);
  });
}
