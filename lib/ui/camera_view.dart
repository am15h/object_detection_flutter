import 'dart:io';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:object_detection/tflite/classifier.dart';
import 'package:object_detection/tflite/recognition.dart';
import 'package:object_detection/tflite/stats.dart';
import 'package:object_detection/ui/camera_view_singleton.dart';
import 'package:object_detection/utils/isolate_utils.dart';

class CameraView extends StatefulWidget {
  final Function(List<Recognition> recognitions) resultsCallback;
  final Function(Stats stats) statsCallback;
  const CameraView(this.resultsCallback, this.statsCallback);
  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  List<CameraDescription> cameras;
  CameraController controller;
  bool predicting;
  Classifier classifier;
  GlobalKey globalKey = GlobalKey();
  IsolateUtils isolateUtils;
  bool firstImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializeCamera();
    classifier = Classifier();
    predicting = false;
    firstImage = true;
    isolateUtils = IsolateUtils();
    isolateUtils.start();
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
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
        controller.stopImageStream();
        break;
      case AppLifecycleState.resumed:
        await controller.startImageStream(onLatestImageAvailable);
        break;
      default:
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
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
      Map<String, dynamic> params = {
        "address": classifier.interpreter.address,
        "labels": classifier.labels,
        "image": cameraImage,
      };
//      List results = await compute(inference, params);
      List results = await inference(params);
      var uiThreadInferenceElapsedTime =
          DateTime.now().millisecondsSinceEpoch - uiThreadTimeStart;

//      print("UI Thread Inference Elapsed Time: $uiThreadInferenceElapsedTime");

      widget.resultsCallback(results[0]);
      widget.statsCallback((results[1] as Stats)
        ..totalElapsedTime = uiThreadInferenceElapsedTime);
      setState(() {
        predicting = false;
      });
    }
  }

  Future<List> inference(Map<String, dynamic> params) async {
    ReceivePort responsePort = ReceivePort();
    if (isolateUtils.sendPort == null) {
      return [];
    }
    isolateUtils.sendPort.send(IsolateData(params["image"], params["address"],
        params["labels"], responsePort.sendPort));
    var results = await responsePort.first;
    return results;
  }
}
