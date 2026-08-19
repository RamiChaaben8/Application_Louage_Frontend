import 'package:flutter/material.dart';
import '../data/models/station_model.dart';
import '../data/models/trip_model.dart';
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
}
