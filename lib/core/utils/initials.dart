abstract class Initials {
  static String buildInitials({
    required String firstName,
    required String lastName,
  }) {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    return '${first.toUpperCase()}${last.toUpperCase()}';
  }

  /// Up to two letters from the first and last word of [fullName].
  static String buildFromFullName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      final word = parts.first;
      if (word.length >= 2) {
        return word.substring(0, 2).toUpperCase();
      }
      return word.isNotEmpty ? word[0].toUpperCase() : '';
    }
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final lastWord = parts.last;
    final last = lastWord.isNotEmpty ? lastWord[0] : '';
    return '${first.toUpperCase()}${last.toUpperCase()}';
  }
}
