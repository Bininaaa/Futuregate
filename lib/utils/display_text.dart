class DisplayText {
  DisplayText._();

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
      if (RegExp(r'[A-Za-z]').hasMatch(char)) {
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
      if (RegExp(r'[A-Za-z]').hasMatch(char)) {
        chars[i] = char.toUpperCase();
        break;
      }
    }

    return chars.join();
  }
}
