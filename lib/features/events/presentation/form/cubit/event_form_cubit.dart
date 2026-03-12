import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/use_cases/add_event_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/update_event_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/upload_event_image_use_case.dart';

@injectable
class EventFormCubit extends Cubit<ResultState<EventModel>> {
  EventFormCubit(
    this._addEventUseCase,
    this._updateEventUseCase,
    this._uploadEventImageUseCase,
    this._authService,
  ) : super(const ResultState.initial());

  final formKey = GlobalKey<FormBuilderState>();

  final AddEventUseCase _addEventUseCase;
  final UpdateEventUseCase _updateEventUseCase;
  final UploadEventImageUseCase _uploadEventImageUseCase;
  final AuthService _authService;

  EventModel? _editingEvent;
  XFile? _selectedCoverFile;

  bool get isEditing => _editingEvent != null;
  EventModel? get editingEvent => _editingEvent;
  XFile? get selectedCoverFile => _selectedCoverFile;

  void initialize({EventModel? event}) {
    _editingEvent = event;
    _selectedCoverFile = null;
    emit(const ResultState.initial());
  }

  /// Picks an image from the device gallery. Handles permission request and
  /// shows a dialog if access is denied, with option to open app settings.
  Future<void> pickCoverImageFromGallery(BuildContext context) async {
    final permission = await _requestPhotoPermission();
    if (!context.mounted) return;

    if (permission == false) {
      final isPermanentlyDenied = await _isPhotoPermissionPermanentlyDenied();
      if (!context.mounted) return;
      await _showPermissionDeniedDialog(
        context,
        isPermanentlyDenied: isPermanentlyDenied,
      );
      return;
    }

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (!context.mounted) return;
    if (file == null) return;

    _selectedCoverFile = file;
    emit(state);
  }

  Future<bool> _requestPhotoPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted || status.isLimited;
  }

  Future<bool> _isPhotoPermissionPermanentlyDenied() async {
    final status = await Permission.photos.status;
    return status.isPermanentlyDenied;
  }

  Future<void> _showPermissionDeniedDialog(
    BuildContext context, {
    required bool isPermanentlyDenied,
  }) async {
    final message = isPermanentlyDenied
        ? EventStrings.photoPermissionPermanentlyDenied
        : EventStrings.photoPermissionDenied;

    final openSettings = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(EventStrings.uploadImage),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.accept),
          ),
          if (isPermanentlyDenied)
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(EventStrings.openSettings),
            ),
        ],
      ),
    );

    if (openSettings == true) {
      await openAppSettings();
    }
  }

  void clearCoverImage() {
    _selectedCoverFile = null;
    emit(state);
  }

  /// Returns the current cover image URL to display: from selected file path
  /// (when user picked a new image) or from the editing event.
  String? get displayCoverImageUrl {
    if (_selectedCoverFile != null) return _selectedCoverFile!.path;
    return _editingEvent?.imageUrl;
  }

  /// True when the cover is a local file (selected from gallery), so the UI
  /// should use Image.file instead of Image.network.
  bool get hasLocalCoverImage => _selectedCoverFile != null;

  Future<void> saveEvent(EventModel eventToSave) async {
    emit(const ResultState.loading());

    final hasNewCover = _selectedCoverFile != null;
    final path = _selectedCoverFile?.path;

    if (isEditing && hasNewCover && path != null && eventToSave.id != null) {
      final uploadResult = await _uploadEventImageUseCase(
        eventId: eventToSave.id!,
        localImagePath: path,
      );
      final updated = uploadResult.fold(
        (error) {
          emit(ResultState.error(error: error));
          return null;
        },
        (imageUrl) => eventToSave.copyWith(imageUrl: imageUrl),
      );
      if (updated == null) return;
      final updateResult = await _updateEventUseCase(updated);
      updateResult.fold(
        (error) => emit(ResultState.error(error: error)),
        (event) => emit(ResultState.data(data: event)),
      );
      return;
    }

    if (!isEditing && hasNewCover && path != null) {
      final eventWithoutImage = eventToSave.copyWith(imageUrl: null);
      final addResult = await _addEventUseCase(eventWithoutImage);
      final created = addResult.fold(
        (error) {
          emit(ResultState.error(error: error));
          return null;
        },
        (e) => e,
      );
      if (created == null || created.id == null) return;
      final uploadResult = await _uploadEventImageUseCase(
        eventId: created.id!,
        localImagePath: path,
      );
      uploadResult.fold(
        (error) => emit(ResultState.error(error: error)),
        (imageUrl) async {
          final withImage = created.copyWith(imageUrl: imageUrl);
          final updateResult = await _updateEventUseCase(withImage);
          updateResult.fold(
            (error) => emit(ResultState.error(error: error)),
            (event) => emit(ResultState.data(data: event)),
          );
        },
      );
      return;
    }

    final result = isEditing
        ? await _updateEventUseCase(eventToSave)
        : await _addEventUseCase(eventToSave);

    result.fold(
      (error) => emit(ResultState.error(error: error)),
      (event) => emit(ResultState.data(data: event)),
    );
  }

  EventModel? buildEventToSave() {
    if (!(formKey.currentState?.saveAndValidate() ?? false)) return null;

    final formData = formKey.currentState!.value;
    final userId = _authService.currentUser?.uid ?? '';

    final dateRange = formData[EventFormFields.dateRange] as DateTimeRange?;

    final isMultiBrand = formData[EventFormFields.isMultiBrand] as bool? ?? true;
    final allowedBrands = isMultiBrand
        ? <String>[]
        : (formData[EventFormFields.allowedBrands] as List<String>? ?? <String>[]);

    final priceStr = formData[EventFormFields.price] as String?;
    final price = priceStr != null && priceStr.isNotEmpty
        ? int.tryParse(priceStr)
        : null;

    final imageUrl = _selectedCoverFile != null
        ? null
        : _editingEvent?.imageUrl;

    return EventModel(
      id: _editingEvent?.id,
      ownerId: _editingEvent?.ownerId ?? userId,
      name: formData[EventFormFields.name] as String,
      description: formData[EventFormFields.description] as String,
      city: formData[EventFormFields.city] as String,
      startDate: dateRange?.start ?? DateTime.now(),
      endDate: dateRange?.end != dateRange?.start ? dateRange?.end : null,
      difficulty: formData[EventFormFields.difficulty] as EventDifficulty,
      meetingPoint: formData[EventFormFields.meetingPoint] as String,
      destination: formData[EventFormFields.destination] as String,
      meetingTime: formData[EventFormFields.meetingTime] as DateTime,
      eventType: formData[EventFormFields.eventType] as EventType,
      allowedBrands: allowedBrands,
      price: price,
      imageUrl: imageUrl,
      state: _editingEvent?.state ?? EventState.scheduled,
    );
  }
}
