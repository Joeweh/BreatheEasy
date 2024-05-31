// TODO: Implement API Class from what Joey
import 'dart:convert';
//import 'dart:js';
import 'package:breathe_easy/utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class PlacePrediction {
  late List<MapEntry<String, LatLng>> autocompletes;

  PlacePrediction({required this.autocompletes});

  factory PlacePrediction.fromJson(var json) {
    var innerJson = json;
    late List<MapEntry<String, LatLng>> factoryAuto = [];

    for (dynamic d in innerJson) {
      MapEntry<String, LatLng> m =
          MapEntry(d["name"] + " - " + d["address"], LatLng(d['location']['lat'], d['location']['long']));
      factoryAuto.add(m);
    }

    return PlacePrediction(autocompletes: factoryAuto);
  }
}

class RoutePrediction {
  late List<LatLng> points;
  late List<NavInstruction> instructions;
  late double airScore;
  late double distanceMiles;
  late double durationMinutes;

  RoutePrediction(
      {required this.points,
      required this.instructions,
      required this.airScore,
      required this.distanceMiles,
      required this.durationMinutes});

  factory RoutePrediction.fromJson(Map<String, dynamic> json) {
    var innerJson = json["polylineCoords"];
    //print(innerJson);
    late List<LatLng> factoryAuto = [];

    for (var d in innerJson) {
      //print(d);
      var latitude = d["lat"];
      var longitude = d["long"];
      var m = LatLng(latitude, longitude);
      factoryAuto.add(m);
    }

    List<NavInstruction> instructions = [];

    for (var i in json['navInstructions']) {
      NavInstruction instruction =
          NavInstruction(maneuver: i['maneuver'], text: i['text']);

      instructions.add(instruction);
    }

    return RoutePrediction(
        airScore: json['airScore'],
        instructions: instructions,
        points: factoryAuto,
        distanceMiles: json['distanceMiles'],
        durationMinutes: json['durationMinutes']);
  }
}

class ApiCall {
  Future<PlacePrediction> placeCall(String query, LatLng location) async {
    Map<String, dynamic> request = {
      'query': query,
      'location': {'lat': location.latitude, 'long': location.longitude}
    };

    final uri =
        Uri.parse("https://breathe-easy-server.onrender.com/api/places");
    final response = await http.post(uri, body: json.encode(request));

    if (response.statusCode == 200) {
      return PlacePrediction.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load post');
    }
  }

  Future<List<RoutePrediction>> routeCall(String origin, String dest) async {
    Map<String, dynamic> request = {'origin': origin, 'dest': dest};

    final uri =
        Uri.parse("https://breathe-easy-server.onrender.com/api/routes");
    final response = await http.post(uri, body: json.encode(request));
    List<RoutePrediction> a = [];
    if (response.statusCode == 200) {
      var t = json.decode(response.body);
      for (var u in t) {
        a.add(RoutePrediction.fromJson(u));
      }
      return a;
    } else {
      throw Exception('Failed to load post');
    }
  }
}