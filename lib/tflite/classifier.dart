import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:object_detection/tflite/recognition.dart';
import 'package:object_detection/ui/camera_view_singleton.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import 'package:image/image.dart' as imageLib;

class Classifier {
  Interpreter _interpreter;

  List<String> _labels;
  static const String MODEL_FILE_NAME = "detect.tflite";

  static const String LABEL_FILE_NAME = "labelmap.txt";
  static const int INPUT_SIZE = 300;

  List<int> _inputShape;
  TfLiteType _inputType;

  List<List<int>> _outputShapes;

  List<TfLiteType> _outputTypes;
  static const int NUM_RESULTS = 3;

  Classifier({
    Interpreter interpreter,
    List<String> labels,
  }) {
    loadModel(interpreter: interpreter);
    loadLabels(labels: labels);
  }

  void loadModel({Interpreter interpreter}) async {
    try {
      _interpreter = interpreter ??
          await Interpreter.fromAsset(
            MODEL_FILE_NAME,
            options: InterpreterOptions()..threads = 4,
          );

      var inputTensors = _interpreter.getInputTensor(0);
      _inputShape = inputTensors.shape;
      _inputType = inputTensors.type;

      var outputTensors = _interpreter.getOutputTensors();
      _outputShapes = [];
      _outputTypes = [];
      outputTensors.forEach((tensor) {
        _outputShapes.add(tensor.shape);
        _outputTypes.add(tensor.type);
      });

//      print("Interpreter created successfully");
    } catch (e) {
      print("Error while creating interpreter: $e");
    }
  }

  void loadLabels({List<String> labels}) async {
    try {
      _labels =
          labels ?? await FileUtil.loadLabels("assets/" + LABEL_FILE_NAME);
//      print("Labels loaded successfully");
    } catch (e) {
      print("Error while loading labels: $e");
    }
  }

  TensorImage getProcessedImage(TensorImage inputImage) {
    int padSize = max(inputImage.height, inputImage.width);
    ImageProcessor imageProcessor = ImageProcessorBuilder()
        .add(Rot90Op())
        .add(ResizeWithCropOrPadOp(padSize, padSize))
        .add(ResizeOp(INPUT_SIZE, INPUT_SIZE, ResizeMethod.BILINEAR))
        .build();
    inputImage = imageProcessor.process(inputImage);
    return inputImage;
  }

  List predict(imageLib.Image image) {
    print("InputImage: height: ${image.height} width: ${image.width}");

    if (_interpreter == null) {
      print("Interpreter not initialized");
      return null;
    }

    TensorImage inputImage = TensorImage.fromImage(image);

    inputImage = getProcessedImage(inputImage);

    List<Object> inputs = [inputImage.buffer];

    TensorBuffer outputLocations = TensorBufferFloat(_outputShapes[0]);
    TensorBuffer outputClasses = TensorBufferFloat(_outputShapes[1]);
    TensorBuffer outputScores = TensorBufferFloat(_outputShapes[2]);
    TensorBuffer numLocations = TensorBufferFloat(_outputShapes[3]);

    Map<int, Object> outputs = {
      0: outputLocations.buffer,
      1: outputClasses.buffer,
      2: outputScores.buffer,
      3: numLocations.buffer,
    };

    _interpreter.runForMultipleInputs(inputs, outputs);

    int resultsCount = min(NUM_RESULTS, numLocations.getIntValue(0));

    List<Recognition> recognitions = [];

    int labelOffset = 1;

    int padSize = max(image.height, image.width);

    ImageProcessor invertProcessor = ImageProcessorBuilder()
        .add(ResizeWithCropOrPadOp(padSize, padSize))
        .add(ResizeOp(INPUT_SIZE, INPUT_SIZE, ResizeMethod.BILINEAR))
        .build();

    List<Rect> locations = BoundingBoxUtils.convert(
      tensor: outputLocations,
      valueIndex: [1, 0, 3, 2],
      boundingBoxAxis: 2,
      boundingBoxType: BoundingBoxType.BOUNDARIES,
      coordinateType: CoordinateType.RATIO,
      height: INPUT_SIZE,
      width: INPUT_SIZE,
    );

    for (int i = 0; i < resultsCount; i++) {
      var label = _labels.elementAt(outputClasses.getIntValue(i) + labelOffset);

      Rect rect = invertProcessor.inverseTransformRect(
          locations[i], image.width, image.height);

//      Rect rect = locations[i];
      recognitions.add(
        Recognition(i, label, outputScores.getDoubleValue(i), rect),
      );
    }

//    return [imageLib.PngEncoder().encodeImage(inputImage.image), recognitions];

//    Map<String, int> counters = Map();
//    final List<Recognition> results = List();
//    for (var index = 0; index < numLocations.getIntValue(0); index++) {
////      if (outputScores.getDoubleValue(index) < threshold) continue;
//
//      String detectedClass =
//          _labels[labelOffset + outputClasses.getIntValue(index)];
//
//      final top = max(0.0, outputLocations.getDoubleValue(index * 4 + 0));
//      final left = max(0.0, outputLocations.getDoubleValue(index * 4 + 1));
//      final bottom = min(1.0, outputLocations.getDoubleValue(index * 4 + 2));
//      final right = min(1.0, outputLocations.getDoubleValue(index * 4 + 3));
//
//      results.add(
//        Recognition(index, detectedClass, outputScores.getDoubleValue(index),
//            Rect.fromLTRB(left*INPUT_SIZE, top*INPUT_SIZE, right*INPUT_SIZE, bottom*INPUT_SIZE)),
//      );
//    }
    return recognitions;
  }

  Interpreter get interpreter => _interpreter;
  List<String> get labels => _labels;
}
