import 'dart:html';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:breathe_easy/api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:location/location.dart';

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
    return const Scaffold(body: DirectionPage());
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
  int aq = 0;
  int miles = 0;

  // in minutes
  int est = 0;

  late GoogleMapController mapController;
  Marker? _startMarker; 
  Marker? _endMarker;
  var api_key = (dotenv.env['MAPS_API_KEY']).toString();
  MapEntry<String, String> startQuery = MapEntry("Origin", "");
  MapEntry<String, String> endQuery = MapEntry("Destination", "");
  var originTextField = TextEditingController();
  var destinationTextField = TextEditingController();
  double numRoutes = 5; // Test Num
  double curRoute = 0;

  bool isRequestingStart = false;
  bool isRequestingEnd = false;

  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();

  LatLng _center = const LatLng(43.281631, -0.802300);

  bool noSpikes = false;
  void setNumRoutes(double x){
    numRoutes = x;
  }

  double getNumRoutes(){
    return numRoutes;
  }

  void setAQ(int x){
    aq = x;
  }

  int getAQ(){
    return aq;
  }

  void setMiles(int x){
    miles = x;
  }

  int getMiles(){
    return miles;
  }

  void setEst(int x){
    est = x;
  }

  int getEst(){
    return est;
  }

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
    return Scaffold(
      appBar: AppBar(
        title: Text(startQuery.value != "" && endQuery.value != "" ? "EST:" + est.toString() : ""),
        actions: [
          Row(
            children: [
              Padding(
                padding: EdgeInsets.all(10.0),
                child: Text(startQuery.value != "" && endQuery.value != "" ? "AQ:" + aq.toString() : ""),
              ),
              Padding(
                padding: EdgeInsets.all(10.0),
                child: Text(startQuery.value != "" && endQuery.value != "" ? "MILES:" + miles.toString() : ""),
              )
            ],
          )
        ],
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 2, 110, 44),
      ),
      drawer: Drawer(
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            ListTile(
              title: const Text("BreatheEasy"),
            ),
            ListTile(
                title: Row(
              children: [
                Text("No Spikes in AQ: "),
                Transform.scale(scale: 0.8, child: Switch(
                  value: noSpikes,
                  onChanged: ((bool value) {
                    setState(() {
                      noSpikes = value;
                    });
                  }),
                  activeColor: Colors.green,
                ),)
              ],
            )),
          ],
        ),
      ),
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(child: googleMapWidget(context)),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Theme.of(context).canvasColor,
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.white,
                        offset: Offset(0, -0.25),
                        blurRadius: 5.0,
                        spreadRadius: 0.1)
                  ]),
              child: Column(
                children: [
                  location(context, startQuery, setStartQuery,
                      "Starting Location", originTextField),
                  const SizedBox(height: 20),
                  location(context, endQuery, setEndQuery, "Destination",
                      destinationTextField),
                  if (startQuery.value != "" && endQuery.value != "")
                    Container(
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text("Route #: "),
                              Expanded(
                                  child: Slider(
                                value: curRoute,
                                max: numRoutes - 1,
                                divisions: (numRoutes as int) - 1,
                                onChanged: (double value) {
                                  setState(() {
                                    curRoute = value;
                                  });
                                },
                                label: (curRoute + 1).round().toString(),
                              )),
                              Expanded(
                                  child: FilledButton(
                                      onPressed: () {},
                                      child: Text("Start Route"))),
                            ],
                          ),
                        ],
                      ),
                    )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
  
  TextField location(
      BuildContext context,
      MapEntry<String, String> location,
      Function(MapEntry<String, String>) m,
      String labelString,
      var txtController) {
    return TextField(
      controller: txtController,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchBarPageState(callback: m, location: _center),
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


  Widget googleMapWidget(BuildContext context) {
    askForLocation();

    return Container(
        child: GoogleMap(
        onMapCreated: _onMapCreated, 
        initialCameraPosition: CameraPosition(target: _center, zoom: 11.0,),
        markers: {if (_startMarker!= null) _startMarker!, if (_endMarker != null) _endMarker!,}, 
        polylines: Set<Polyline>.of(polylines.values) ,));
  }

  void askForLocation() async {
    var location = Location();

    // blah blah blah please give me your location
    var serviceEnabled = await location.serviceEnabled();

    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();

      if (!serviceEnabled) {
        print('location not allowed');
        return;
      }
    }

    var permissionGranted = await location.hasPermission();

    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        print('location permission denied');
        return;
      }
    }

    // listens for changes in user's location
    location.onLocationChanged.listen((LocationData currentLocation) {
      // update variables when location changes
      mapController.animateCamera(CameraUpdate.newLatLngZoom(
          LatLng(currentLocation.latitude as double,
              currentLocation.longitude as double),
          13));

      LatLng l = LatLng(currentLocation.latitude as double,
          currentLocation.longitude as double);

      _center = l;
      print(_center.latitude);
      print(_center.longitude);
    });
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
        autofocus: true,
      ),
    );
  }
}

class SearchBarPageState extends StatefulWidget {
  final Function(MapEntry<String, String>) callback;
  final LatLng location;

  const SearchBarPageState(
      {super.key, required this.callback, required this.location});

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
      body: Container(
        margin: const EdgeInsets.all(10),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  LocationBar(
                    callback: fetchPlacesAutcomplete,
                  ),
                  placesAutoComplete(),
                ],
              ),
              FilledButton.tonal(
                  onPressed: () {
                    widget.callback(MapEntry("", ""));
                    Navigator.of(context).pop();
                  },
                  child: const Text("Exit")),
            ]),
      ),
    );
  }

  Container placesAutoComplete() {
    List<String> locs =
        httpAutocompletes.entries.map((entry) => entry.key).toList();

    return Container(
        margin: const EdgeInsets.all(10),
        child: Column(
          children: [
            for (String element in locs)
              Container(
                margin: EdgeInsets.symmetric(vertical: 10),
                child: ListTile(
                  title: Text(element),
                  onTap: () async {
                    selected = MapEntry(
                        element, httpAutocompletes[element].toString());
                    widget.callback(selected);
                    Navigator.of(context).pop();
                  },
                  tileColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                ),
              ),
          ],
        ));
  }

  void fetchPlacesAutcomplete(String query) async {
    Map<String, String> m = {};
    ApiCall a = ApiCall();
    PlacePrediction p = await a.placeCall(query, widget.location);

    p.autocompletes.forEach((element) {
      m[element.key] = element.value;
    });

    setState(() {
      httpAutocompletes = m;
    });
  }
}
