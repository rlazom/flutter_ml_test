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
      title: 'Flutter ML Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter ML Demo'),
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
  var _output;
  File _image;
  var picker = ImagePicker();
  List<CameraDescription> cameras;
  CameraController cameraCtrl;
  bool takePhoto;

  @override
  void initState() {
    super.initState();
    takePhoto = false;

    loadModel();
    initializeCameras();
  }

  loadModel() async {
    await Tflite.loadModel(
      model: 'assets/dl_cnn/model_unquant.tflite',
      labels: 'assets/dl_cnn/labels.txt',
//      isAsset: false,
    );
  }

  Future<void> initializeCameras() async {
    cameras = await availableCameras();

    print('availableCameras');
    print(cameras);
    await initializeController();
    print('Camera ${cameras[1]} initialized');
  }

  initializeController() async {
    cameraCtrl = CameraController(cameras[1], ResolutionPreset.medium);

    try {
      await cameraCtrl.initialize();
    } on CameraException catch (e) {
      print('CameraException $e');
    }

    if (mounted) {
      setState(() {});
    }
  }

  _clear() {
    if(mounted) {
      setState(() {
        _image = null;
        _output = null;
      });
    }
  }

  Widget _buildCameraPreviewWidget() {
    if (cameraCtrl == null || !cameraCtrl.value.isInitialized) {
      return CircularProgressIndicator();
    } else {
      return AspectRatio(
        aspectRatio: cameraCtrl.value.aspectRatio,
        child: CameraPreview(cameraCtrl),
      );
    }
  }

  _buildThumbnailImg() {
    List<Widget> list = new List();

    if(cameras == null) {
      return Container();
    }

    if(_image == null) {
      list.add(
        new Icon(Icons.photo, size: 64, color: Colors.black26,)
      );
    } else {
      list.addAll([
        SizedBox(
          child: Image.file(_image),
          width: 64.0,
          height: 64.0,
        ),
        new IconButton(icon: Icon(Icons.delete), onPressed: _clear),
      ]);
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: list,
      ),
    );
  }

  /// Display a row of toggle to select the camera (or a message if no camera is available).
  Widget _cameraTogglesRowWidget() {
    final List<Widget> toggles = <Widget>[];

    if (cameras == null) {
      return const Text('Initializing camera controller...');
    }
    if (cameras.isEmpty) {
      return const Text('No camera found');
    } else {
      for (CameraDescription cameraDescription in cameras) {
        toggles.add(
          SizedBox(
            width: 90.0,
            child: RadioListTile<CameraDescription>(
              title: Icon(getCameraLensIcon(cameraDescription.lensDirection)),
              groupValue: cameraCtrl?.description,
              value: cameraDescription,
              onChanged: cameraCtrl != null && cameraCtrl.value.isRecordingVideo
                  ? null
                  : onNewCameraSelected,
            ),
          ),
        );
      }
    }

    return Row(children: toggles, mainAxisAlignment: MainAxisAlignment.center,);
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (cameraCtrl != null) {
      await cameraCtrl.dispose();
    }
    cameraCtrl = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    // If the controller is updated then update the UI.
    cameraCtrl.addListener(() {
      if (mounted) setState(() {});
      if (cameraCtrl.value.hasError) {
        print('Camera error ${cameraCtrl.value.errorDescription}');
      }
    });

    try {
      await cameraCtrl.initialize();
    } on CameraException catch (e) {
      print('Camera error $e');
    }

    if (mounted) {
      setState(() {});
    }
  }

  /// Returns a suitable camera icon for [direction].
  IconData getCameraLensIcon(CameraLensDirection direction) {
    switch (direction) {
      case CameraLensDirection.back:
        return Icons.camera_rear;
      case CameraLensDirection.front:
        return Icons.camera_front;
      case CameraLensDirection.external:
        return Icons.camera;
    }
    throw ArgumentError('Unknown lens direction');
  }

  capturePictures() async {
    print('capturePictures()');

    if (cameraCtrl.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    var timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = "${extDir.path}/Pictures/flutter_test";
    await Directory(dirPath).create(recursive: true);
    final String filePath = "$dirPath/($timestamp).jpg";

    print('capturePictures() - filePath: "$filePath"');

    try {
      await cameraCtrl.takePicture(filePath);
    } on CameraException catch (e) {
      print('CameraException - Error: $e');
      return null;
    }

    _image = File(filePath);
    await classifyImage(_image);
  }

  pickImage() async {
    var image = await picker.getImage(source: ImageSource.gallery);
    if (image == null) return null;

    setState(() {
      _image = File(image.path);
    });

    print('Start classification');
    await classifyImage(_image);
  }

  Future<List<dynamic>> classifyImage(File image) async {
    print('classifyImage()');

    var output = await Tflite.runModelOnImage(
        path: image.path,
        numResults: 2,
        threshold: 0.5,
        imageMean: 127.5,
        imageStd: 127.5);
    setState(() {
      _output = output;
    });

    print('classifyImage() - output');
    return output;
  }

  String getClassifyLabel(result) {
    print('getClassifyLabel()');
    print('getClassifyLabel() - result: $result');

    String label = result['label'].toString();
    double confidence = result['confidence'];
    String confidenceStr = confidence.toStringAsFixed(2);

    int idx = label.indexOf(' ');
    return label.substring(idx).trim() + ' ($confidenceStr)';
  }

  _buildClassifyLabelWdt() {
    List resultList = _output;
    List<Widget> widgetsList = new List();

    if(_image != null) {
      if(resultList == null || resultList.isEmpty) {
        widgetsList.add(
            new Chip(label: new Text('UNKNOWN'),)
        );
      } else {
        for(var res in resultList) {
          String label = getClassifyLabel(res);
          widgetsList.add(
              new Chip(label: new Text(label))
          );
        }
      }
    } else {
      widgetsList.add(
          new Container()
      );
    }

    return Row(
      children: widgetsList,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Import from Gallery',
            icon: Icon(Icons.add_photo_alternate),
            onPressed: pickImage,
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _buildThumbnailImg(),
                _buildClassifyLabelWdt(),
                _buildCameraPreviewWidget(),
                _cameraTogglesRowWidget(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: capturePictures,
        tooltip: 'Capture from Camera',
        child: Icon(Icons.camera_alt),
      ),
    );
  }
}
