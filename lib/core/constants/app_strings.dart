/// Global string constants for the Rideglory app
/// This file contains common strings used across the entire application
abstract class AppStrings {
  // App name
  static const String appName = 'Rideglory';

  // Common actions
  static const String accept = 'Aceptar';
  static const String cancel = 'Cancelar';
  static const String confirm = 'Confirmar';
  static const String save = 'Guardar';
  static const String delete = 'Eliminar';
  static const String edit = 'Editar';
  static const String add = 'Agregar';
  static const String apply = 'Aplicar';
  static const String clear = 'Limpiar';
  static const String retry = 'Reintentar';
  static const String back = 'Volver';
  static const String continue_ = 'Continuar';
  static const String exit = 'Salir';
  static const String exitAppTitle = 'Salir de la aplicación';
  static const String exitAppMessage =
      '¿Estás seguro de que deseas salir de Rideglory?';

  // Errors
  static const String errorOccurred = 'Ocurrió un error';
  static String errorMessage(String message) => 'Error: $message';
  static const String tryAgain = 'Intentar nuevamente';
  static const String noInternet = 'Sin conexión a internet';

  // Image upload errors
  static const String imageUploadFailed =
      'No se pudo subir la imagen. Revisa tu conexión e intenta de nuevo.';
  static const String imageUploadCancelled =
      'La subida de la imagen fue cancelada.';
  static const String imageUploadNotFound =
      'No se pudo completar la subida. Intenta de nuevo en unos segundos.';

  // Empty states
  static const String noData = 'No hay datos';
  static const String noResults = 'No se encontraron resultados';
  static const String notAvailable = 'N/A';
  static const String noSearchResults =
      'No se encontraron resultados para tu búsqueda';

  // Loading
  static const String loading = 'Cargando...';
  static const String pleaseWait = 'Por favor espera';

  // Success messages
  static const String success = 'Éxito';
  static const String savedSuccessfully = 'Guardado exitosamente';
  static const String deletedSuccessfully = 'Eliminado exitosamente';
  static const String updatedSuccessfully = 'Actualizado exitosamente';

  // Settings
  static const String settings = 'Configuración';
  static const String comingSoon = 'próximamente';

  // Validation messages
  static const String required = 'es requerido';
  static const String mustBeNumber = 'Debe ser un número';
  static const String invalidValue = 'Valor inválido';
  static const String mustBeGreaterThanZero = 'Debe ser mayor a 0';
  static const String mustBeGreaterThan = 'Debe ser mayor a';
}
