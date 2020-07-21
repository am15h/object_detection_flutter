import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';

class IsolateUtils {
  static const String DEBUG_NAME = "InferenceIsolate";

  Isolate _isolate;
  ReceivePort _receivePort = ReceivePort();
  SendPort _sendPort;

  void start({int interpreterAddress}) async {
    _isolate = await Isolate.spawn<IsolateData>(
      entryPoint,
      IsolateData(null, interpreterAddress, _receivePort.sendPort),
      debugName: DEBUG_NAME,
    );

    _receivePort.listen(isolateListener);

    _sendPort = await _receivePort.first;
  }

  void isolateListener(message) {}

  void entryPoint(IsolateData isolateData) {}
}

class IsolateData {
  CameraImage cameraImage;
  int interpreterAddress;
  SendPort sendPort;

  IsolateData(this.cameraImage, this.interpreterAddress, this.sendPort);
}
