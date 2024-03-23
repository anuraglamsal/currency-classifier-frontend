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
import 'package:vibration/vibration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toggle_switch/toggle_switch.dart';

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
  bool light = true;
  int _initialLabelIndex = 0;

  @override
  initState() {
	//  testVibrator();

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
	  SizedBox(height: 30),
	  Image.asset('assets/logo_2.png', width: 150, height: 50),
	  SizedBox(height: 10),
          Container(
            height: MediaQuery.of(context).size.height * 0.65,
            width: MediaQuery.of(context).size.width,
            child: CameraPreview(controller),
          ),
          SizedBox(height: 30),
	  Row(
		  children: [
			  SizedBox(width: 40), 
			  Column(
				  children: [
					  Switch.adaptive(
						  value: light, 
						  onChanged: (bool value){
							  setState(() {
								  light = value;
							  });
						  }
					  ),
					  Text(
						  "Haptic",
						  style: GoogleFonts.lato(
							  textStyle: TextStyle(color: Colors.white, letterSpacing: .5, fontWeight: FontWeight.bold),
						  ),
					  ),
				  ]
			  ),
			  SizedBox(width: 40),
			  IconButton.filled(
				  iconSize: 90.0,
				  icon: const Icon(Icons.camera),
				  highlightColor: Colors.blue,
				  onPressed: takePicture,
				  alignment: Alignment.center,
			  ),
			  SizedBox(width: 45),
			  Column(
				  children: [
					  SizedBox(height: 6),
					  ToggleSwitch(
						  minWidth: 37.0,
						  minHeight: 37.0,
						  fontSize: 12.0,
						  initialLabelIndex: _initialLabelIndex,
						  activeBgColors: [[Colors.red.shade700], [Colors.blue.shade700]],
						  activeFgColor: Colors.white,
						  inactiveBgColor: Colors.blueGrey.shade300,
						  inactiveFgColor: Colors.grey[900],
						  totalSwitches: 2,
						  labels: ['NP', 'EN'],
						  onToggle: (index) {
							  setState((){
								  _initialLabelIndex = index!;
							  });
						  },
					  ),
					  SizedBox(height: 7),
					  Text(
						  "Lang",
						  style: GoogleFonts.lato(
							  textStyle: TextStyle(color: Colors.white, letterSpacing: .5, fontWeight: FontWeight.bold),
						  ),
					  ),
				  ], 
			  ),
		      ],
		  ),
        ]);
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Scaffold(
          backgroundColor: Color(0xff28282B),
          body: Center(
              child: CircularProgressIndicator(
            color: Colors.white,
          )));
    }

    return Scaffold(
        backgroundColor: Color(0xff1c1c1f),
        body: ModalProgressHUD(
            child: cameraWidget(), 
	    inAsyncCall: _server, 
	    opacity: 0.6, 
	    color: Colors.black, 
	    blur: 1.0,
	    progressIndicator: CircularProgressIndicator(color: Colors.white)
	)
    );
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
    //request.fields["text_field"] = "test";

    //create multipart using filepath, string or bytes
    var pic = await http.MultipartFile.fromPath("file", file.path);
    //add multipart to request
    request.files.add(pic);
    var response = await request.send();

    vibrator(response.headers['etag']);

    //Get the response from the server. Currently we only get an audio file corresponding to the tts.
    Uint8List responseData = await response.stream.toBytes(); //convert the response to bytes such that I can use the response in the app.
    							      //Uint8List is preferred for bytes than List.
    //Play the audio
    await player.play(BytesSource(responseData));

    setState(() {
      _server = false;
    });
  }

  void vibrator(label) async {
	  bool? vib = await Vibration.hasCustomVibrationsSupport();
	  label = label.substring(1, label.length - 1);

	  if (vib!) {
		  Map<String, int> label_to_itr = {"five": 1, "ten": 2, "twenty": 3, "fifty": 4, "hundred": 5, "five hundred": 6, "thousand": 7};
		  List<int> pattern = [];

		  for(int i=0; i<label_to_itr[label]!; ++i){
			  pattern.add(100);
			  pattern.add(500);
		  }

		  Vibration.vibrate(pattern: pattern);
	  }
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
    if(!_server){
	    try {
		    await controller.setFlashMode(FlashMode.off);
		    XFile picture = await controller.takePicture();

		    sendRequest(picture); //send the picture to the server

		    setState(() {
			    _server = true;
		    });
	    } on CameraException catch (e) {
		    debugPrint('Error occured while taking picture: $e');
		    return null;
	    }
    }
  }
}
