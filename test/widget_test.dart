// Tes asap dasar: aplikasi bisa dipompa dan menampilkan MaterialApp.
// (Bawaan templat Flutter merujuk MyApp yang tidak ada di proyek ini.)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:s3console/main.dart';

void main() {
  testWidgets('Aplikasi tampil', (WidgetTester tester) async {
    await tester.pumpWidget(const S3App());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
