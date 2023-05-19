import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:rideglory/shared/constants/env_keys.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late MapboxMap controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async => afterLayout());
  }

  Future<void> afterLayout() async {
    await initializeLocationAndSave();
  }

  Future<void> initializeLocationAndSave() async {
    // Ensure all permissions are collected for Locations

    geolocator.LocationPermission permission =
        await geolocator.Geolocator.checkPermission();
    bool isLocationServiceEnabled =
        await geolocator.Geolocator.isLocationServiceEnabled();

    if (!isLocationServiceEnabled) {
      await geolocator.Geolocator.openLocationSettings();
      return;
    }

    if (permission == geolocator.LocationPermission.denied) {
      await geolocator.Geolocator.openLocationSettings();
    }

    // Get the current user location
    final currentPosition = await geolocator.Geolocator.getCurrentPosition(
        desiredAccuracy: geolocator.LocationAccuracy.high);
    // _currentLocation =
    //     LatLng(currentPosition.latitude, currentPosition.longitude);
    final cameraOptions = CameraOptions(
      center: Point(
        coordinates: Position(
          currentPosition.longitude,
          currentPosition.latitude,
        ),
      ).toJson(),
      zoom: 14,
    );

    await controller.flyTo(
      cameraOptions,
      MapAnimationOptions(duration: 2000, startDelay: 0),
    );

    final annotation =
        await controller.annotations.createPointAnnotationManager();

    await annotation.create(
      PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(
            currentPosition.longitude,
            currentPosition.latitude,
          ),
        ).toJson(),
        iconSize: 24
      ),
    );

    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    // return Container();
    return SafeArea(
      child: MapWidget(
        resourceOptions: ResourceOptions(
          accessToken: dotenv.get(EnvKeys.mapBoxAccessToken),
        ),
        onMapCreated: (controller) {
          this.controller = controller;
        },
      ),
    );
  }
}
