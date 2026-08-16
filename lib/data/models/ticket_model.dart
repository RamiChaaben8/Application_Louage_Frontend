import 'enums.dart';
import 'trip_model.dart';
import 'customer_model.dart';

class Ticket {
  final int id;
  final int tripId;
  final Trip? trip;
  final double price;
  final double originalPrice;
  final String date; // Using String for DateOnly to keep it simple, or DateTime
  final String time; // Using String for TimeOnly
  final TicketStatus status;
  final int ownerId;
  final Customer? owner;

  Ticket({
    required this.id,
    required this.tripId,
    this.trip,
    required this.price,
    required this.originalPrice,
    required this.date,
    required this.time,
    required this.status,
    required this.ownerId,
    this.owner,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      tripId: json['tripId'] ?? 0,
      // Be cautious with recursive parsing if Trip includes Tickets
      trip: json['trip'] != null ? Trip.fromJson(json['trip']) : null,
      price: (json['price'] ?? 0).toDouble(),
      originalPrice: (json['originalPrice'] ?? 0).toDouble(),
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      status: json['status'] != null
          ? TicketStatusExtension.fromString(json['status'].toString())
          : TicketStatus.active,
      ownerId: json['ownerId'] ?? 0,
      owner: json['owner'] != null ? Customer.fromJson(json['owner']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tripId': tripId,
      'price': price,
      'originalPrice': originalPrice,
      'date': date,
      'time': time,
      'status': status.toString().split('.').last,
      'ownerId': ownerId,
      // Avoid circular json encoding
    };
  }
}
