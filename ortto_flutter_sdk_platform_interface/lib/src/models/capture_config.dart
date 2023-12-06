class CaptureConfig {
  String dataSourceKey;
  String captureJsUrl;
  String apiHost;

  CaptureConfig(
    this.dataSourceKey,
    this.captureJsUrl,
    this.apiHost,
  );

  Map<String, dynamic> toMap() {
    return {
      'dataSourceKey': dataSourceKey,
      'captureJsUrl': captureJsUrl,
      'apiHost': apiHost,
    };
  }
}

