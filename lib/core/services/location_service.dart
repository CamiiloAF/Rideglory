import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

class LocationData {
  final String country;
  final List<Department> departments;

  LocationData({required this.country, required this.departments});

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      country: json['country'],
      departments: (json['departments'] as List)
          .map((dept) => Department.fromJson(dept))
          .toList(),
    );
  }
}

class Department {
  final String name;
  final List<String> municipalities;

  Department({required this.name, required this.municipalities});

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      name: json['name'],
      municipalities: List<String>.from(json['municipalities']),
    );
  }
}

@singleton
class LocationService {
  LocationData? _cachedData;

  Future<LocationData> loadColombiaData() async {
    if (_cachedData != null) return _cachedData!;

    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/colombia_locations.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      _cachedData = LocationData.fromJson(jsonData['colombia']);
      return _cachedData!;
    } catch (e) {
      throw Exception('Error loading Colombia location data: $e');
    }
  }

  List<String> getDepartmentNames(LocationData data) {
    return data.departments.map((dept) => dept.name).toList()..sort();
  }

  List<String> getMunicipalitiesForDepartment(
    LocationData data,
    String departmentName,
  ) {
    final department = data.departments.firstWhere(
      (dept) => dept.name == departmentName,
      orElse: () => Department(name: '', municipalities: []),
    );
    return department.municipalities..sort();
  }
}
