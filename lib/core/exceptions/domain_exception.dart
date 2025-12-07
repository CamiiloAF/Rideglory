import 'package:flutter/material.dart';

@immutable
class DomainException implements Exception {
  const DomainException({required this.message});

  final String message;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DomainException && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'DomainException(message: $message)';
}
