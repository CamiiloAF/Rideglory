abstract class Initials {
  static String buildInitials({required String firstName, required String lastName}) {
   final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    return '${first.toUpperCase()}${last.toUpperCase()}';
  }
}

