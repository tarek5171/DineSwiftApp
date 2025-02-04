import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class ETAService {
  final String _googleMapsApiKey = 'AIzaSyAF5wS2S_ToE1tHlO58YuRy39lj9wvKhTI'; // Replace with your API key

  /// Fetches the ETA and route polyline between the driver and user locations.
  Future<Map<String, dynamic>?> getETAAndRoute({
    required LatLng driverLocation,
    required LatLng userLocation,
  }) async {
    try {
      final origin = '${driverLocation.latitude},${driverLocation.longitude}';
      final destination = '${userLocation.latitude},${userLocation.longitude}';

      // Call Google Directions API to get ETA and route data
      final url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$_googleMapsApiKey';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final routes = data['routes'] as List;
          final route = routes[0];
          final legs = route['legs'] as List;
          final leg = legs[0];

          // Return ETA and polyline points
          return {
            'eta': leg['duration']['text'],
            'route': route['overview_polyline']['points'],
          };
        }
      }
    } catch (e) {
      print('Error fetching ETA and route: $e');
    }

    return null;
  }
}
