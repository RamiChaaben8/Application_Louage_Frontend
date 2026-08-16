class Station {
  final int id;
  final String city;
  final String name;

  Station({
    required this.id,
    required this.city,
    required this.name,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'],
      city: json['city'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'city': city,
      'name': name,
    };
  }
}
