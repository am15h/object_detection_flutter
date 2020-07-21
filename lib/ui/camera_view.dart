import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as imageLib;
import 'package:object_detection/tflite/classifier.dart';
import 'package:object_detection/tflite/recognition.dart';
import 'package:object_detection/ui/camera_view_singleton.dart';
import 'package:object_detection/utils/image_utils.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class CameraView extends StatefulWidget {
  final Function(List<Recognition> recognitions) resultsCallback;
  const CameraView(this.resultsCallback);
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
    controller = CameraController(cameras[0], ResolutionPreset.medium,
        enableAudio: false);
    await controller.initialize();
    await Future.delayed(Duration(milliseconds: 200));
    controller.startImageStream(onLatestImageAvailable);

    // Camera view preview size
    Size previewSize = controller.value.previewSize;
    CameraViewSingleton.inputImageSize = previewSize;

    // Screen size
    Size screenSize = MediaQuery.of(context).size;
    CameraViewSingleton.screenSize = screenSize;

    if (Platform.isAndroid) {
      // On Android image is initially rotated by 90 degrees
      CameraViewSingleton.ratio = screenSize.width / previewSize.height;
    } else {
      // For iOS
      CameraViewSingleton.ratio = screenSize.width / previewSize.width;
    }
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

      var uiThreadTimeStart = DateTime.now().millisecondsSinceEpoch;
      List results = await compute(inference, {
        "address": classifier.interpreter.address,
        "labels": classifier.labels,
        "image": cameraImage,
      });
      var uiThreadInferenceElapsedTime =
          DateTime.now().millisecondsSinceEpoch - uiThreadTimeStart;

      print("UI Thread Inference Elapsed Time: $uiThreadInferenceElapsedTime");

      widget.resultsCallback(results);
      setState(() {
        predicting = false;
      });
    }
  }
}

List inference(Map<String, dynamic> params) {
  imageLib.Image image = ImageUtils.convertYUV420ToImage(params["image"]);
  var interpreter = Interpreter.fromAddress(params["address"]);
  var classifier =
      Classifier(interpreter: interpreter, labels: params["labels"]);
  return classifier.predict(image);
}
