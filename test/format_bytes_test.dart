import 'package:flutter_test/flutter_test.dart';

import 'package:aura_app/presentation/utils/format_bytes.dart';

void main() {
  group('formatBytes', () {
    test('returns 0 B for zero', () {
      expect(formatBytes(0), '0 B');
    });

    test('returns 0 B for negative values', () {
      expect(formatBytes(-1), '0 B');
      expect(formatBytes(-1024), '0 B');
    });

    test('formats bytes', () {
      expect(formatBytes(1), '1 B');
      expect(formatBytes(512), '512 B');
      expect(formatBytes(1023), '1023 B');
    });

    test('formats kilobytes without decimals', () {
      expect(formatBytes(1024), '1 KB');
      expect(formatBytes(1536), '2 KB');
      expect(formatBytes(10240), '10 KB');
    });

    test('formats megabytes without decimals', () {
      expect(formatBytes(1024 * 1024), '1 MB');
      expect(formatBytes(1024 * 1024 * 500), '500 MB');
    });

    test('formats gigabytes with two decimals', () {
      expect(formatBytes(1024 * 1024 * 1024), '1.00 GB');
      expect(formatBytes((1.5 * 1024 * 1024 * 1024).round()), '1.50 GB');
      expect(formatBytes((2.13 * 1024 * 1024 * 1024).round()), '2.13 GB');
    });

    test('formats terabytes with two decimals', () {
      expect(formatBytes(1024 * 1024 * 1024 * 1024), '1.00 TB');
    });

    test('clamps to TB for very large values', () {
      expect(formatBytes(1024 * 1024 * 1024 * 1024 * 1024), '1024.00 TB');
    });
  });
}
