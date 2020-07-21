import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:object_detection/tflite/classifier.dart';
import 'package:object_detection/tflite/recognition.dart';
import 'package:object_detection/ui/box_widget.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class ImagePickerView extends StatefulWidget {
  @override
  _ImagePickerViewState createState() => _ImagePickerViewState();
}

class _ImagePickerViewState extends State<ImagePickerView> {
  Classifier _classifier;

  var results;

  File _image;
  final picker = ImagePicker();

  Image _imageWidget;

  @override
  void initState() {
    super.initState();
    _classifier = Classifier();
  }

  Future getImage() async {
    if (_imageWidget == null) {
      final pickedFile = await picker.getImage(source: ImageSource.gallery);
      setState(() {
        _image = File(pickedFile.path);
      });
    }
    _predict();
  }

  void _predict() async {
    var bytes = _image.readAsBytesSync();
    img.Image imageInput = img.decodeImage(bytes);
    _imageWidget = Image.memory(bytes);
    List<Recognition> results = _classifier.predict(imageInput);
    print(results);
    setState(() {
      this.results = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    print("ScreenSize ${MediaQuery.of(context).size}");
    return Scaffold(
//      appBar: AppBar(
//        title: Text('TfLite Flutter Helper',
//            style: TextStyle(color: Colors.white)),
//      ),
      body: _image == null
          ? Text('No image selected.')
          : Stack(
              children: [
                _imageWidget,
                boundingBoxes(results),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: getImage,
        tooltip: 'Pick Image',
        child: Icon(Icons.add_a_photo),
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
}
