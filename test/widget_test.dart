import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trip_central/app/trip_central_app.dart';

void main() {
  testWidgets('TripCentral app loads bottom navigation shell', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TripCentralApp());

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is AppBar &&
            widget.title is Text &&
            (widget.title as Text).data == 'Home',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.text('Lists'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Social'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
