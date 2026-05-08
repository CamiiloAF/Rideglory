class UploadEventImageRequest {
  const UploadEventImageRequest({
    required this.localImagePath,
    this.eventId,
    this.ownerId,
  });

  final String localImagePath;
  final String? eventId;
  final String? ownerId;
}
