import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:location/location.dart';
// import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:rideglory/shared/constants/env_keys.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // LatLng? _currentLocation;
  // late CameraPosition _cameraPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async => afterLayout());
  }

  Future<void> afterLayout() async {
    await initializeLocationAndSave();
    // if (_currentLocation != null) {
    //   _cameraPosition = CameraPosition(target: _currentLocation!);
    // }
  }

  Future<void> initializeLocationAndSave() async {
    // Ensure all permissions are collected for Locations
    Location location = Location();
    bool? serviceEnabled;
    PermissionStatus? permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
    }

    // Get the current user location
    LocationData locationData = await location.getLocation();
    // _currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
  }

  @override
  Widget build(BuildContext context) {
    return Container();
    // return MapboxMap(
    //   initialCameraPosition: _cameraPosition,
    //   accessToken: dotenv.get(EnvKeys.mapBoxAccessToken),
    //   myLocationEnabled: true,
    // );
  }
}
