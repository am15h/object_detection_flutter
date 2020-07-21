import 'package:flutter/cupertino.dart';
import 'package:object_detection/ui/camera_view_singleton.dart';

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
    double ratio = 1;
    double transLeft = location.left * ratio;
    double transTop = location.top * ratio;
    double transWidth = location.width * ratio;
    double transHeight = location.height * ratio;
    return Rect.fromLTWH(transLeft, transTop, transWidth, transHeight);
  }

  @override
  String toString() {
    return 'Recognition(id: $id, label: $label, score: $score, location: $location)';
  }
}
