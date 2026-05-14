enum SoatStatus {
  noSoat,
  valid,
  expiringSoon,
  expired,
}

class SoatModel {
  const SoatModel({
    required this.id,
    required this.vehicleId,
    this.policyNumber,
    this.startDate,
    required this.expiryDate,
    this.insurer,
    this.documentUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String vehicleId;
  final String? policyNumber;
  final DateTime? startDate;
  final DateTime expiryDate;
  final String? insurer;
  final String? documentUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SoatStatus get status {
    final daysUntil = daysUntilExpiry;
    if (daysUntil < 0) return SoatStatus.expired;
    if (daysUntil <= 30) return SoatStatus.expiringSoon;
    return SoatStatus.valid;
  }

  int get daysUntilExpiry {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
    );
    return expiry.difference(today).inDays;
  }

  SoatModel copyWith({
    String? id,
    String? vehicleId,
    String? policyNumber,
    DateTime? startDate,
    DateTime? expiryDate,
    String? insurer,
    String? documentUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SoatModel(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      policyNumber: policyNumber ?? this.policyNumber,
      startDate: startDate ?? this.startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      insurer: insurer ?? this.insurer,
      documentUrl: documentUrl ?? this.documentUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SoatModel &&
            id == other.id &&
            vehicleId == other.vehicleId &&
            policyNumber == other.policyNumber &&
            startDate == other.startDate &&
            expiryDate == other.expiryDate &&
            insurer == other.insurer &&
            documentUrl == other.documentUrl;
  }

  @override
  int get hashCode => Object.hash(
        id,
        vehicleId,
        policyNumber,
        startDate,
        expiryDate,
        insurer,
        documentUrl,
      );
}
