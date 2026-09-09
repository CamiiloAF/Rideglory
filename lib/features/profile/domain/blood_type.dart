/// Tipo de sangre. Los valores coinciden con el enum `public.blood_type` de
/// Supabase (`json_serializable` los serializa con `@JsonValue`).
enum BloodType {
  oPositive,
  oNegative,
  aPositive,
  aNegative,
  bPositive,
  bNegative,
  abPositive,
  abNegative,
}
