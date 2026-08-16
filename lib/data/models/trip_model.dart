import 'station_model.dart';
import 'ticket_model.dart';

class Trip {
  final int id;
  final DateTime departureTime;
  final int startStationId;
  final Station? startStation;
  final int endStationId;
  final Station? endStation;
  final List<Ticket> tickets;

  Trip({
    required this.id,
    required this.departureTime,
    required this.startStationId,
    this.startStation,
    required this.endStationId,
    this.endStation,
    this.tickets = const [],
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'],
      departureTime: json['departureTime'] != null 
          ? DateTime.parse(json['departureTime']) 
          : DateTime.now(),
      startStationId: json['startStationId'] ?? 0,
      startStation: json['startStation'] != null ? Station.fromJson(json['startStation']) : null,
      endStationId: json['endStationId'] ?? 0,
      endStation: json['endStation'] != null ? Station.fromJson(json['endStation']) : null,
      tickets: json['tickets'] != null 
          ? (json['tickets'] as List).map((i) => Ticket.fromJson(i)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'departureTime': departureTime.toIso8601String(),
      'startStationId': startStationId,
      'endStationId': endStationId,
      'startStation': startStation?.toJson(),
      'endStation': endStation?.toJson(),
      'tickets': tickets.map((t) => t.toJson()).toList(),
    };
  }
}
