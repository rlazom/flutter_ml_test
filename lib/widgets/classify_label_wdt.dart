import 'dart:async';

import 'package:flutter/material.dart';
import 'package:test_ml/services/camera_service.dart';
import 'package:test_ml/services/tensorflow_service.dart';

class ClassifyLabelWdt extends StatefulWidget {
  final Function reDraw;

  const ClassifyLabelWdt({Key key, this.reDraw}) : super(key: key);

  @override
  _ClassifyLabelWdtState createState() => _ClassifyLabelWdtState();
}

class _ClassifyLabelWdtState extends State<ClassifyLabelWdt> {

  List<dynamic> _currentRecognition = [];                       // current list of recognition
  StreamSubscription _streamSubscription;                       // listens the changes in tensorflow recognitions
  TensorflowService _tensorflowService = TensorflowService();   // tensorflow service injection
  CameraService _cameraService = CameraService();

  @override
  void initState() {
    super.initState();

    // starts the streaming to tensorflow results
    _startRecognitionStreaming();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  _startRecognitionStreaming() {
    if (_streamSubscription == null) {
      _streamSubscription = _tensorflowService.recognitionStream.listen((recognition) {
        print('ClassifyLabelWdt - _startRecognitionStreaming() - _tensorflowService.recognitionStream');
        if (recognition != null) {
          // rebuilds the screen with the new recognitions
          setState(() {
            _currentRecognition = recognition;
          });
        } else {
          _currentRecognition = [];
        }
      });
    }
  }

  String getClassifyLabel(result) {
    print('getClassifyLabel()');
    print('getClassifyLabel() - result: $result');

    String label =  result['label'].toString();
    label = label.replaceAll('\n', ' ');

    int idx = label.indexOf(' ');
    return label.substring(idx).trim();
  }

  String getClassifyConfidence(result) {
    double confidence = result['confidence'];
    confidence *= 100;
    String confidenceStr = '${confidence.toStringAsFixed(2)}%';
    return confidenceStr;
  }

  _buildListOfRecognitions() {
    List<Widget> widgetsList = new List();

//    if(_image != null || stream == true) {
    if(_currentRecognition == null || _currentRecognition.isEmpty) {
      widgetsList.add(
          new Chip(label: new Text('UNKNOWN'),)
      );
    } else {
      for(var res in _currentRecognition) {
        String label = getClassifyLabel(res);
        widgetsList.add(
            Flexible(
                child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: new Text(label)
                )
            )
        );
      }
    }
//    } else {
//      widgetsList.add(
//          new Container()
//      );
//    }

    return Row(
      children: widgetsList,
    );
  }

  _capturePicture() async {
    await _cameraService.capturePicture();
    widget.reDraw();
  }

  _buildRecognitionWdt() {
    String recognitionLabel = '';
    String recognitionConfidence = '';
    if(_currentRecognition != null && _currentRecognition.isNotEmpty) {
      var _current = _currentRecognition.first;
      recognitionLabel = getClassifyLabel(_current);
      recognitionConfidence = getClassifyConfidence(_current);
    }

    return Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.7),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  new Text('$recognitionConfidence', style: Theme.of(context).textTheme.caption,),
                  new Text('$recognitionLabel', style: Theme.of(context).textTheme.headline5,),
                ],
              ),
            ),
            Container(
              width: 40,
              child: RawMaterialButton(
                onPressed: _capturePicture,
                shape: CircleBorder(),
                fillColor: Colors.blue,
                child: Icon(Icons.camera_alt),
              ),
            ),
          ],
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildRecognitionWdt();
  }
}
