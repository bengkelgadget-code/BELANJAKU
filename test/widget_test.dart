import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:belanjaku/features/transactions/widgets/numpad_widget.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('NumpadWidget interacts and fires callbacks', (WidgetTester tester) async {
    String pressedDigit = '';
    bool deleted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NumpadWidget(
            onDigitPressed: (digit) => pressedDigit = digit,
            onDeletePressed: () => deleted = true,
          ),
        ),
      ),
    );

    expect(find.text('1'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('00'), findsOneWidget);

    await tester.tap(find.text('5'));
    await tester.pump();
    expect(pressedDigit, '5');

    await tester.tap(find.byType(InkWell).last);
    await tester.pump();
    expect(deleted, isTrue);
  });
}
