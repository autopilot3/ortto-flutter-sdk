class IdentityResult {
  final String? sessionId;

  IdentityResult({this.sessionId});

  factory IdentityResult.fromMap(Map<String, dynamic> map) {
    return IdentityResult(sessionId: map['sessionId']);
  }
}