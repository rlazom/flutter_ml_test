import 'package:flutter/material.dart';
import 'package:test_ml/services/camera_service.dart';

class ThumbnailImgWdt extends StatelessWidget {
  final Function reDraw;

  const ThumbnailImgWdt({Key key, this.reDraw}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    CameraService _cameraService = CameraService();
    List<Widget> list = new List();
    var image = _cameraService.image;

    if(image == null) {
      list.add(
          new Icon(Icons.photo, size: 64, color: Colors.black26,)
      );
    } else {
      list.add(
        InkWell(
          onLongPress: () {
            _cameraService.clearImageThumbnail();
            reDraw();
          },
          child: SizedBox(
            child: Image.file(image),
            width: 64.0,
            height: 64.0,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: list,
      ),
    );
  }
}
