import 'enums.dart';
import 'trip_model.dart';

class Ticket {
  final int id;
  final int tripId;
  final Trip? trip;
  final double price;
  final double originalPrice;
  final String date;
  final String time;
  final TicketStatus status;
  final int? ownerId;

  Ticket({
    required this.id,
    required this.tripId,
    this.trip,
    required this.price,
    required this.originalPrice,
    required this.date,
    required this.time,
    required this.status,
    this.ownerId,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] ?? 0,
      tripId: json['tripId'] ?? 0,
      trip: json['trip'] != null ? Trip.fromJson(json['trip']) : null,
      price: (json['price'] ?? 0).toDouble(),
      originalPrice: (json['originalPrice'] ?? json['price'] ?? 0).toDouble(),
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      status: TicketStatus.fromJson(json['status']),
      ownerId: json['ownerId'],
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
      'status': status.name,
      if (ownerId != null) 'ownerId': ownerId,
    };
  }
}
