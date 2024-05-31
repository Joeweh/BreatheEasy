import 'package:breathe_easy/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:breathe_easy/api.dart';
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

class RoutePage extends StatefulWidget {
  final List<NavInstruction> instructions;

  const RoutePage({super.key, required this.instructions});

  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Directions"),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 2, 110, 44),
      ),
      body: Container(
        alignment: Alignment.bottomCenter,
        margin: const EdgeInsets.all(10),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemBuilder: (BuildContext context, int index) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(widget.instructions[index].text),
                        ),
                      );
                    },
                    itemCount: widget.instructions.length,
                  ),
                ),
              ),
              FilledButton.tonal(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Exit")),
            ]),
      ),
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
  double aq = 0;
  int miles = 0;

  // in minutes
  int est = 0;

  late GoogleMapController mapController;
  Marker? _startMarker;
  Marker? _endMarker;
  var api_key = (dotenv.env['MAPS_API_KEY']).toString();
  MapEntry<String, String> startQuery = MapEntry("", "");
  MapEntry<String, String> endQuery = MapEntry("", "");
  var originTextField = TextEditingController();
  var destinationTextField = TextEditingController();
  double numRoutes = 5; // Test Num
  int curRoute = 0;
  late List<RoutePrediction> routes;

  bool routeDisplayed = false;

  bool isRequestingStart = false;
  bool isRequestingEnd = false;

  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();



  LatLng _center = LatLng(43.281631, -0.802300);

  bool noSpikes = false;
  void setNumRoutes(int x) {
    numRoutes = x as double;
  }

  double getNumRoutes() {
    return numRoutes;
  }

  void setAQ(double x) {
    aq = x;
  }

  double getAQ() {
    return aq;
  }

  void setMiles(int x) {
    miles = x;
  }

  int getMiles() {
    return miles;
  }

  void setEst(int x) {
    est = x;
  }

  int getEst() {
    return est;
  }

  void setStartQuery(MapEntry<String, String> s) async {
    if (s.value != "") {
      setState(() {
        startQuery = s;
        originTextField.text = s.key;
        routeDisplayed = false;
      });

      if (endQuery.key != "Destination") {
        await getRoute();
      }
    }
  }

  void setEndQuery(MapEntry<String, String> s) async {
    if (s.value != "") {
      setState(() {
        endQuery = s;
        destinationTextField.text = s.key;
        routeDisplayed = false;
      });
      if (startQuery.key != "Origin") {
        await getRoute();
      }
    }
  }

  String formatEST(int est) {
    int days = est ~/ (24 * 60);
    int hours = (est % (24 * 60)) ~/ 60;
    int minutes = est % 60;

    if (days > 0) {
      return "${days} days, ${hours} hours";
    } else if (hours > 0) {
      return "${hours} hours, ${minutes} mins";
    } else {
      return "${minutes} mins";
    }
  }

Text formatAQ(double aq) {
  if (aq <= 1.0) {
    return const Text(
      'Great Air Quality',
      style: TextStyle(
        color: Colors.white,
      ),
    );
  } else if (aq < 3.0) {
    return const Text(
      'Good Air Quality',
      style: TextStyle(
        color: Colors.white,
      ),
    );
  } else if (aq < 5.0) {
    return const Text(
      'Bad Air Quality',
      style: TextStyle(
        color: Colors.orange,
      ),
    );
  } else {
    return const Text(
      'Terrible Air Quality',
      style: TextStyle(
        color: Colors.red,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(startQuery.value != "" && endQuery.value != "" && routeDisplayed ?
            "${formatEST(est)} (${miles.toStringAsFixed(1)} miles)" : "BreatheEasy", // Format est and miles
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: startQuery.value != "" && endQuery.value != "" && routeDisplayed ? formatAQ(aq) : Placeholder(),
            ),
          ),
        ],
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 2, 110, 44),
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
                              const Text("Route #: "),
                              Expanded(
                                  child: Slider(
                                value: curRoute as double,
                                max: numRoutes - 1,
                                divisions: (numRoutes).truncate(),
                                onChanged: (double value) {
                                  setState(() {
                                    setEst(routes[curRoute]
                                        .durationMinutes
                                        .truncate());
                                    setMiles(routes[curRoute]
                                        .distanceMiles
                                        .truncate());
                                    setAQ(routes[curRoute].airScore);
                                    curRoute = value.truncate();
                                    polylineCoordinates.clear();
                                    routes[curRoute]
                                        .points
                                        .forEach((LatLng point) {
                                      polylineCoordinates.add(LatLng(
                                          point.latitude, point.longitude));
                                    });
                                  });
                                },
                                label: (curRoute + 1).round().toString(),
                              )),
                              Expanded(
                                  child: FilledButton(
                                onPressed: routeDisplayed
                                    ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) {
                                              return RoutePage(
                                                instructions: routes[curRoute]
                                                    .instructions,
                                              );
                                            },
                                            fullscreenDialog: true,
                                          ),
                                        );
                                      }
                                    : null,
                                child: Text(routeDisplayed
                                    ? "Start Route"
                                    : "Loading..."),
                              )),
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
      readOnly: true,
      onTap: () async {
        var locationSelection = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  SearchBarPageState(callback: m, location: _center),
              fullscreenDialog: true),
        );

          await mapController.moveCamera(CameraUpdate.newLatLngZoom(
              const LatLng(51.5, -0.118),
              13));

          LatLng l = LatLng(locationSelection.latitude as double,
              locationSelection.longitude as double);

          setState(() {
            _center = l;
          });
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

  Widget googleMapWidget(BuildContext context) {
    askForLocation();

    return Container(
        child: GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: _center,
        zoom: 11.0,
      ),
      markers: {
        if (_startMarker != null) _startMarker!,
        if (_endMarker != null) _endMarker!,
      },
      polylines: Set<Polyline>.of(polylines.values),
    ));
  }

  void askForLocation() async {
    var location = Location();

    var serviceEnabled = await location.serviceEnabled();

    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();

      if (!serviceEnabled) {
        throw Exception('location not allowed');
      }
    }

    var permissionGranted = await location.hasPermission();

    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        throw Exception('location permission denied');
      }
    }

    var currentLocation = await location.getLocation();

    // update variables when location changes
    await mapController.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(currentLocation.latitude as double,
            currentLocation.longitude as double),
        13));

    LatLng l = LatLng(currentLocation.latitude as double,
        currentLocation.longitude as double);

    _center = l;
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
  }

  Future<void> getRoute() async {
    polylineCoordinates.clear();
    setState(() {
      curRoute = 0;
    });
    polylines.clear();
    ApiCall a = ApiCall();
    routes = await a.routeCall(startQuery.key, endQuery.key);

    setNumRoutes(routes.length);
    setEst(routes[curRoute].durationMinutes.truncate());
    setMiles(routes[curRoute].distanceMiles.truncate());
    setAQ(routes[curRoute].airScore);

    setState(() {});
    routes[curRoute].points.forEach((LatLng point) {
      polylineCoordinates.add(LatLng(point.latitude, point.longitude));
    });
    
    _startMarker = Marker(markerId: MarkerId('start'), position: polylineCoordinates.first);
    _endMarker = Marker(markerId: MarkerId('end'), position: polylineCoordinates.last);

    PolylineId id = PolylineId('poly');
    Polyline polyline = Polyline(
        polylineId: id, color: Colors.blue, points: polylineCoordinates);
    polylines[id] = polyline;

    setState(() {
      routeDisplayed = true;
    });
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
  Map<String, LatLng> httpAutocompletes = {};
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
                  onPressed: () async {
                    widget.callback(const MapEntry("", ""));
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
                    Navigator.of(context).pop(httpAutocompletes[element]);
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
    Map<String, LatLng> m = {};
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
