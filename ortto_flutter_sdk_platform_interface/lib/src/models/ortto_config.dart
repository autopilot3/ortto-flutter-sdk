class OrttoConfig {
  String appKey;
  String endpoint;
  bool shouldSkipNonExistingContacts = false;

  OrttoConfig(
    this.appKey,
    this.endpoint, {
    this.shouldSkipNonExistingContacts = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'appKey': appKey,
      'endpoint': endpoint,
      'shouldSkipNonExistingContacts': shouldSkipNonExistingContacts,
    };
  }
}
