-- Enums del dominio Rideglory.

create type public.blood_type as enum (
  'o_positive', 'o_negative',
  'a_positive', 'a_negative',
  'b_positive', 'b_negative',
  'ab_positive', 'ab_negative'
);

create type public.document_kind as enum ('soat', 'rtm');

create type public.event_state as enum ('draft', 'published', 'started', 'finished', 'cancelled');

create type public.registration_status as enum ('pending', 'approved', 'rejected', 'cancelled');

create type public.consent_kind as enum ('risk_acceptance', 'medical_consent', 'terms');

create type public.device_platform as enum ('ios', 'android');
