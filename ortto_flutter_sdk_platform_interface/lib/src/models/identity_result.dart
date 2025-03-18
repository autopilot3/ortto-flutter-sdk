class IdentityResult {
  final String sessionId;

  IdentityResult({required this.sessionId});

  factory IdentityResult.fromMap(Map<String, dynamic> map) {
    return IdentityResult(
      sessionId: map['session_id'] as String? ?? '',
    );
  }
}