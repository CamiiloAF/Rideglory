enum EventType {
  offRoad('Off-Road'),
  onRoad('On-Road'),
  exhibition('Exhibición'),
  charitable('Benéfico');

  final String label;
  const EventType(this.label);
}

enum EventDifficulty {
  one(1, 'Fácil 🌶'),
  two(2, 'Moderado 🌶🌶'),
  three(3, 'Intermedio 🌶🌶🌶'),
  four(4, 'Difícil 🌶🌶🌶🌶'),
  five(5, 'Muy difícil 🌶🌶🌶🌶🌶');

  final int value;
  final String label;
  const EventDifficulty(this.value, this.label);

  static EventDifficulty fromValue(int value) => EventDifficulty.values
      .firstWhere((e) => e.value == value, orElse: () => EventDifficulty.one);
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
  final double? price;
  final String? recommendations;
  final DateTime? createdDate;
  final DateTime? updatedDate;

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
    this.recommendations,
    this.createdDate,
    this.updatedDate,
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
    double? price,
    String? recommendations,
    DateTime? createdDate,
    DateTime? updatedDate,
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
      recommendations: recommendations ?? this.recommendations,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is EventModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
