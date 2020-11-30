import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List _output;
  File _image;
  var picker = ImagePicker();
  List<CameraDescription> cameras;
  CameraController controller;
  bool takePhoto;

  @override
  void initState() {
    super.initState();
    takePhoto = false;

//    loadModel().then((value) {
//      setState(() {});
//    });

    loadModel();
    initializeCameras();
  }

  loadModel() async {
    await Tflite.loadModel(
        model: 'assets/dl_cnn/model_unquant.tflite',
        labels: 'assets/dl_cnn/labels.txt');
  }

  Future<void> initializeCameras() async {
    cameras = await availableCameras();
    initializeController();
  }

  initializeController() {
    controller = CameraController(cameras[0], ResolutionPreset.medium);
    controller.initialize().then((_) {
      if (!mounted) return;
      if (takePhoto) {
        const interval = const Duration(seconds: 3);
        new Timer.periodic(interval, (Timer t) => capturePictures());
      }
    });
  }

  capturePictures() async {
    var timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = "${extDir.path}/Pictures/flutter_test";
    await Directory(dirPath).create(recursive: true);
    final String filePath = "$dirPath/($timestamp).png";
    takePhoto = true;

    if (takePhoto) {
      controller.takePicture(filePath).then((_) async {
        if (takePhoto) {
          File imgFile = File(filePath);
          var res = await classifyImage(imgFile);
          print('Class detected:');
          print(res);
          takePhoto = false;
        } else {
          return;
        }
      });
    }
  }

  Future<List<dynamic>> classifyImage(File image) async {
    var output = await Tflite.runModelOnImage(
        path: image.path,
        numResults: 2,
        threshold: 0.5,
        imageMean: 127.5,
        imageStd: 127.5);
    setState(() {
      _output = output;
    });
    return output;
  }

  pickImage() async {
    var image = await picker.getImage(source: ImageSource.camera);
    if (image == null) return null;

    setState(() {
      _image = File(image.path);
    });

    print('Start classification');
    var res = await classifyImage(_image);

    print('Class detected:');
    print(res);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: capturePictures,
        tooltip: 'Increment',
        child: Icon(Icons.camera_alt),
      ),
    );
  }
}
