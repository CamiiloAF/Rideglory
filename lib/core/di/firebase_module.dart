import 'package:dio/dio.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/http/app_dio.dart';

@module
abstract class FirebaseInjectableModule {
  @lazySingleton
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;
  @lazySingleton
  FirebaseStorage get firebaseStorage => FirebaseStorage.instance;
  @lazySingleton
  FirebaseAnalytics get firebaseAnalytics => FirebaseAnalytics.instance;
  @lazySingleton
  FlutterSecureStorage get flutterSecureStorage => const FlutterSecureStorage();
  @lazySingleton
  FirebaseRemoteConfig get firebaseRemoteConfig =>
      FirebaseRemoteConfig.instance;
  @lazySingleton
  Dio dio(FirebaseAuth firebaseAuth, FirebaseRemoteConfig remoteConfig) {
    return AppDio.create(
      firebaseAuth: firebaseAuth,
      remoteConfig: remoteConfig,
    );
  }
  GoogleSignIn get googleSignIn => GoogleSignIn();
}
