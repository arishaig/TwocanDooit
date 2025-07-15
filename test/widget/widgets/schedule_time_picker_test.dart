import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/ui/widgets/schedule_time_picker.dart';

void main() {
  group('ScheduleTimePicker Widget Tests', () {
    late TimeOfDay selectedTime;
    setUp(() {
      selectedTime = const TimeOfDay(hour: 8, minute: 0);
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: ScheduleTimePicker(
            selectedTime: selectedTime,
            onChanged: (time) {
              // Handle time change
            },
          ),
        ),
      );
    }

    testWidgets('displays the selected time correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('8:00 AM'), findsOneWidget);
    });

    testWidgets('displays time icon', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('displays dropdown arrow', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    });

    testWidgets('formats morning time correctly', (WidgetTester tester) async {
      selectedTime = const TimeOfDay(hour: 6, minute: 30);
      await tester.pumpWidget(createTestWidget());

      expect(find.text('6:30 AM'), findsOneWidget);
    });

    testWidgets('formats afternoon time correctly', (WidgetTester tester) async {
      selectedTime = const TimeOfDay(hour: 14, minute: 45);
      await tester.pumpWidget(createTestWidget());

      expect(find.text('2:45 PM'), findsOneWidget);
    });

    testWidgets('formats midnight correctly', (WidgetTester tester) async {
      selectedTime = const TimeOfDay(hour: 0, minute: 0);
      await tester.pumpWidget(createTestWidget());

      expect(find.text('12:00 AM'), findsOneWidget);
    });

    testWidgets('formats noon correctly', (WidgetTester tester) async {
      selectedTime = const TimeOfDay(hour: 12, minute: 0);
      await tester.pumpWidget(createTestWidget());

      expect(find.text('12:00 PM'), findsOneWidget);
    });

    testWidgets('formats with leading zero for minutes', (WidgetTester tester) async {
      selectedTime = const TimeOfDay(hour: 8, minute: 5);
      await tester.pumpWidget(createTestWidget());

      expect(find.text('8:05 AM'), findsOneWidget);
    });

    testWidgets('is tappable', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final timePicker = find.byType(ScheduleTimePicker);
      expect(timePicker, findsOneWidget);

      // Should be able to tap on it
      await tester.tap(timePicker);
      await tester.pump();

      // This would normally open the time picker dialog, but we can't easily test that
      // in unit tests without mocking the showTimePicker function
    });

    testWidgets('has proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final container = find.descendant(
        of: find.byType(ScheduleTimePicker),
        matching: find.byType(Container),
      );

      expect(container, findsOneWidget);

      final containerWidget = tester.widget<Container>(container);
      expect(containerWidget.padding, const EdgeInsets.symmetric(horizontal: 16, vertical: 16));
    });

    testWidgets('displays time in row with icon and text', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final row = find.descendant(
        of: find.byType(ScheduleTimePicker),
        matching: find.byType(Row),
      );

      expect(row, findsOneWidget);

      // Should have icon, text, spacer, and dropdown icon
      expect(find.descendant(of: row, matching: find.byIcon(Icons.access_time)), findsOneWidget);
      expect(find.descendant(of: row, matching: find.text('8:00 AM')), findsOneWidget);
      expect(find.descendant(of: row, matching: find.byType(Spacer)), findsOneWidget);
      expect(find.descendant(of: row, matching: find.byIcon(Icons.arrow_drop_down)), findsOneWidget);
    });

    testWidgets('uses correct border styling', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final container = find.descendant(
        of: find.byType(ScheduleTimePicker),
        matching: find.byType(Container),
      );

      final containerWidget = tester.widget<Container>(container);
      final decoration = containerWidget.decoration as BoxDecoration;

      expect(decoration.border, isNotNull);
      expect(decoration.borderRadius, BorderRadius.circular(12));
    });
  });
}