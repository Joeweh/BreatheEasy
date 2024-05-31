// TODO: Implement API Class from what Joey 
import 'dart:convert';
import 'dart:js';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class PlacePrediction {
  late List<MapEntry<String, String>> autocompletes;

  PlacePrediction({ required this.autocompletes });

  factory PlacePrediction.fromJson(var json) {
    var innerJson = json;
    late List<MapEntry<String, String>> factoryAuto = [];

    for (dynamic d in innerJson)
    {
      MapEntry<String, String> m = MapEntry(d["name"] + " - " + d["address"], d["id"]);
      factoryAuto.add(m);
    }

    return PlacePrediction(autocompletes: factoryAuto);
  }
}


class RoutePrediction {
  
  late List<LatLng> points; 
  RoutePrediction({ required this.points});

  factory RoutePrediction.fromJson(Map<String, dynamic> json){
    var innerJson = json["polylineCoords"]; 
    //print(innerJson);
    late List<LatLng> factoryAuto = [];

    for(var d in innerJson){
      //print(d);
      var latitude = d["lat"];
      var longitude = d["long"];
      var m = LatLng(latitude, longitude);
      factoryAuto.add(m);
    }

    return RoutePrediction(points: factoryAuto);
  }
}



class ApiCall {
  Future<PlacePrediction> placeCall(String query, LatLng location) async 
  {
    Map<String, dynamic> request = 
    {
      'query': query,
      'location': {
        'lat': location.latitude,
        'long': location.longitude
      }
    };

    final uri = Uri.parse("https://breathe-easy-server.onrender.com/api/places");
    final response = await http.post(uri, body: json.encode(request));

    if (response.statusCode == 200)
    {
      return PlacePrediction.fromJson(json.decode(response.body));
    }
    else
    {
      throw Exception('Failed to load post');
    }
  }

  Future<List<RoutePrediction>> routeCall(String origin, String dest) async{
    Map<String, dynamic> request = 
    {
        'origin': origin,
        'dest': dest,
        'avoidOutliers': true,
    };

    final uri = Uri.parse("https://breathe-easy-server.onrender.com/api/routes");
    final response = await http.post(uri, body: json.encode(request));
    List<RoutePrediction> a = [];
    if (response.statusCode == 200){
      var t = json.decode(response.body);
      for(var u in t){    
        a.add(RoutePrediction.fromJson(u));
      }
      return a;
    }else {
      throw Exception('Failed to load post');
    }
  }
}