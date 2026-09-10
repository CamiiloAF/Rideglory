/// Estado de una rodada. Coincide con el enum `public.event_state` de
/// Supabase. Las transiciones válidas las impone el trigger de la base
/// (`enforce_event_state_transition`); el cliente nunca las asume.
enum EventState { draft, published, started, finished, cancelled }
