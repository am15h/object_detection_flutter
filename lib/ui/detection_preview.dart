import 'package:flutter/material.dart';

class DetectionPreview extends StatelessWidget {
  final Image image;

  const DetectionPreview({Key key, this.image}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: image,
    );
  }
}
