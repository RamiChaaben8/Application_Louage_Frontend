import 'station_model.dart';
import 'ticket_model.dart';
import 'enums.dart';

class Trip {
  final int id;
  final DateTime departureTime;
  final int startStationId;
  final Station? startStation;
  final int endStationId;
  final Station? endStation;
  final List<Ticket> tickets;
  final int? driverId;
  final String? driverName;
  final List<String> passengerNames;
  final TripStatus status;

  Trip({
    required this.id,
    required this.departureTime,
    this.startStationId = 0,
    this.startStation,
    this.endStationId = 0,
    this.endStation,
    this.tickets = const [],
    this.driverId,
    this.driverName,
    this.passengerNames = const [],
    this.status = TripStatus.pending,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    final start = json['startStation'] != null ? Station.fromJson(json['startStation']) : null;
    final end = json['endStation'] != null ? Station.fromJson(json['endStation']) : null;

    DateTime depTime = DateTime.now();
    if (json['departureTime'] != null) {
      try {
        depTime = DateTime.parse(json['departureTime']);
      } catch (_) {}
    }

    return Trip(
      id: json['id'] ?? 0,
      departureTime: depTime,
      startStationId: json['startStationId'] ?? start?.id ?? 0,
      startStation: start,
      endStationId: json['endStationId'] ?? end?.id ?? 0,
      endStation: end,
      tickets: json['tickets'] != null
          ? (json['tickets'] as List).map((i) => Ticket.fromJson(i)).toList()
          : [],
      driverId: json['driverId'],
      driverName: json['driverName'],
      passengerNames: json['passengerNames'] != null
          ? List<String>.from(json['passengerNames'])
          : [],
      status: TripStatus.fromJson(json['status']),
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
      'driverId': driverId,
      'driverName': driverName,
      'passengerNames': passengerNames,
      'status': status.index,
    };
  }
}
