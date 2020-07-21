import 'dart:ui';

class CameraViewSingleton {
  CameraViewSingleton _instance = CameraViewSingleton();
  CameraViewSingleton get instance => _instance;

  Size cameraPreviewSize;
  Size screenPreviewSize;
}
