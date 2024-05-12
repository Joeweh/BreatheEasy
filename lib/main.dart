import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  late GoogleMapController mapController;

  final LatLng _center = const LatLng(43.281631, -0.802300);
  final Set<Marker> _markers = {};

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

  @override
  Widget build(BuildContext context) {
    _addMarker(const LatLng(43.3, -0.8), "Test Marker 1");
    _addMarker(const LatLng(43.281631, -0.802300), "Test Marker 2");

    return Scaffold(
      body: Container(
        margin: EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(height: 600, margin: EdgeInsets.all(10), child: GoogleMap(onMapCreated: _onMapCreated, initialCameraPosition: CameraPosition(target: _center, zoom: 11.0,), markers: _markers,)),
            StartLocation(),
            EndLocation(),
          ],
        ),
      )
    );
  }
}

class StartLocation extends StatelessWidget {
  const StartLocation({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(10),
      child: TextField(
        obscureText: false,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Origin',
        ),
      ),
    );
  }
}

class EndLocation extends StatelessWidget {
  const EndLocation({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(10),
      child: TextField(
        obscureText: false,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Destination',
        ),
      ),
    );
  }
}
