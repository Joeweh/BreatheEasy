import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:breathe_easy/api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  // Load Environment Variables
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
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
  Widget build(BuildContext context) {
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
  Marker? _startMarker; 
  Marker? _endMarker;
  var api_key = (dotenv.env['MAPS_API_KEY']).toString();
  MapEntry<String, String> startQuery = MapEntry("Origin", "");
  MapEntry<String, String> endQuery = MapEntry("Destination", "");
  var originTextField = TextEditingController();
  var destinationTextField = TextEditingController();

  bool isRequestingStart = false;
  bool isRequestingEnd = false;

  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();

  final LatLng _center = const LatLng(43.281631, -0.802300);

  void setStartQuery(MapEntry<String, String> s) {
    if (s.value != "") {
      setState(() {
        startQuery = s;
        originTextField.text = s.key;
      });
      getLatLng(s, true);
    }
  }

  void setEndQuery(MapEntry<String, String> s) {
    if (s.value != "") {
      setState(() {
        endQuery = s;
        destinationTextField.text = s.key;
      });
      getLatLng(s, false);
    }
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

  Widget googleMapWidget() {
    return Container(
      height: 600, 
      margin: const EdgeInsets.all(10), 
      child: GoogleMap(
        onMapCreated: _onMapCreated, 
        initialCameraPosition: CameraPosition(target: _center, zoom: 11.0,),
        markers: {if (_startMarker!= null) _startMarker!, if (_endMarker != null) _endMarker!,}, 
        polylines: Set<Polyline>.of(polylines.values) ,
      )
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
  }

  Future<void> getLatLng(MapEntry<String, String> query, bool isStart) async {
    if (query.value.isEmpty) return;

    if (isStart && isRequestingStart) return;
    if (!isStart && isRequestingEnd) return;

    if (isStart) {
      setState(() {
        isRequestingStart = true;
      });
    } else {
      setState(() {
        isRequestingEnd = true;
      });
    }

    final placeId = query.value;
    final url = Uri.parse('https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$api_key');

    try {
      final response = await http.get(url);

      if(response.statusCode == 200) {
        final place = json.decode(response.body)['result'];
        final latlng = LatLng(place['geometry']['location']['lat'], place['geometry']['location']['lng']);
        final markerId = isStart ? 'start_marker' : 'end_marker';

        setState(() {
          if(isStart) {
            _startMarker = Marker(markerId: MarkerId(markerId), position: latlng);
          } else {
            _endMarker = Marker(markerId: MarkerId(markerId), position: latlng);
          }

          if(_startMarker != null && _endMarker != null) {
            getRoute();
          }
        });
      }
    } catch (e) {
      // Handle errors here
      print('Failed to fetch location details: $e');
    } finally {
      if (isStart) {
        setState(() {
          isRequestingStart = false;
        });
      } else {
        setState(() {
          isRequestingEnd = false;
        });
      }
    }
  }

  void getRoute() async {
    polylineCoordinates.clear();
    polylines.clear();
    List<LatLng> m = [];
    ApiCall a = ApiCall();
    List<RoutePrediction> r = await a.routeCall(startQuery.key, endQuery.key);
    
    setState((){});
    r[0].points.forEach((LatLng point){
      polylineCoordinates.add(LatLng(point.latitude, point.longitude));
    }); 

    PolylineId id = PolylineId('poly');
    Polyline polyline = Polyline(polylineId: id,
    color: Colors.blue, points: polylineCoordinates);

    polylines[id] = polyline;
  }
}

class LocationBar extends StatefulWidget {
  final ValueChanged<String> callback;
  LocationBar({key, required this.callback});

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

  Widget locationBar() {
    return Container(
      margin: const EdgeInsets.all(10),
      child: TextField(
        obscureText: false,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Location',
        ),
        onChanged: (value) {
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

  Container placesAutoComplete() {
    List<String> locs = httpAutocompletes.entries.map((entry) => entry.key).toList();

    return Container(
      margin: const EdgeInsets.all(10),
      child: Column(
        children: [
          for (String element in locs)
            Container(
              margin: const EdgeInsets.all(10), 
              child: ElevatedButton(
                onPressed: () async {
                  selected = MapEntry(element, httpAutocompletes[element].toString());
                  widget.callback(selected); Navigator.of(context).pop();
                }, 
                child: Text(element),))
        ],
      )
    );
  }

  void fetchPlacesAutcomplete(String query) async {
    Map<String, String> m = {};
    ApiCall a = ApiCall();
    PlacePrediction p = await a.placeCall(query, LatLng(51.5, 0.1));

    p.autocompletes.forEach((element) {m[element.key] = element.value; });
    setState(() {
      httpAutocompletes = m;
    });
  }
}
