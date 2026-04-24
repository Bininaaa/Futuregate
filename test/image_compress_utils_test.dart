import 'package:avenirdz/utils/image_compress_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImageCompressUtils.isImage', () {
    test('returns true for jpg', () {
      expect(ImageCompressUtils.isImage('photo.jpg'), isTrue);
    });

    test('returns true for jpeg', () {
      expect(ImageCompressUtils.isImage('photo.JPEG'), isTrue);
    });

    test('returns true for png', () {
      expect(ImageCompressUtils.isImage('image.png'), isTrue);
    });

    test('returns true for webp', () {
      expect(ImageCompressUtils.isImage('avatar.webp'), isTrue);
    });

    test('returns false for pdf', () {
      expect(ImageCompressUtils.isImage('resume.pdf'), isFalse);
    });

    test('returns false for docx', () {
      expect(ImageCompressUtils.isImage('report.docx'), isFalse);
    });

    test('returns false for empty string', () {
      expect(ImageCompressUtils.isImage(''), isFalse);
    });
  });
}
