import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roluck_mobile/app.dart';

void main() {
  testWidgets('App se inicia correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: RoLuckApp()));
    expect(find.text('Convertir'), findsWidgets);
  });
}
