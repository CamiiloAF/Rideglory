/// Valida el formato colombiano de placa de moto: tres letras, dos dígitos
/// y una letra final (ej. `ABC12D`). Sin I/O, sin Flutter: puro Dart para
/// que sea trivial de testear.
abstract final class VehiclePlateValidator {
  static final RegExp _pattern = RegExp(r'^[A-Z]{3}[0-9]{2}[A-Z]$');

  /// Normaliza a mayúsculas y sin espacios para comparar y persistir.
  static String normalize(String rawPlate) {
    return rawPlate.toUpperCase().replaceAll(RegExp(r'\s+'), '');
  }

  static bool isValid(String rawPlate) => _pattern.hasMatch(normalize(rawPlate));
}
