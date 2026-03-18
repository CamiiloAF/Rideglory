enum EventType {
  offRoad('Off-Road'),
  onRoad('On-Road'),
  exhibition('Exhibición'),
  charitable('Benéfico');

  final String label;
  const EventType(this.label);
}

enum EventDifficulty {
  one(1, 'Fácil 🌶', 'FÁCIL'),
  two(2, 'Moderado 🌶🌶', 'MODERADO'),
  three(3, 'Intermedio 🌶🌶🌶', 'MEDIA'),
  four(4, 'Difícil 🌶🌶🌶🌶', 'DIFÍCIL'),
  five(5, 'Muy difícil 🌶🌶🌶🌶🌶', 'MUY DIFÍCIL');

  final int value;
  final String label;
  final String shortLabel;
  const EventDifficulty(this.value, this.label, this.shortLabel);

  static EventDifficulty fromValue(int value) => EventDifficulty.values
      .firstWhere((e) => e.value == value, orElse: () => EventDifficulty.one);
}

enum EventState {
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
  final String name;
  final String description;
  final String city;
  final DateTime startDate;
  final DateTime? endDate;
  final EventDifficulty difficulty;
  final String meetingPoint;
  final String destination;
  final DateTime meetingTime;
  final EventType eventType;
  final List<String> allowedBrands;
  final int? price;
  final String? imageUrl;
  final DateTime? createdDate;
  final DateTime? updatedDate;
  final EventState state;

  const EventModel({
    this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.city,
    required this.startDate,
    this.endDate,
    required this.difficulty,
    required this.meetingPoint,
    required this.destination,
    required this.meetingTime,
    required this.eventType,
    this.allowedBrands = const [],
    this.price,
    this.imageUrl,
    this.createdDate,
    this.updatedDate,
    this.state = EventState.scheduled,
  });

  bool get isFree => price == null || price == 0;

  bool get isMultiBrand => allowedBrands.isEmpty;

  bool get isMultiDay => endDate != null;

  EventModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? description,
    String? city,
    DateTime? startDate,
    DateTime? endDate,
    EventDifficulty? difficulty,
    String? meetingPoint,
    String? destination,
    DateTime? meetingTime,
    EventType? eventType,
    List<String>? allowedBrands,
    int? price,
    String? imageUrl,
    DateTime? createdDate,
    DateTime? updatedDate,
    EventState? state,
  }) {
    return EventModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      city: city ?? this.city,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      difficulty: difficulty ?? this.difficulty,
      meetingPoint: meetingPoint ?? this.meetingPoint,
      destination: destination ?? this.destination,
      meetingTime: meetingTime ?? this.meetingTime,
      eventType: eventType ?? this.eventType,
      allowedBrands: allowedBrands ?? this.allowedBrands,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
      state: state ?? this.state,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is EventModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
