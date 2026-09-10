import 'dart:async';
import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/sos_outbox.dart';
import '../../domain/sos_outbox_item.dart';
import '../dto/sos_outbox_item_dto.dart';

/// Cola durable de SOS en `SharedPreferences` (JSON). Persistida ANTES de
/// la red (regla de seguridad del rider): sobrevive a que maten la app
/// porque `SharedPreferences` escribe a disco, no a memoria.
///
/// Las operaciones se serializan con `_writeLock` (encadenando `Future`s)
/// para que dos llamadas concurrentes (ej. `enqueue` de un SOS nuevo justo
/// cuando `RetrySosOutboxUseCase` está escribiendo un `markSent`) nunca se
/// pisen con un read-modify-write parcial.
@Injectable(as: SosOutbox)
class SharedPreferencesSosOutbox implements SosOutbox {
  SharedPreferencesSosOutbox(this._prefs);

  final SharedPreferences _prefs;

  static const String _key = 'live_ride_sos_outbox';

  Future<void> _writeLock = Future<void>.value();

  Future<T> _synchronized<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _writeLock = _writeLock.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  List<SosOutboxItem> _readAll() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map(
          (entry) => SosOutboxItemDto.fromJson(entry as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> _writeAll(List<SosOutboxItem> items) async {
    final encoded = jsonEncode(
      items.map((item) => SosOutboxItemDto(item).toJson()).toList(),
    );
    await _prefs.setString(_key, encoded);
  }

  @override
  Future<void> enqueue(SosOutboxItem item) {
    return _synchronized(() async {
      final items = _readAll();
      if (items.any((existing) => existing.clientId == item.clientId)) return;
      await _writeAll([...items, item]);
    });
  }

  @override
  Future<List<SosOutboxItem>> pending() {
    return _synchronized(() async => _readAll());
  }

  @override
  Future<void> markSent(String clientId) {
    return _synchronized(() async {
      final items = _readAll()
        ..removeWhere((item) => item.clientId == clientId);
      await _writeAll(items);
    });
  }

  @override
  Future<void> markAttempt(String clientId) {
    return _synchronized(() async {
      final items = _readAll();
      final index = items.indexWhere((item) => item.clientId == clientId);
      if (index == -1) return;
      items[index] = items[index].copyWith(attempts: items[index].attempts + 1);
      await _writeAll(items);
    });
  }
}
