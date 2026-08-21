import 'package:flutter/material.dart';
import '../data/models/station_model.dart';
import '../data/models/trip_model.dart';
import '../data/models/enums.dart';
import '../data/sources/trip_service.dart';

class TripProvider with ChangeNotifier {
  final TripService _tripService = TripService();

  List<Station> _stations = [];
  List<Trip> _trips = [];
  bool _isLoadingStations = false;
  bool _isLoadingTrips = false;
  String? _error;

  Station? _selectedStartStation;
  Station? _selectedEndStation;
  DateTime? _selectedDate;

  List<Station> get stations => _stations;
  List<Trip> get trips => _trips;
  bool get isLoadingStations => _isLoadingStations;
  bool get isLoadingTrips => _isLoadingTrips;
  String? get error => _error;

  Station? get selectedStartStation => _selectedStartStation;
  Station? get selectedEndStation => _selectedEndStation;
  DateTime? get selectedDate => _selectedDate;

  void setStartStation(Station? station) {
    _selectedStartStation = station;
    notifyListeners();
  }

  void setEndStation(Station? station) {
    _selectedEndStation = station;
    notifyListeners();
  }

  void setSelectedDate(DateTime? date) {
    _selectedDate = date;
    notifyListeners();
  }

  void clearFilters() {
    _selectedStartStation = null;
    _selectedEndStation = null;
    _selectedDate = null;
    notifyListeners();
    searchTrips();
  }

  Future<void> loadStations() async {
    _isLoadingStations = true;
    notifyListeners();

    _stations = await _tripService.getStations();

    _isLoadingStations = false;
    notifyListeners();
  }

  Future<void> searchTrips() async {
    _isLoadingTrips = true;
    _error = null;
    notifyListeners();

    _trips = await _tripService.getTrips(
      startStationId: _selectedStartStation?.id,
      endStationId: _selectedEndStation?.id,
      date: _selectedDate,
    );

    _isLoadingTrips = false;
    notifyListeners();
  }

  Future<bool> createTrip({
    required int startStationId,
    required int endStationId,
    required DateTime departureTime,
    int? driverId,
  }) async {
    final success = await _tripService.createTrip(
      startStationId: startStationId,
      endStationId: endStationId,
      departureTime: departureTime,
      driverId: driverId,
    );
    if (success) {
      await searchTrips(); // Refresh list after creation
    }
    return success;
  }

  Future<bool> updateTripStatus(int tripId, TripStatus status) async {
    final success = await _tripService.updateTripStatus(tripId, status.index);
    if (success) {
      // Find the trip and update its status locally or just re-fetch
      await searchTrips();
    }
    return success;
  }
}
