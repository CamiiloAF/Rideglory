import '../../profile/domain/blood_type.dart';
import '../domain/event_registrant.dart';
import '../domain/registration_status.dart';

/// `O+`, `AB-`, etc. Igual para [BloodType] (perfil) y [EventBloodType]
/// (snapshot de una inscripción): son el mismo dato en dos features.
String bloodTypeShortLabel(BloodType bloodType) => switch (bloodType) {
  BloodType.oPositive => 'O+',
  BloodType.oNegative => 'O-',
  BloodType.aPositive => 'A+',
  BloodType.aNegative => 'A-',
  BloodType.bPositive => 'B+',
  BloodType.bNegative => 'B-',
  BloodType.abPositive => 'AB+',
  BloodType.abNegative => 'AB-',
};

String eventBloodTypeShortLabel(EventBloodType bloodType) =>
    switch (bloodType) {
      EventBloodType.oPositive => 'O+',
      EventBloodType.oNegative => 'O-',
      EventBloodType.aPositive => 'A+',
      EventBloodType.aNegative => 'A-',
      EventBloodType.bPositive => 'B+',
      EventBloodType.bNegative => 'B-',
      EventBloodType.abPositive => 'AB+',
      EventBloodType.abNegative => 'AB-',
    };

/// "Yamaha MT-03 · O+", o solo lo que haya disponible.
String registrantSubtitle(EventRegistrant registrant) {
  final parts = <String>[
    if (registrant.vehicleName != null) registrant.vehicleName!,
    if (registrant.bloodType != null)
      eventBloodTypeShortLabel(registrant.bloodType!),
  ];
  return parts.join(' · ');
}
