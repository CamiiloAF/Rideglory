/// Dificultad de una rodada. Los tres niveles que ofrece el creador (EV3)
/// mapean a los enteros 1/3/5 de `events.difficulty` (smallint 1..5): los
/// valores intermedios (2/4) no se ofrecen en la UI pero se leen igual si
/// llegan a existir en la base.
enum EventDifficulty { easy, medium, hard }

/// Traduce el `smallint` de la base a [EventDifficulty] agrupando 1-2 en
/// fácil, 3 en media y 4-5 en difícil.
EventDifficulty eventDifficultyFromScore(int score) {
  if (score <= 2) return EventDifficulty.easy;
  if (score == 3) return EventDifficulty.medium;
  return EventDifficulty.hard;
}

/// El valor que se envía a la base al crear/editar una rodada.
int eventDifficultyToScore(EventDifficulty difficulty) => switch (difficulty) {
  EventDifficulty.easy => 1,
  EventDifficulty.medium => 3,
  EventDifficulty.hard => 5,
};
