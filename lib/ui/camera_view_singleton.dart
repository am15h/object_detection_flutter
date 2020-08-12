import 'dart:ui';

/// Singleton to record size related data
class CameraViewSingleton {
  static double ratio;
  static Size screenSize;
  static Size inputImageSize;
  static Size get actualPreviewSize =>
      Size(screenSize.width, screenSize.width * ratio);
}
