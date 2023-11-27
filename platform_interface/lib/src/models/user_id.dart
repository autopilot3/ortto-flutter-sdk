class UserID {
  String? firstName;
  String? lastName;
  bool acceptsGdpr;
  String? contactId;
  String? email;
  String? externalId;
  String? phone;

  UserID({
    this.firstName,
    this.lastName,
    this.acceptsGdpr = false,
    this.contactId,
    this.email,
    this.externalId,
    this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'accepts_gdpr': acceptsGdpr,
      'contact_id': contactId,
      'email': email,
      'external_id': externalId,
      'phone_number': phone,
    };
  }
}
