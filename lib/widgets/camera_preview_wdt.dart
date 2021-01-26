import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraPreviewWdt extends StatelessWidget {
  final CameraController cameraCtrl;

  const CameraPreviewWdt({Key key, this.cameraCtrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (cameraCtrl == null || !cameraCtrl.value.isInitialized) {
      return CircularProgressIndicator();
    } else {
//      return AspectRatio(
//        aspectRatio: cameraCtrl.value.aspectRatio,
//        child: CameraPreview(cameraCtrl),
//      );
      return CameraPreview(cameraCtrl);
    }
  }
}
