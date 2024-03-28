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
import 'dart:async';

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
  bool _server1 = false;
  bool _server2 = false;
  bool light = true;
  int labelIndex = 0;
  Timer? _timer;

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
						  initialLabelIndex: labelIndex,
						  activeBgColors: [[Colors.red.shade700], [Colors.blue.shade700]],
						  activeFgColor: Colors.white,
						  inactiveBgColor: Colors.blueGrey.shade300,
						  inactiveFgColor: Colors.grey[900],
						  totalSwitches: 2,
						  labels: ['NP', 'EN'],
						  onToggle: (index) {
							  setState((){
								  labelIndex = index!;
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
	    inAsyncCall: _server1 || _server2, 
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
        if (call.arguments == "volume_down"){
          takePicture();
        }
	else if(call.arguments == "volume_up"){
	  int index = (labelIndex==1 ? labelIndex-1 : labelIndex+1);
	  setState((){
		  labelIndex = index;
	  });
	}
      }

      return Future.value(null);
    });
  }

  Future<void> audioRequest(XFile file) async {
    var request = http.MultipartRequest(
        "POST", Uri.parse("http://192.168.1.70:3000/audio"));
    request.fields["lang_idx"] = labelIndex.toString();
    var pic = await http.MultipartFile.fromPath("file", file.path);
    request.files.add(pic);
    var response = await request.send();

    Uint8List responseData = await response.stream.toBytes(); 
    await player.play(BytesSource(responseData));

    await Future.delayed(Duration(seconds: 1, milliseconds: 500));

    vibrator(response.headers['etag']);

    setState(() {
      _server1 = false;
    });

    if(!_server2){
	    _timer?.cancel();
    }
  }

  Future<void> imageRequest() async {
    var response = await http.get(Uri.parse("http://192.168.1.70:3000/image"));

    popupBoundedPic(response.bodyBytes);

    setState(() {
      _server2 = false;
    });

    if(!_server1){
	    _timer?.cancel();
    }
  }

  popupBoundedPic(boundedImage){
      return showDialog(
        context: context,
        builder: (BuildContext context) => Dialog(
		child: Image.memory(boundedImage, width: 300, height: 300),
        ),
      );
  }

  void vibrator(label) async {
	  bool? vib = await Vibration.hasCustomVibrationsSupport();
	  label = label.substring(1, label.length - 1);

	  if (vib!) {
		  Map<String, int> label_to_itr = {"five": 1, "ten": 2, "twenty": 3, "fifty": 4, "hundred": 5, "five hundred": 6, "thousand": 7};
		  List<int> pattern = [];

		  for(int i=0; i<label_to_itr[label]!; ++i){
			  pattern.add(200);
			  pattern.add(300);
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
    if(!_server1 && !_server2){
	    try {
		    await controller.setFlashMode(FlashMode.off);
		    XFile picture = await controller.takePicture();

		    setState(() {
			    _server1 = true;
			    _server2 = true;
		    });

		    audioRequest(picture);
		    imageRequest();

		    //final stopwatch = Stopwatch()..start();

		    _timer = Timer(Duration(seconds: 20), () {
			    alertMessage();
			    setState((){
				    _server1 = false;
				    _server2 = false;
			    });
		    });
	    } on CameraException catch (e) {
		    debugPrint('Error occured while taking picture: $e');
		    return null;
	    }
    }
  }

  alertMessage(){
	  return showDialog(
		  context: context,
		  builder: (BuildContext context) => AlertDialog(
			  backgroundColor: Colors.red.shade900,
			  title: Text("Response wait time of 20 seconds exceeded!",
				  style: GoogleFonts.lato(
					  textStyle: TextStyle(color: Colors.white, letterSpacing: .5, fontWeight: FontWeight.bold),
				  ),
			  ),
		  ),
	  );
  }
}
