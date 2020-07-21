import 'package:flutter/material.dart';
import 'package:object_detection/tflite/recognition.dart';
import 'package:object_detection/ui/box_widget.dart';
import 'package:object_detection/ui/detection_preview.dart';
import 'camera_view.dart';

class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<Recognition> results;

  Image image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 600,
            child: Stack(
              children: <Widget>[
                CameraView(resultsCallback, imagePreviewCallback),
                boundingBoxes(results),
              ],
            ),
          ),
          FlatButton(
            child: Text('Preview'),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => DetectionPreview(
                        image: image,
                      )));
            },
          )
        ],
      ),
    );
  }

  Widget boundingBoxes(List<Recognition> results) {
    if (results == null) {
      return Container();
    }
    return Stack(
      children: results
          .map((e) => BoxWidget(
                result: e,
              ))
          .toList(),
    );
  }

  void resultsCallback(List<Recognition> results) {
    print(results);
    setState(() {
      this.results = results;
    });
  }

  void imagePreviewCallback(Image image) {
    setState(() {
      this.image = image;
    });
  }
}
