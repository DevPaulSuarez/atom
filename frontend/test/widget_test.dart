import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:atom/main.dart';
import 'package:atom/providers/app_state.dart';

void main() {
  testWidgets('App renders project list screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const AtomApp(),
      ),
    );
    await tester.pump();
    expect(find.text('Atom'), findsWidgets);
  });
}
