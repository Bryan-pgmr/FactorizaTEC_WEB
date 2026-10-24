import 'package:flutter_test/flutter_test.dart';
import 'package:factorizacion/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FactorizacionApp(alumnoIdInicial: null));
    expect(find.text('Bienvenido'), findsOneWidget);
  });
}
