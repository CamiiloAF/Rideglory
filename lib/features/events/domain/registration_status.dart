/// Estado de una inscripción. Coincide con `public.registration_status`.
enum RegistrationStatus { pending, approved, rejected, cancelled }

/// Tipo de sangre de una inscripción, para el snapshot legal que ve el
/// organizador (enmascarado según `share_medical_info`). Coincide con
/// `public.blood_type`. Se duplica del feature `profile` a propósito: el
/// snapshot de una inscripción es un dato propio de `events`, no del
/// perfil vigente del rider (puede cambiar después sin afectar lo ya
/// aceptado).
enum EventBloodType {
  oPositive,
  oNegative,
  aPositive,
  aNegative,
  bPositive,
  bNegative,
  abPositive,
  abNegative,
}
