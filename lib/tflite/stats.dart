class Stats {
  int totalElapsedTime;
  int totalPredictTime;
  int inferenceTime;
  int preProcessingTime;

  Stats({this.totalElapsedTime, this.totalPredictTime, this.inferenceTime,
      this.preProcessingTime});

  @override
  String toString() {
    return 'Stats{totalElapsedTime: $totalElapsedTime, inferenceTime: $inferenceTime, preProcessingTime: $preProcessingTime}';
  }
}
