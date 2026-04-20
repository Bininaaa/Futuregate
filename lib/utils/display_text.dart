class DisplayText {
  DisplayText._();

  static String opportunityTitle(String value, {required String fallback}) {
    final text = value.trim().isEmpty ? fallback.trim() : value.trim();
    return capitalizeLeadingLabel(text);
  }

  static String capitalizeDisplayValue(String input) {
    final text = input.trim();
    if (text.isEmpty || _looksLikeAddress(text)) {
      return text;
    }

    return capitalizeLeadingLabel(text);
  }

  /// Capitalizes the first alphabetic character in a label.
  ///
  /// Examples:
  /// - `company` -> `Company`
  /// - `student` -> `Student`
  /// - `4 applications` -> `4 Applications`
  static String capitalizeLeadingLabel(String input) {
    final text = input.trim();
    if (text.isEmpty) {
      return text;
    }

    final chars = text.split('');
    for (var i = 0; i < chars.length; i++) {
      final char = chars[i];
      if (_isCasedLetter(char)) {
        chars[i] = char.toUpperCase();
        break;
      }
    }

    return chars.join();
  }

  /// Capitalizes the first alphabetic character of each word while preserving
  /// the remaining characters in that token.
  static String capitalizeWords(String input) {
    final text = input.trim();
    if (text.isEmpty) {
      return text;
    }

    return text.split(RegExp(r'\s+')).map(_capitalizeWord).join(' ');
  }

  static String _capitalizeWord(String word) {
    if (word.isEmpty) {
      return word;
    }

    final chars = word.split('');
    for (var i = 0; i < chars.length; i++) {
      final char = chars[i];
      if (_isCasedLetter(char)) {
        chars[i] = char.toUpperCase();
        break;
      }
    }

    return chars.join();
  }

  static bool _isCasedLetter(String char) {
    if (char.isEmpty) {
      return false;
    }

    return char.toLowerCase() != char.toUpperCase();
  }

  static bool _looksLikeAddress(String text) {
    final lower = text.toLowerCase();
    return lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('www.') ||
        lower.startsWith('mailto:') ||
        lower.startsWith('tel:') ||
        text.contains('@');
  }
}
