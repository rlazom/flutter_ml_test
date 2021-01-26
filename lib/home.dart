import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:test_ml/services/camera_service.dart';
import 'package:test_ml/services/tensorflow_service.dart';
import 'package:test_ml/widgets/camera_preview_wdt.dart';
import 'package:test_ml/widgets/classify_label_wdt.dart';
import 'package:test_ml/widgets/thumbnail_img_wdt.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TensorflowService _tensorFlowService = TensorflowService();
  CameraService _cameraService = CameraService();

//  File _image;
//  var picker = ImagePicker();
//  List<CameraDescription> cameras;
//  CameraController cameraCtrl;
  bool _stream;

  @override
  void initState() {
    super.initState();

    _stream = false;
    _initialize();
  }


  @override
  void dispose() {
    _cameraService.dispose();
    _tensorFlowService.dispose();
    super.dispose();
  }

  _initialize() async {
    print('MyHomePage - initialize()');

    await Future.wait([
      _tensorFlowService.loadModel(),
      _cameraService.initializeCameras(),
    ]);

    print('MyHomePage - initialize() - DONE');
    if (mounted) {
      setState(() {});
    }
  }

  pickImage() async {
    await _cameraService.pickImage();
    setState(() {});
  }

  _toggleCameraStream(bool value) {
    print('updateStream(val: $value)');

    if(!value) {
      _stopRecognitions();
    } else {
      _startRecognitions();
    }

    setState(() {
      _stream = value;
    });
  }

  _startRecognitions() async {
    try {
      _cameraService.startStreaming();
    } catch (e) {
      print('error streaming camera image');
      print(e);
    }
  }

  _stopRecognitions() async {
    await _cameraService.stopImageStream();
  }

  _reDraw() {
    setState(() {});
  }

  _buildStackBody() {
    return Stack(
      children: [
        CameraPreviewWdt(cameraCtrl: _cameraService.cameraController),
        Align(
          alignment: Alignment.topRight,
          child: Tooltip(message: 'Stream', child: Switch(value: _stream, onChanged: _toggleCameraStream))
        ),
        ThumbnailImgWdt(reDraw: _reDraw),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ClassifyLabelWdt(reDraw: _reDraw)
          ),
        ),
      ],
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
          ),
        ],
      ),
      body: _buildStackBody(),
    );
  }
}