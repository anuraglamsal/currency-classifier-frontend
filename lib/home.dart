import 'package:flutter/material.dart';
//import 'package:flutter/rendering.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:http/src/byte_stream.dart';
import 'package:volume_watcher/volume_watcher.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title, required this.cameras});

  String title;
  List<CameraDescription> cameras;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late CameraController controller;
  static const _volumeBtnChannel = MethodChannel("mychannel");
  final player = AudioPlayer();
  bool _server = false;

  @override
  initState() {
    super.initState();

    initializeCameraController(); //Camera Controller intialization.
    initializeVolume(); //Setting the volume to be 1 and customizing the volume buttons to take pictures.
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget cameraWidget() {
    return Column(
        //mainAxisAlignment: MainAxisAlignment.center,
        //crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 100),
          Container(
            height: MediaQuery.of(context).size.height * 0.65,
            width: MediaQuery.of(context).size.width,
            child: CameraPreview(controller),
          ),
          SizedBox(height: 30),
          IconButton.filled(
            iconSize: 90.0,
            icon: const Icon(Icons.camera),
            highlightColor: Colors.blue,
            onPressed: takePicture,
          )
        ]);
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Scaffold(
          backgroundColor: Color(0xff1c1c1f),
          body: Center(
              child: CircularProgressIndicator(
            color: Colors.white,
          )));
    }

    return Scaffold(
        backgroundColor: Color(0xff1c1c1f),
        body: ModalProgressHUD(child: cameraWidget(), inAsyncCall: _server));
  }

  Future<void> initializeVolume() async {
    //Setting volume to max.
    late var maxVolume;
    try {
      maxVolume = await VolumeWatcher.getMaxVolume;
    } on PlatformException {
      // handle exception
    }

    //Code to handle what to do when volume keys are pressed. The replacement of default behavior of volume buttons is done in 'MainActivity.kt' in
    //'android/app/....'.
    VolumeWatcher.setVolume(maxVolume);
    _volumeBtnChannel.setMethodCallHandler((call) {
      if (call.method == "volumeBtnPressed") {
        if (call.arguments == "volume_down" || call.arguments == "volume_up") {
          takePicture();
        }
      }

      return Future.value(null);
    });
  }

  Future<void> sendRequest(XFile file) async {
    //create multipart request for POST or PATCH method
    var request = http.MultipartRequest(
        "POST", Uri.parse("http://192.168.1.70:3000/upload"));
    //add text fields
    request.fields["text_field"] = "test";
    //create multipart using filepath, string or bytes
    var pic = await http.MultipartFile.fromPath("file", file.path);
    //add multipart to request
    request.files.add(pic);
    var response = await request.send();

    //Get the response from the server. Currently we only get an audio file corresponding to the tts.
    Uint8List responseData = await response.stream
        .toBytes(); //convert the response to bytes such that I can use the response in the app.
    //Uint8List is preferred for bytes than List.
    //Play the audio
    await player.play(BytesSource(responseData));

    setState(() {
      _server = false;
    });
  }

  void initializeCameraController() {
    controller = CameraController(widget.cameras[0], ResolutionPreset.max);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });
  }

  Future takePicture() async {
    if (!controller.value.isInitialized) {
      return null;
    }
    if (controller.value.isTakingPicture) {
      return null;
    }
    try {
      await controller.setFlashMode(FlashMode.off);
      XFile picture = await controller.takePicture();

      sendRequest(picture); //send the picture to the server

      setState(() {
        _server = true;
      });

      /*Navigator.push(context, MaterialPageRoute(
					builder: (context) => DisplayPictureScreen(
						imagePath: picture,
					)));*/
    } on CameraException catch (e) {
      debugPrint('Error occured while taking picture: $e');
      return null;
    }
  }
}

/*class DisplayPictureScreen extends StatelessWidget {
  const DisplayPictureScreen({super.key, required this.imagePath});
  final  imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('The picture')),
      body: Image.file(File(imagePath.path)),
    );
  }
}*/
