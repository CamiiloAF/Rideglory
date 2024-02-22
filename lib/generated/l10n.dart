// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class AppStrings {
  AppStrings();

  static AppStrings? _current;

  static AppStrings get current {
    assert(_current != null,
        'No instance of AppStrings was loaded. Try to initialize the AppStrings delegate before accessing AppStrings.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<AppStrings> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = AppStrings();
      AppStrings._current = instance;

      return instance;
    });
  }

  static AppStrings of(BuildContext context) {
    final instance = AppStrings.maybeOf(context);
    assert(instance != null,
        'No instance of AppStrings present in the widget tree. Did you add AppStrings.delegate in localizationsDelegates?');
    return instance!;
  }

  static AppStrings? maybeOf(BuildContext context) {
    return Localizations.of<AppStrings>(context, AppStrings);
  }

  /// `Bienvenido a Rideglory`
  String get loginWelcome {
    return Intl.message(
      'Bienvenido a Rideglory',
      name: 'loginWelcome',
      desc: '',
      args: [],
    );
  }

  /// `Iniciar sesión con google`
  String get signInWithGoogle {
    return Intl.message(
      'Iniciar sesión con google',
      name: 'signInWithGoogle',
      desc: '',
      args: [],
    );
  }

  /// `Información personal`
  String get personalInfo {
    return Intl.message(
      'Información personal',
      name: 'personalInfo',
      desc: '',
      args: [],
    );
  }

  /// `Masculino`
  String get male {
    return Intl.message(
      'Masculino',
      name: 'male',
      desc: '',
      args: [],
    );
  }

  /// `Femenino`
  String get female {
    return Intl.message(
      'Femenino',
      name: 'female',
      desc: '',
      args: [],
    );
  }

  /// `Prefiero no decirlo`
  String get preferDoNotSay {
    return Intl.message(
      'Prefiero no decirlo',
      name: 'preferDoNotSay',
      desc: '',
      args: [],
    );
  }

  /// `Nombre completo`
  String get fullName {
    return Intl.message(
      'Nombre completo',
      name: 'fullName',
      desc: '',
      args: [],
    );
  }

  /// `Correo electrónico`
  String get email {
    return Intl.message(
      'Correo electrónico',
      name: 'email',
      desc: '',
      args: [],
    );
  }

  /// `Fecha de nacimiento`
  String get dob {
    return Intl.message(
      'Fecha de nacimiento',
      name: 'dob',
      desc: '',
      args: [],
    );
  }

  /// `Género`
  String get gender {
    return Intl.message(
      'Género',
      name: 'gender',
      desc: '',
      args: [],
    );
  }

  /// `Teléfono`
  String get phoneNumber {
    return Intl.message(
      'Teléfono',
      name: 'phoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `Guardar`
  String get save {
    return Intl.message(
      'Guardar',
      name: 'save',
      desc: '',
      args: [],
    );
  }

  /// `Ocurrió un error al registrarse, intentalo más tarde`
  String get signUpError {
    return Intl.message(
      'Ocurrió un error al registrarse, intentalo más tarde',
      name: 'signUpError',
      desc: '',
      args: [],
    );
  }

  /// `Aventura`
  String get adventure {
    return Intl.message(
      'Aventura',
      name: 'adventure',
      desc: '',
      args: [],
    );
  }

  /// `Viaje corto`
  String get shortTrip {
    return Intl.message(
      'Viaje corto',
      name: 'shortTrip',
      desc: '',
      args: [],
    );
  }

  /// `Viaje largo`
  String get longTrip {
    return Intl.message(
      'Viaje largo',
      name: 'longTrip',
      desc: '',
      args: [],
    );
  }

  /// `Pareja`
  String get couple {
    return Intl.message(
      'Pareja',
      name: 'couple',
      desc: '',
      args: [],
    );
  }

  /// `Extremo`
  String get extreme {
    return Intl.message(
      'Extremo',
      name: 'extreme',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<AppStrings> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'es'),
      Locale.fromSubtags(languageCode: 'en'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<AppStrings> load(Locale locale) => AppStrings.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
