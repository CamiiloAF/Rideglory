import 'package:rideglory/shared/models/address_location.dart';

enum EventType {
  onRoad('On-road', 'ON_ROAD'),
  offRoad('Off-road', 'OFF_ROAD'),
  course('Curso', 'COURSE'),
  trackDay('Track Day', 'TRACK_DAY'),
  leisure('Paseo', 'LEISURE'),
  competition('Competencia', 'COMPETITION');

  final String label;

  /// Valor que espera la API para este tipo (debe coincidir con
  /// [EventTypeConverter]). Evita derivarlo de `name`, que produciría
  /// valores incorrectos y rompería el filtrado en el backend.
  final String apiValue;

  const EventType(this.label, this.apiValue);
}

enum EventDifficulty {
  one(1, 'Fácil', 'FÁCIL'),
  two(2, 'Moderado', 'MODERADO'),
  three(3, 'Intermedio', 'MEDIA'),
  four(4, 'Difícil', 'DIFÍCIL'),
  five(5, 'Muy difícil', 'MUY DIFÍCIL');

  final int value;
  final String label;
  final String shortLabel;
  const EventDifficulty(this.value, this.label, this.shortLabel);

  static EventDifficulty fromValue(int value) => EventDifficulty.values
      .firstWhere((e) => e.value == value, orElse: () => EventDifficulty.one);
}

enum EventState {
  draft('Borrador'),
  scheduled('Programado'),
  inProgress('En curso'),
  cancelled('Cancelado'),
  finished('Finalizado');

  final String label;
  const EventState(this.label);
}

class EventModel {
  final String? id;
  final String ownerId;
  final String? ownerName;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final EventDifficulty difficulty;
  final DateTime meetingTime;
  final EventType eventType;
  final List<String> allowedBrands;
  final int? price;
  final int? maxParticipants;
  final String? imageUrl;
  final DateTime? createdDate;
  final DateTime? updatedDate;
  final EventState state;
  final List<String> waypoints;
  final Map<String, dynamic>? routeGeoJson;
  final DateTime? organizerAcceptedResponsibilityAt;
  final DateTime? sosTriggeredAt;

  const EventModel({
    this.id,
    required this.ownerId,
    this.ownerName,
    required this.name,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.difficulty,
    required this.meetingTime,
    required this.eventType,
    this.allowedBrands = const [],
    this.price,
    this.maxParticipants,
    this.imageUrl,
    this.createdDate,
    this.updatedDate,
    this.state = EventState.scheduled,
    this.waypoints = const [],
    this.routeGeoJson,
    this.organizerAcceptedResponsibilityAt,
    this.sosTriggeredAt,
  });

  bool get isFree => price == null || price == 0;

  /// Derived from the first waypoint in routeGeoJson.
  String get meetingPoint =>
      routePoints.isNotEmpty ? (routePoints.first.label ?? '') : '';

  /// Derived from the last waypoint in routeGeoJson (empty if only one point).
  String get destination =>
      routePoints.length > 1 ? (routePoints.last.label ?? '') : '';

  /// Parses [routeGeoJson] into ordered [AddressLocation] points for map rendering.
  List<AddressLocation> get routePoints {
    final data = routeGeoJson;
    if (data == null) return const [];
    final list = data['points'] as List<dynamic>?;
    if (list == null) return const [];
    return list.map((p) {
      final map = p as Map<String, dynamic>;
      return AddressLocation(
        latitude: (map['lat'] as num).toDouble(),
        longitude: (map['lng'] as num).toDouble(),
        label: map['label'] as String?,
      );
    }).toList();
  }

  bool get isMultiBrand => allowedBrands.isEmpty;

  bool get isMultiDay => endDate != null;

  EventModel copyWith({
    String? id,
    String? ownerId,
    String? ownerName,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    EventDifficulty? difficulty,
    DateTime? meetingTime,
    EventType? eventType,
    List<String>? allowedBrands,
    int? price,
    int? maxParticipants,
    String? imageUrl,
    DateTime? createdDate,
    DateTime? updatedDate,
    EventState? state,
    List<String>? waypoints,
    Map<String, dynamic>? routeGeoJson,
    DateTime? organizerAcceptedResponsibilityAt,
    DateTime? sosTriggeredAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      difficulty: difficulty ?? this.difficulty,
      meetingTime: meetingTime ?? this.meetingTime,
      eventType: eventType ?? this.eventType,
      allowedBrands: allowedBrands ?? this.allowedBrands,
      price: price ?? this.price,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      imageUrl: imageUrl ?? this.imageUrl,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
      state: state ?? this.state,
      waypoints: waypoints ?? this.waypoints,
      routeGeoJson: routeGeoJson ?? this.routeGeoJson,
      organizerAcceptedResponsibilityAt:
          organizerAcceptedResponsibilityAt ??
          this.organizerAcceptedResponsibilityAt,
      sosTriggeredAt: sosTriggeredAt ?? this.sosTriggeredAt,
    );
  }

  /// El evento llegó a un estado terminal (finalizado o cancelado): ya no se
  /// puede gestionar el estado de las inscripciones.
  bool get hasEnded =>
      state == EventState.finished || state == EventState.cancelled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is EventModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
