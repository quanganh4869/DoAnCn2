enum AddressType { home, office, other }

class Address {
  final String? id;
  final String label;
  final String fullAddress;
  final String city;
  final String state;
  final String zipCode;
  final bool isDefault;
  final AddressType type;

  const Address({
    this.id,
    required this.label,
    required this.fullAddress,
    required this.city,
    required this.state,
    required this.zipCode,
    this.isDefault = false,
    this.type = AddressType.home,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'].toString(),
      label: json['label'] ?? '',
      fullAddress: json['full_address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zip_code'] ?? '',
      isDefault: json['is_default'] ?? false,
      type: AddressType.values.firstWhere(
        (e) => e.name == (json['type'] ?? 'home'),
        orElse: () => AddressType.home,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'label': label,
      'full_address': fullAddress,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'is_default': isDefault,
      'type': type.name,
    };
  }

  String get typeString => type.name;
}