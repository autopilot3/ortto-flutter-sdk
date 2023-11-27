class OrttoConfig {
  String appKey;
  String endpoint;
  bool shouldSkipNonExistingContacts = false;
  bool allowAnonUsers = false;

  OrttoConfig(
    this.appKey,
    this.endpoint, {
      this.shouldSkipNonExistingContacts = false,
      this.allowAnonUsers = false,
    }
  );

  Map<String, dynamic> toMap() {
    return {
      'appKey': appKey,
      'endpoint': endpoint,
      'shouldSkipNonExistingContacts': shouldSkipNonExistingContacts,
      'allowAnonUsers': allowAnonUsers,
    };
  }
}

