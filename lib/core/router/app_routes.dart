/// Nombres y paths de ruta centralizados.
abstract final class AppRoutes {
  static const String welcome = 'welcome';
  static const String welcomePath = '/welcome';

  static const String maintenance = 'maintenance';
  static const String maintenancePath = '/maintenance';

  static const String events = 'events';
  static const String eventsPath = '/events';

  static const String garage = 'garage';
  static const String garagePath = '/garage';

  static const String vehicleAdd = 'vehicle-add';
  static const String vehicleAddPath = 'add';

  static const String vehicleEdit = 'vehicle-edit';
  static const String vehicleEditPath = 'edit';

  static const String brandPicker = 'brand-picker';
  static const String brandPickerPath = 'brand';

  static const String documentViewer = 'document-viewer';
  static const String documentViewerPath = 'documents/:kind';

  static const String documentUpload = 'document-upload';
  static const String documentUploadPath = 'documents/:kind/upload';

  static const String profile = 'profile';
  static const String profilePath = '/profile';
}
