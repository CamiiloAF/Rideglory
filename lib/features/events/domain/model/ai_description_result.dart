class AiDescriptionResult {
  const AiDescriptionResult({
    required this.markdown,
    required this.remainingGenerations,
    required this.isDescription,
  });

  final String markdown;
  final int remainingGenerations;
  final bool isDescription;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AiDescriptionResult &&
        other.markdown == markdown &&
        other.remainingGenerations == remainingGenerations &&
        other.isDescription == isDescription;
  }

  @override
  int get hashCode => Object.hash(markdown, remainingGenerations, isDescription);
}
