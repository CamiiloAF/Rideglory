enum AiChatRole { user, model }

class AiChatTurn {
  const AiChatTurn({
    required this.role,
    required this.content,
    this.isDescription = false,
  });

  final AiChatRole role;
  final String content;
  final bool isDescription;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AiChatTurn &&
        other.role == role &&
        other.content == content &&
        other.isDescription == isDescription;
  }

  @override
  int get hashCode => Object.hash(role, content, isDescription);
}
