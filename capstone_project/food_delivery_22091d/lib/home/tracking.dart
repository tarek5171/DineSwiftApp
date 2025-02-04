import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:food_delivery_22091d/home/etaService.dart';

class DriverLiveLocationPage extends StatefulWidget {
  final double userLatitude;
  final double userLongitude;

  const DriverLiveLocationPage({
    required this.userLatitude,
    required this.userLongitude,
    Key? key,
  }) : super(key: key);

  @override
  _DriverLiveLocationPageState createState() =>
      _DriverLiveLocationPageState();
}

class _DriverLiveLocationPageState extends State<DriverLiveLocationPage> {
  late GoogleMapController _mapController;
  LatLng? _driverLocation;
  LatLng? _userLocation;
  String? _eta;
  Polyline? _routePolyline;

  final ETAService _etaService = ETAService();
  late StreamSubscription<Position> _locationStreamSubscription;

  @override
  void initState() {
    super.initState();
    _userLocation = LatLng(widget.userLatitude, widget.userLongitude);
    _startLocationTracking();
  }

  void _startLocationTracking() {
    _locationStreamSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      setState(() {
        _driverLocation = LatLng(position.latitude, position.longitude);
      });


      if (_userLocation != null) {
        _updateETA(_driverLocation!);
      }
    });
  }

  Future<void> _updateETA(LatLng driverLocation) async {
    if (_userLocation != null) {
      try {
        final etaData = await _etaService.getETAAndRoute(
          driverLocation: driverLocation,
          userLocation: _userLocation!,
        );

        if (etaData != null) {
          setState(() {
            _eta = etaData['eta'];
            final polyline = etaData['route'];
            _routePolyline = Polyline(
              polylineId: PolylineId('route'),
              points: _decodePolyline(polyline),
              width: 5,
              color: Colors.blue,
            );
          });
        } else {
          print("No ETA data returned.");
        }
      } catch (e) {
        print("Error fetching ETA: $e");
      }
    } else {
      print("User location not available.");
    }
  }

  List<LatLng> _decodePolyline(String polyline) {
    List<LatLng> points = [];
    int index = 0;
    int len = polyline.length;
    int latitude = 0;
    int longitude = 0;

    while (index < len) {
      int result = 0;
      int shift = 0;
      int byte;

      do {
        byte = polyline.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      int dLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      latitude += dLat;

      result = 0;
      shift = 0;

      do {
        byte = polyline.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      int dLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      longitude += dLng;

      points.add(LatLng(latitude / 1E5, longitude / 1E5));
    }

    return points;
  }

  @override
  void dispose() {
    _locationStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Live Location and ETA'),
      ),
      body: _userLocation == null || _driverLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          if (_eta != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'ETA: $_eta',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _userLocation!,
                zoom: 15,
              ),
              markers: {
                if (_userLocation != null)
                  Marker(
                    markerId: const MarkerId('userMarker'),
                    position: _userLocation!,
                    infoWindow: const InfoWindow(title: 'Address Location'),
                  ),
                if (_driverLocation != null)
                  Marker(
                    markerId: const MarkerId('driverMarker'),
                    position: _driverLocation!,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueAzure),
                    infoWindow: const InfoWindow(title: 'Delivery Driver'),
                  ),
              },
              polylines: {
                if (_routePolyline != null) _routePolyline!,
              },
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
          ),
        ],
      ),
    );
  }
}

