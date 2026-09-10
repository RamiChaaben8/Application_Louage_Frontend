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
  int? _driverId;

  String? _selectedStartCity;
  String? _selectedEndCity;

  List<Station> get stations => _stations;
  List<Trip> get trips => _trips;
  bool get isLoadingStations => _isLoadingStations;
  bool get isLoadingTrips => _isLoadingTrips;
  String? get error => _error;

  Station? get selectedStartStation => _selectedStartStation;
  Station? get selectedEndStation => _selectedEndStation;
  DateTime? get selectedDate => _selectedDate;
  int? get driverId => _driverId;
  String? get selectedStartCity => _selectedStartCity;
  String? get selectedEndCity => _selectedEndCity;

  /// Sorted, deduplicated list of city names from loaded stations.
  List<String> get cities {
    final seen = <String>{};
    final result = <String>[];
    for (final s in _stations) {
      if (seen.add(s.city)) result.add(s.city);
    }
    result.sort();
    return result;
  }

  /// Stations that belong to [city], or all stations if [city] is null.
  List<Station> stationsForCity(String? city) {
    if (city == null) return _stations;
    return _stations.where((s) => s.city == city).toList();
  }

  void setStartCity(String? city) {
    _selectedStartCity = city;
    // Clear station if it no longer belongs to the new city
    if (city != null && _selectedStartStation?.city != city) {
      _selectedStartStation = null;
    }
    notifyListeners();
  }

  void setEndCity(String? city) {
    _selectedEndCity = city;
    if (city != null && _selectedEndStation?.city != city) {
      _selectedEndStation = null;
    }
    notifyListeners();
  }

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
    _selectedStartCity = null;
    _selectedEndCity = null;
    _selectedDate = null;
    _driverId = null;
    _trips = [];
    notifyListeners();
  }

  Future<void> loadStations() async {
    _isLoadingStations = true;
    notifyListeners();

    _stations = await _tripService.getStations();

    _isLoadingStations = false;
    notifyListeners();
  }

  Future<void> loadDriverTrips(int driverId) async {
    _driverId = driverId;
    await searchTrips(driverId: driverId, onlyAvailable: false);
  }

  Future<void> searchTrips({int? driverId, bool onlyAvailable = true}) async {
    if (driverId != null) {
      _driverId = driverId;
    }
    _isLoadingTrips = true;
    _error = null;
    notifyListeners();

    _trips = await _tripService.getTrips(
      startStationId: _selectedStartStation?.id,
      endStationId: _selectedEndStation?.id,
      date: _selectedDate,
      driverId: _driverId,
      onlyAvailable: onlyAvailable,
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
      await searchTrips(driverId: driverId ?? _driverId); // Refresh list after creation
    }
    return success;
  }

  Future<bool> updateTripStatus(int tripId, TripStatus status) async {
    final success = await _tripService.updateTripStatus(tripId, status.index);
    if (success) {
      // Find the trip and update its status locally or just re-fetch
      await searchTrips(driverId: _driverId);
    }
    return success;
  }
}
