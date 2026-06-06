import 'package:flutter_test/flutter_test.dart';
import 'package:hirehub/main.dart';

void main() {
  testWidgets('HireHub App initial layout smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HireHubApp());

    // Verify that the title 'HireHub' is rendered in the AppBar
    expect(find.text('HireHub'), findsOneWidget);

    // Verify that the search bar prompt is displayed
    expect(find.text('Search by title or company...'), findsOneWidget);

    // Verify that initial loading state or list is rendered
    expect(find.text('All Jobs'), findsOneWidget);
  });
}
