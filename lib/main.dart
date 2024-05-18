import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart' as places;
import 'package:breathe_easy/api.dart';


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
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) 
  {
    return const Scaffold(
      body: DirectionPage()
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

  MapEntry<String, String> startQuery = MapEntry("Origin", "");
  MapEntry<String, String> endQuery = MapEntry("Destination", "");

  final LatLng _center = const LatLng(43.281631, -0.802300);

  void setStartQuery(MapEntry<String, String> s)
  {
    setState(() {
      startQuery = s;
    });
  }

  void setEndQuery(MapEntry<String, String> s)
  {
    setState(() {
      endQuery = s;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      margin: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          googleMapWidget(),
          const SizedBox(height: 20),
          location(context, startQuery, setStartQuery),
          const SizedBox(height: 20),
          location(context, endQuery, setEndQuery)
        ],
      ),
    );
  }

  List<LatLng> latLen = [LatLng(43.3, -0.8), LatLng(43.281631, -0.802300)];
  List<Marker> marks = [Marker(markerId: MarkerId('Test1'), position: LatLng(43.3, -0.8)), 
  Marker(markerId: MarkerId('Test2'), position: LatLng(43.281631, -0.802300))];
  
  TextField location(BuildContext context, MapEntry<String, String> location, Function(MapEntry<String, String>) m) {
    return TextField(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => SearchBarPageState(callback: m,),
                  fullscreenDialog: true),
            );
          },
          autofocus: false,
          showCursor: false,
          decoration: InputDecoration(
              hintText: location.key,
              hintStyle: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 24),
              filled: true,
              fillColor: Colors.grey[200],
              border: InputBorder.none),
        );
  }

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


class LocationBar extends StatefulWidget {
  final ValueChanged<String> callback;
  LocationBar({key, required this.callback});
  
  @override
  void initState() {

  }

  @override
  State<LocationBar> createState() => LocationBarState(callback: callback);
}

class LocationBarState extends State<LocationBar> {
  final ValueChanged<String> callback;
  LocationBarState({key, required this.callback});

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
          labelText: 'Location',
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
  final Function(MapEntry<String, String>) callback;
  
  const SearchBarPageState({super.key, required this.callback});

  @override
  State<SearchBarPageState> createState() => _SearchBarPageState();
}

class _SearchBarPageState extends State<SearchBarPageState> {
  Map<String, String> httpAutocompletes = {};
  Map<ElevatedButton, Map<String, String>> autoList = {};

  MapEntry<String, String> selected = MapEntry("", "");

  @override
  Widget build(BuildContext context) {
    print("Test123");

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {widget.callback(MapEntry("","")); Navigator.of(context).pop();},
        ), 
        centerTitle: true,
      ),
      body: Container(
        margin: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            LocationBar(callback: fetchPlacesAutcomplete,),
            placesAutoComplete(),
          ],
        ),
      ),
    );
  }

  Container placesAutoComplete() // Does not work yet
  {
    List<String> locs = httpAutocompletes.entries.map((entry) => entry.key).toList();

    return Container(
      margin: const EdgeInsets.all(10),
      child: Column
      (
        children: [
          for (String element in locs)
            Container(
              margin: const EdgeInsets.all(10), 
              child: ElevatedButton(
                onPressed: () async{
                  selected = MapEntry(element, httpAutocompletes[element].toString());
                  widget.callback(selected); Navigator.of(context).pop();
                }, 
                child: Text(element),))
        ],
      )
    );
  }

  void fetchPlacesAutcomplete(String query) async
  {
    // Map<String, String> m = {};
    
    // if (query == "")
    // {
    //   m = {};
    // }
    // else
    // {
    //   places.LatLng l = const places.LatLng(lat: 43.281631, lng: -0.802300, ); // Temp constant lat long coordinates
    //   places.LatLngBounds bounds = places.LatLngBounds(
    //     southwest: places.LatLng(lat: l.lat - 1, lng: l.lng - 1),
    //     northeast: places.LatLng(lat: l.lat + 1, lng: l.lng + 1)
    //   );

    //   var locations = places.FlutterGooglePlacesSdk(dotenv.env['MAPS_API_KEY']!);
    //   var predictions = await locations.findAutocompletePredictions(query, origin: l, locationBias: bounds);

    //   predictions.predictions.forEach((element) {m[element.primaryText] = element.placeId;});
    // }

    // setState(() {
    //   httpAutocompletes = m;
    // });

    Map<String, String> m = {};
    ApiCall a = ApiCall();
    PlacePrediction p = await a.placeCall(query, LatLng(51.5, 0.1));

    p.autocompletes.forEach((element) {m[element.key] = element.value; });

    setState(() {
      httpAutocompletes = m;
    });
  }
}