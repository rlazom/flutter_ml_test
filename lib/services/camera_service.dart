import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:test_ml/services/tensorflow_service.dart';

// singleton class used as a service
class CameraService {
  // singleton boilerplate
  static final CameraService _cameraService = CameraService._internal();

  factory CameraService() {
    return _cameraService;
  }
  // singleton boilerplate
  CameraService._internal();

  List<CameraDescription> cameras;
  CameraController _cameraController;
  CameraController get cameraController => _cameraController;
  TensorflowService _tensorFlowService = TensorflowService();
  ImagePicker _picker = ImagePicker();
  bool available = true;
  File _image;
  File get image => _image;


  Future<void> initializeCameras() async {
    print('CameraService - initializeCameras()');

    cameras = await availableCameras();

    try {
      _cameraController = CameraController(
        // Get a specific camera from the list of available cameras.
        cameras.first, //back/primary camera
//        cameras.last, //front camera
        // Define the resolution to use.
        ResolutionPreset.veryHigh,
      );
    } on CameraException catch (e) {
      print('CameraException $e');
    }

    print('CameraService - startService() - DONE');
    // Next, initialize the controller
    try {
      await _cameraController.initialize();
    } on CameraException catch (e) {
      print('Camera initialize error $e');
    }
  }

  dispose() async {
    await _cameraController.dispose();
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

  Future<void> capturePicture() async {
    print('capturePictures()');

    if (_cameraController.value.isTakingPicture ||_cameraController.value.hasError) {
      print('A capture is already pending, do nothing.');
      return null;
    }

    XFile file;
    try {
      file = await _cameraController.takePicture();
    } on CameraException catch (e) {
      print('CameraException - Error: $e');
      return null;
    }

    _image = File(file.path);
    await _tensorFlowService.classifyImage(_image);
//    return File(file.path);
  }

  clearImageThumbnail() {
    _image = null;
  }

  Future<void> pickImage() async {
    var image = await _picker.getImage(source: ImageSource.gallery);
    if (image == null) return null;

    _image = File(image.path);
    await _tensorFlowService.classifyImage(_image);
  }

  Future<void> startStreaming() async {
    print('startStreaming()');

    // Checking whether the controller is initialized
    if (!_cameraController.value.isInitialized) {
      print("Camera Controller is not initialized");
      return null;
    }
    if (_cameraController.value.isStreamingImages) {
      print("Camera Controller is already streaming");
      return null;
    }

    _cameraController.startImageStream((img) async {
      try {
        if (available) {
          // Loads the model and recognizes frames
          available = false;
          await _tensorFlowService.classifyFrame(img);
          await Future.delayed(Duration(seconds: 1));
          available = true;
        }
      } catch (e) {
        print('error running model with current frame');
        print(e);
      }
    });
  }

  Future stopImageStream() async {
    if (_cameraController.value.isStreamingImages) {
      await this._cameraController.stopImageStream();
    }
  }
}
