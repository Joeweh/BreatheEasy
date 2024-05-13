import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;

import 'package:http/http.dart' as http;
void main() async {
  // Load Environment Variables
  await dotenv.load(fileName: '.env');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) 
  {
    return const Scaffold(
      body: DirectionPage() // Change to Direction Page if you want to see the page with the maps on it
      body: SearchBarPageState() // Change to Direction Page if you want to see the page with the maps on it
    );
  }
}

class DirectionPage extends StatefulWidget {
  const DirectionPage({
    super.key,
  });

  @override
  State<DirectionPage> createState() => _DirectionPageState();
}

class _DirectionPageState extends State<DirectionPage> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  Map<PolylineId, Polyline> _polylines = {};
  PolylinePoints polylinePoints = PolylinePoints();
  List<LatLng> polylineCoordinates = [];
  var api_key = (dotenv.env['MAPS_API_KEY']).toString();
  String startQuery = "";
  String endQuery = "";

  final LatLng _center = const LatLng(43.281631, -0.802300);

  void setStartQuery(String s)
  {
    startQuery = s;
  }

  void setEndQuery(String s)
  {
    endQuery = s;
  }

  String startQuery = "";
  String endQuery = "";

  final LatLng _center = const LatLng(43.281631, -0.802300);

  void setStartQuery(String s)
  {
    startQuery = s;
  }

  void setEndQuery(String s)
  {
    endQuery = s;
  }

  @override
  Widget build(BuildContext context) {
    LocationBar startLocationBar = LocationBar(callback: setStartQuery,);
    LocationBar endLocationBar = LocationBar(callback: setEndQuery,);

    return Container(
      margin: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          googleMapWidget(),
          startLocationBar,
          endLocationBar,
        ],
      ),
    );
  }

  List<LatLng> latLen = [LatLng(43.3, -0.8), LatLng(43.281631, -0.802300)];
  List<Marker> marks = [Marker(markerId: MarkerId('Test1'), position: LatLng(43.3, -0.8)), 
  Marker(markerId: MarkerId('Test2'), position: LatLng(43.281631, -0.802300))];
  
  Widget googleMapWidget()
  {
    _addMarker(const LatLng(43.3, -0.8), "Test Marker 1");
    _addMarker(const LatLng(43.281631, -0.802300), "Test Marker 2");
    getDirections(marks, setState);
    return Container(height: 600, margin: const EdgeInsets.all(10), child: GoogleMap(onMapCreated: _onMapCreated, initialCameraPosition: CameraPosition(target: _center, zoom: 11.0,), markers: _markers, polylines: Set<Polyline>.of(_polylines.values)));
  }

  void _onMapCreated(GoogleMapController controller)
  {
    setState(() {
      mapController = controller;
    });
  }

  void _addMarker(LatLng l, String markerId)
  {
    setState(() {
      _markers.add(Marker(markerId: MarkerId(markerId), position: l,)); 
    });
  }
}

  getDirections(List<Marker> markers, newSetState) async {
    List<LatLng> polylineCoordinates = [];
    List<PolylineWayPoint> polylineWayPoints = [];
    for (var i =0; i<markers.length; i++){
      polylineWayPoints.add(PolylineWayPoint(location:
      "${markers[i].position.latitude.toString()},${markers[i].position.longitude.toString()}", stopOver: true));
    }

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(api_key, PointLatLng(markers.first.position.latitude, markers.first.position.longitude), PointLatLng(markers.last.position.latitude, markers.last.position.longitude), travelMode: TravelMode.driving, wayPoints: polylineWayPoints);

    if(result.points.isNotEmpty){
      result.points.forEach((PointLatLng point){
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    
    } else {
      print(result.errorMessage);
    }

    newSetState(() {});

    addPolyLine(polylineCoordinates, newSetState);
  }

  addPolyLine(List<LatLng> polylineCoordinates, newSetState){
    PolylineId id = PolylineId("Poly");
    Polyline polyline = Polyline(polylineId: id, color: Colors.blue, points: polylineCoordinates);
    _polylines[id] = polyline;
    newSetState((){});
  }
  
  
}

class LocationBar extends StatelessWidget {
  final ValueChanged<String> callback;

  const LocationBar({super.key, required this.callback});
  
  @override
  Widget build(BuildContext context) {
    return locationBar();
  }

  Widget locationBar()
  {
    return Container(
      margin: const EdgeInsets.all(10),
      child: TextField(
        obscureText: false,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Origin',
        ),
        onChanged: (value)
        {
          callback(value);
        },
      ),
    );
  }
}


class SearchBarPageState extends StatefulWidget {
  const SearchBarPageState({super.key});

  @override
  State<SearchBarPageState> createState() => _SearchBarPageState();
}

class _SearchBarPageState extends State<SearchBarPageState> {
  String textInBar = "";
  Map<String, String> httpAutocompletes = {};

  void setTextInBar(String s)
  {
    setState(() {
      textInBar = s;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          LocationBar(callback: setTextInBar,),
        ],
      ),
    );
  }

  Container placesAutoComplete() // Does not work yet
  {
    return Container(
      margin: const EdgeInsets.all(10),
      child: ListView(
        children: [
          for (var entry in httpAutocompletes.entries)
            ListTile(
              leading: const Icon(Icons.favorite),
            )
        ],
      )
    );
  }

  void fetchPlacesAutcomplete(String query, LatLng l) async // This method doesn't work completely yet, we need to set a timer to make the api requests slow down
  {
    final uri = Uri.parse("https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&location=${l.latitude}%2C${l.longitude}&radius=500&key=${dotenv.env['MAPS_API_KEY']!}");
    final response = await http.get(uri);
    Map<String, String> m = {};

    if (response.statusCode == 200)
    {
      final locations = jsonDecode(response.body);
      locations['predictions'].forEach((value) => m[value['description']] = value['place_id']);

      setState(() {
        httpAutocompletes = m;
      });
    }
    else
    {
      throw Exception('Failed to get places autocorrect');
    }
  }
}