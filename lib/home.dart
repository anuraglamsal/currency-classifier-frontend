import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';

class MyHomePage extends StatefulWidget {
	MyHomePage({super.key, required this.title, required this.cameras});

	String title;
	List<CameraDescription> cameras;

	@override
	State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

	late CameraController controller;

	@override
	initState() {
		super.initState();
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
		if (!controller.value.isInitialized) {return null;}
		if (controller.value.isTakingPicture) {return null;}
		try {
			await controller.setFlashMode(FlashMode.off);
			XFile picture = await controller.takePicture();
			Navigator.push(context, MaterialPageRoute(
					builder: (context) => DisplayPictureScreen(
						imagePath: picture,
					)));
		} on CameraException catch (e) {
			debugPrint('Error occured while taking picture: $e');
			return null;
		}
	}

	@override
	void dispose() {
		controller.dispose();
		super.dispose();
	}
	
	@override
	Widget build(BuildContext context) {
		if (!controller.value.isInitialized) {
			return Scaffold(
				body: Center(
					child: CircularProgressIndicator(
					)
				)
			);
		}
		final scale = 1 / (controller.value.aspectRatio * MediaQuery.of(context).size.aspectRatio);
		return Scaffold(
			body: Container(
				child: Stack(
					children: [
						Transform.scale(
							scale: scale,
							alignment: Alignment.topCenter,
							child: CameraPreview(controller)
						),
						Align(
							alignment: Alignment.bottomCenter,
							child: FloatingActionButton(
								onPressed: takePicture,
							),
						)
					]
				)
			)
		);
	}
}
class DisplayPictureScreen extends StatelessWidget {
  const DisplayPictureScreen({super.key, required this.imagePath});
  final XFile imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      body: Image.file(File(imagePath.path)),
    );
  }
}
