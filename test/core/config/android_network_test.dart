import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release manifest permits Firebase network requests', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(
      RegExp(
        r'<uses-permission\s+android:name="android.permission.INTERNET"\s*/>',
      ).hasMatch(manifest),
      isTrue,
      reason: 'Debug/profile permissions do not apply to release APKs.',
    );
  });
}
