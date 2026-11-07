import 'package:flutter_test/flutter_test.dart';
import 'package:rodantex_app/main.dart';

void main() {
  testWidgets('La app arranca con el tema Rodantex', (tester) async {
    await tester.pumpWidget(const RodantexApp());

    expect(find.text('Rodantex'), findsOneWidget);
    expect(find.text('Paleta Fusion'), findsOneWidget);
  });
}
