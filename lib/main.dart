import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:breathe_easy/api.dart';

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
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  Map<PolylineId, Polyline> _polylines = {};
  PolylinePoints polylinePoints = PolylinePoints();
  List<LatLng> polylineCoordinates = [];
  var api_key = (dotenv.env['MAPS_API_KEY']).toString();
  var originTextField = TextEditingController();
  var destinationTextField = TextEditingController();
  double numRoutes = 5; // Test Num
  double curRoute = 0;

  MapEntry<String, String> startQuery = MapEntry("Origin", "");
  MapEntry<String, String> endQuery = MapEntry("Destination", "");

  final LatLng _center = const LatLng(43.281631, -0.802300);

  void setStartQuery(MapEntry<String, String> s) {
    if (s.value != "") {
      setState(() {
        startQuery = s;
        originTextField.text = s.key;
      });
    }
  }

  void setEndQuery(MapEntry<String, String> s) {
    if (s.value != "") {
      setState(() {
        endQuery = s;
        destinationTextField.text = s.key;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("EST"),
        actions: const [
          Row(
            children: [
              Padding(
                padding: EdgeInsets.all(10.0),
                child: Text("AQ"),
              ),
              Padding(
                padding: EdgeInsets.all(10.0),
                child: Text("MINS"),
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
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 2, 110, 44),
              ),
              child: Text('Settings'),
            ),
            ListTile(
              leading: const Icon(
                Icons.settings,
              ),
              title: const Text('User Preferences'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.stacked_bar_chart_sharp,
              ),
              title: const Text('User Stats'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(child: googleMapWidget()),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Theme.of(context).canvasColor,
                  boxShadow: [
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
                              Slider(
                                value: curRoute,
                                max: numRoutes,
                                divisions: numRoutes as int,
                                onChanged: (double value) {
                                  setState(() {
                                    curRoute = value;
                                  });
                                },
                                label: (curRoute + 1).round().toString(),
                              ),
                              FilledButton(onPressed: () {}, child: Text("Start Route"))
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

  List<LatLng> latLen = [LatLng(43.3, -0.8), LatLng(43.281631, -0.802300)];
  List<Marker> marks = [
    Marker(markerId: MarkerId('Test1'), position: LatLng(43.3, -0.8)),
    Marker(markerId: MarkerId('Test2'), position: LatLng(43.281631, -0.802300))
  ];

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
              builder: (context) => SearchBarPageState(
                    callback: m,
                  ),
              fullscreenDialog: true),
        );
      },
      autofocus: false,
      showCursor: false,
      decoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context).scaffoldBackgroundColor,
          labelText: labelString,
          border: OutlineInputBorder()),
    );
  }

  Widget googleMapWidget() {
    _addMarker(const LatLng(43.3, -0.8), "Test Marker 1");
    _addMarker(const LatLng(43.281631, -0.802300), "Test Marker 2");
    getDirections(marks, setState);
    return Container(
        height: 600,
        child: GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 11.0,
            ),
            markers: _markers,
            polylines: Set<Polyline>.of(_polylines.values)));
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
  }

  void _addMarker(LatLng l, String markerId) {
    setState(() {
      _markers.add(Marker(
        markerId: MarkerId(markerId),
        position: l,
      ));
    });
  }

  getDirections(List<Marker> markers, newSetState) async {
    List<LatLng> polylineCoordinates = [];
    List<PolylineWayPoint> polylineWayPoints = [];
    for (var i = 0; i < markers.length; i++) {
      polylineWayPoints.add(PolylineWayPoint(
          location:
              "${markers[i].position.latitude.toString()},${markers[i].position.longitude.toString()}",
          stopOver: true));
    }

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        api_key,
        PointLatLng(
            markers.first.position.latitude, markers.first.position.longitude),
        PointLatLng(
            markers.last.position.latitude, markers.last.position.longitude),
        travelMode: TravelMode.driving,
        wayPoints: polylineWayPoints);

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    } else {
      print(result.errorMessage);
    }

    newSetState(() {});

    addPolyLine(polylineCoordinates, newSetState);
  }

  addPolyLine(List<LatLng> polylineCoordinates, newSetState) {
    PolylineId id = PolylineId("Poly");
    Polyline polyline = Polyline(
        polylineId: id, color: Colors.blue, points: polylineCoordinates);
    _polylines[id] = polyline;
    newSetState(() {});
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
    PlacePrediction p = await a.placeCall(query, LatLng(51.5, 0.1));

    p.autocompletes.forEach((element) {
      m[element.key] = element.value;
    });

    setState(() {
      httpAutocompletes = m;
    });
  }
}
