import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart' as places;

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
          locationBar(context, startQuery, setStartQuery),
          const SizedBox(height: 20),
          locationBar(context, endQuery, setEndQuery)
        ],
      ),
    );
  }

  TextField locationBar(BuildContext context, MapEntry<String, String> location, Function(MapEntry<String, String>) m) {
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

    return Container(height: 600, margin: const EdgeInsets.all(10), child: GoogleMap(onMapCreated: _onMapCreated, initialCameraPosition: CameraPosition(target: _center, zoom: 11.0,), markers: _markers,));
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {widget.callback(selected); Navigator.of(context).pop();},
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
            Container(margin: const EdgeInsets.all(10), child: ElevatedButton(onPressed: () {selected = MapEntry(element, httpAutocompletes[element].toString());}, child: Text(element),))
        ],
      )
    );
  }

  void fetchPlacesAutcomplete(String query) async
  {
    Map<String, String> m = {};
    
    if (query == "")
    {
      m = {};
    }
    else
    {
      places.LatLng l = const places.LatLng(lat: 43.281631, lng: -0.802300, ); // Temp constant lat long coordinates
      places.LatLngBounds bounds = places.LatLngBounds(
        southwest: places.LatLng(lat: l.lat - 1, lng: l.lng - 1),
        northeast: places.LatLng(lat: l.lat + 1, lng: l.lng + 1)
      );

      var locations = places.FlutterGooglePlacesSdk(dotenv.env['MAPS_API_KEY']!);
      var predictions = await locations.findAutocompletePredictions(query, origin: l, locationBias: bounds);

      predictions.predictions.forEach((element) {m[element.primaryText] = element.placeId;});
    }

    setState(() {
      httpAutocompletes = m;
    });
  }
}