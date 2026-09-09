@TestOn('browser')
import 'package:flutter_test/flutter_test.dart';
import 'package:qringer_web_stream_io/main.dart';

void main() {
  testWidgets('an invalid QR route does not start a call', (tester) async {
    await tester.pumpWidget(const QringerVisitorApp());
    await tester.pump();
    expect(find.text('Unable to call'), findsOneWidget);
  });
}
