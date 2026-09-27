import 'package:flutter_test/flutter_test.dart';
import 'package:db_lens/app/app.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SqliteApp());
    expect(find.text('DB Lens'), findsAtLeastNWidgets(1));
  });
}
