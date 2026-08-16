import 'user_model.dart';
import 'ticket_model.dart';

class Customer extends User {
  final List<Ticket> tickets;

  Customer({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.email,
    required super.phoneNum,
    this.tickets = const [],
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phoneNum: json['phoneNum'] ?? 0,
      tickets: json['tickets'] != null 
          ? (json['tickets'] as List).map((i) => Ticket.fromJson(i)).toList()
          : [],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    data['tickets'] = tickets.map((v) => v.toJson()).toList();
    return data;
  }
}
