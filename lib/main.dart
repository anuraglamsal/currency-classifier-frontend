import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'home.dart';
import 'package:flutter/services.dart';

late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _cameras =
      await availableCameras(); // I guess this could be done in the home widget, but whatever.

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: Color(
            0xff28282B), // Setting color of the phone's bottom nav bar to match the over app color.
      ),
    );

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp
    ]); // Locking orientation to portrait mode. Makes sense for a camera app.

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan.shade800),
        useMaterial3: true,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page', cameras: _cameras),
    );
  }
}
