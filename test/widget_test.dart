import 'package:flutter_test/flutter_test.dart';
import 'package:promptingdbp/main.dart';

void main() {
  testWidgets('App can start', (WidgetTester tester) async {
    await tester.pumpWidget(const MahasiswaSuksesApp());

    expect(find.byType(MahasiswaSuksesApp), findsOneWidget);
  });
}
