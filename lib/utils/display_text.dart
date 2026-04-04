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
}
