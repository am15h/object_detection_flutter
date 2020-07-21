import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:object_detection/ui/camera_view_singleton.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class Recognition {
  int _id;
  String _label;
  double _score;
  Rect _location;

  Recognition(this._id, this._label, this._score, [this._location]);

  String get id => _id.toString();

  String get label => _label;

  double get score => _score;

  Rect get location => _location;

  Rect get renderLocation {
//    print(ResizeOp(4128, 2322, ResizeMethod.BILINEAR).inverseTransform(
//        Point(location.topLeft.dx, location.topLeft.dy), 640, 360));

    double ratioX = 360 / 2322;
    double ratioY = 640 / 4128;
//    double ratioX = 1;
//    double ratioY = 1;
    double transLeft = location.left * ratioX;
    double transTop = location.top * ratioY;
    double transWidth = location.width * ratioX;
    double transHeight = location.height * ratioY;
    Rect result = Rect.fromLTWH(transLeft, transTop, transWidth, transHeight);
    if (label == "chair") {
      print(result);
    }
    return result;
  }

  @override
  String toString() {
    return 'Recognition(id: $id, label: $label, score: $score, location: $location)';
  }
}
