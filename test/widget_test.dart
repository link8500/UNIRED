import 'package:flutter_test/flutter_test.dart';

import 'package:unired/main.dart';

void main() {
  testWidgets('renders the UniRed visual home', (WidgetTester tester) async {
    await tester.pumpWidget(const UniRedApp());
    await tester.pumpAndSettle();

    expect(find.text('Ofertas destacadas'), findsOneWidget);
    expect(find.text('Explorar Market'), findsOneWidget);
  });
}
