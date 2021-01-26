import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';

// singleton class used as a service
class TensorflowService {
  // singleton boilerplate
  static final TensorflowService _tensorflowService = TensorflowService._internal();

  factory TensorflowService() {
    return _tensorflowService;
  }
  // singleton boilerplate
  TensorflowService._internal();

  StreamController<List<dynamic>> _recognitionController = StreamController();
  Stream get recognitionStream => this._recognitionController.stream;
  bool _modelLoaded = false;
  int _numResults = 2;
  double _threshold = 0.1;

  Future<void> loadModel() async {
    print('TensorflowService - loadModel()');
    try {
      this._recognitionController.add(null);
      await Tflite.loadModel(
        model: 'assets/dl_cnn/model_unquant.tflite',
        labels: 'assets/dl_cnn/labels.txt',
      );
      _modelLoaded = true;
    } catch (e) {
      print('error loading model');
      print(e);
    }
    print('TensorflowService - loadModel() - DONE');
  }

  Future<void> classifyImage(File img) async {
    print('TensorflowService - classifyImage()');
    if (_modelLoaded) {
      print('runModel() - Tflite.runModelOnImage');
      List<dynamic> recognitions = await Tflite.runModelOnImage(
          path: img.path,
          numResults: _numResults,
          threshold: _threshold,
          imageMean: 127.5,
          imageStd: 127.5
      );
      print('runModel() - Tflite.runModelOnImage - DONE');
      print('recognitions: $recognitions');

      // shows recognitions on screen
      if (recognitions.isNotEmpty) {
        print(recognitions[0].toString());
        if (this._recognitionController.isClosed) {
          // restart if was closed
          this._recognitionController = StreamController();
        }
        // notify to listeners
        this._recognitionController.add(recognitions);
      }
    }
  }

  Future<void> classifyFrame(CameraImage img) async {
    print('TensorflowService - classifyFrame()');
    if (_modelLoaded) {
      print('runModel() - Tflite.runModelOnFrame');
      List<dynamic> recognitions = await Tflite.runModelOnFrame(
        bytesList: img.planes.map((plane) {
          return plane.bytes;
        }).toList(), // required
        imageHeight: img.height,
        imageWidth: img.width,
        numResults: _numResults,
        threshold: _threshold,
      );
      print('runModel() - Tflite.runModelOnFrame - DONE');

      // shows recognitions on screen
      if (recognitions.isNotEmpty) {
        print(recognitions[0].toString());
        if (this._recognitionController.isClosed) {
          // restart if was closed
          this._recognitionController = StreamController();
        }
        // notify to listeners
        this._recognitionController.add(recognitions);
      }
    }
  }

  Future<void> stopRecognitions() async {
    if (!this._recognitionController.isClosed) {
      this._recognitionController.add(null);
      this._recognitionController.close();
    }
  }

  void dispose() async {
    this._recognitionController.close();
    Tflite.close();
  }
}