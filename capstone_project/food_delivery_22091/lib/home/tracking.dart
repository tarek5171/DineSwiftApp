import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:food_delivery_22091/services/etaService.dart';

class DriverLiveLocationPage extends StatefulWidget {
  final String driverId;
  final String addressId;

  const DriverLiveLocationPage({
    required this.driverId,
    required this.addressId,
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
  late Stream<DocumentSnapshot> _driverStream;
  String? _eta;
  Polyline? _routePolyline;

  final ETAService _etaService = ETAService();

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
    _driverStream = FirebaseFirestore.instance
        .collection('driver_accounts')
        .doc(widget.driverId)
        .snapshots();
  }

  Future<void> _fetchUserLocation() async {
    try {
      final addressSnapshot = await FirebaseFirestore.instance
          .collection('addresses')
          .doc(widget.addressId)
          .get();

      if (addressSnapshot.exists) {
        final addressLocation = addressSnapshot['location'];
        final addressLat = addressLocation['latitude'];
        final addressLng = addressLocation['longitude'];

        setState(() {
          _userLocation = LatLng(addressLat, addressLng);
        });
      }
    } catch (e) {
      print('Error fetching address location: $e');
    }
  }

  Future<void> _updateETA(LatLng driverLocation) async {
    if (_userLocation != null) {
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
      }
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Live Location and ETA'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _driverStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              _userLocation == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching driver data'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Driver not found'));
          }

          final driverData = snapshot.data!.data() as Map<String, dynamic>;
          final location = driverData['location'] as Map<String, dynamic>?;
          if (location == null ||
              !location.containsKey('latitude') ||
              !location.containsKey('longitude')) {
            return const Center(child: Text('Driver location not available'));
          }

          final latitude = location['latitude'] as double;
          final longitude = location['longitude'] as double;
          _driverLocation = LatLng(latitude, longitude);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_driverLocation != null) {
              _updateETA(_driverLocation!);
            }
          });

          return Column(
            children: [
              if (_eta != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'ETA: $_eta',
                    style: TextStyle(fontSize: 18),
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
                        infoWindow: const InfoWindow(
                          title: 'Delivery Driver',
                        ),
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
          );
        },
      ),
    );
  }
}
