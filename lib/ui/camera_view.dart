import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as imageLib;
import 'package:object_detection/tflite/classifier.dart';
import 'package:object_detection/tflite/recognition.dart';
import 'package:object_detection/ui/camera_view_singleton.dart';
import 'package:object_detection/utils/image_utils.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class CameraView extends StatefulWidget {
  final Function(List<Recognition> recognitions) resultsCallback;
  final Function(Image image) previewCallback;
  const CameraView(this.resultsCallback, this.previewCallback);
  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  List<CameraDescription> cameras;
  CameraController controller;
  bool predicting;
  Classifier classifier;
  GlobalKey globalKey = GlobalKey();

  bool firstImage;

  @override
  void initState() {
    super.initState();
    initializeCamera();
    classifier = Classifier();
    predicting = false;
    firstImage = true;
  }

  void initializeCamera() async {
    cameras = await availableCameras();
    controller =
        CameraController(cameras[0], ResolutionPreset.medium, enableAudio: false);
    await controller.initialize();
    await Future.delayed(Duration(milliseconds: 200));
    controller.startImageStream(onLatestImageAvailable);

    Size previewSize = controller.value.previewSize;
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller.value.isInitialized) {
      return Container();
    }
    return AspectRatio(
        key: globalKey,
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller));
  }

  onLatestImageAvailable(CameraImage cameraImage) async {
    if (classifier.interpreter != null && classifier.labels != null) {
      if (predicting) {
        return;
      }
      setState(() {
        predicting = true;
      });

      List results = await compute(inference, {
        "address": classifier.interpreter.address,
        "labels": classifier.labels,
        "image": cameraImage,
      });

      ui.Codec codec = await ui.instantiateImageCodec(results[0] as Uint8List,
          targetWidth: 300, targetHeight: 300);

      ui.Image resultImage = (await codec.getNextFrame()).image;

      ByteData resultBytes = await generateResultImage(resultImage, results[1]);

      widget.previewCallback(Image.memory(resultBytes.buffer.asUint8List()));

      widget.resultsCallback(results[1]);
      setState(() {
        predicting = false;
      });
    }
  }
}

List inference(Map<String, dynamic> params) {
  imageLib.Image image = ImageUtils.convertYUV420ToARGB8888(params["image"]);
  var interpreter = Interpreter.fromAddress(params["address"]);
  var classifier =
      Classifier(interpreter: interpreter, labels: params["labels"]);
  return classifier.predict(image);
}

Future<ByteData> generateResultImage(
    ui.Image image, List<Recognition> rect) async {
  var recorder = ui.PictureRecorder();
  var canvas = Canvas(recorder);

  var paint = Paint()..style = PaintingStyle.stroke;

  canvas.drawImage(image, Offset.zero, Paint());
  rect.forEach((element) {
    canvas.drawRect(
        element.location,
        paint
          ..color = Color.fromRGBO(Random().nextInt(255), Random().nextInt(255),
              Random().nextInt(255), 1));
  });
  canvas.save();

  final picture = recorder.endRecording();
  final img = await picture.toImage(image.width, image.height);
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);

  return bytes;
}
