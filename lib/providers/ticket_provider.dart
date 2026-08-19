import 'package:flutter/material.dart';
import '../data/models/ticket_model.dart';
import '../data/sources/ticket_service.dart';

class TicketProvider with ChangeNotifier {
  final TicketService _ticketService = TicketService();

  List<Ticket> _myTickets = [];
  List<Ticket> _resaleTickets = [];
  bool _isLoadingMyTickets = false;
  bool _isLoadingResale = false;
  bool _isActionLoading = false;
  String? _actionError;

  List<Ticket> get myTickets => _myTickets;
  List<Ticket> get resaleTickets => _resaleTickets;
  bool get isLoadingMyTickets => _isLoadingMyTickets;
  bool get isLoadingResale => _isLoadingResale;
  bool get isActionLoading => _isActionLoading;
  String? get actionError => _actionError;

  Future<void> loadMyTickets(int customerId) async {
    _isLoadingMyTickets = true;
    notifyListeners();

    _myTickets = await _ticketService.getMyTickets(customerId: customerId);

    _isLoadingMyTickets = false;
    notifyListeners();
  }

  Future<void> loadResaleTickets() async {
    _isLoadingResale = true;
    notifyListeners();

    _resaleTickets = await _ticketService.getResaleTickets();

    _isLoadingResale = false;
    notifyListeners();
  }

  Future<bool> buyTicket({required int tripId, required int customerId}) async {
    _isActionLoading = true;
    _actionError = null;
    notifyListeners();

    final (ticket, error) = await _ticketService.buyTicket(
      tripId: tripId,
      customerId: customerId,
    );

    _isActionLoading = false;
    if (error != null) {
      _actionError = error;
      notifyListeners();
      return false;
    }

    if (ticket != null) {
      _myTickets.insert(0, ticket);
    }
    notifyListeners();
    return true;
  }

  Future<bool> resellTicket({
    required int ticketId,
    required double resalePrice,
    required int customerId,
  }) async {
    _isActionLoading = true;
    _actionError = null;
    notifyListeners();

    final (ticket, error) = await _ticketService.resellTicket(
      ticketId: ticketId,
      resalePrice: resalePrice,
      customerId: customerId,
    );

    _isActionLoading = false;
    if (error != null) {
      _actionError = error;
      notifyListeners();
      return false;
    }

    // Refresh tickets
    await loadMyTickets(customerId);
    await loadResaleTickets();
    return true;
  }

  Future<bool> purchaseResaleTicket({
    required int ticketId,
    required int customerId,
  }) async {
    _isActionLoading = true;
    _actionError = null;
    notifyListeners();

    final (ticket, error) = await _ticketService.purchaseResaleTicket(
      ticketId: ticketId,
      customerId: customerId,
    );

    _isActionLoading = false;
    if (error != null) {
      _actionError = error;
      notifyListeners();
      return false;
    }

    // Refresh tickets
    await loadMyTickets(customerId);
    await loadResaleTickets();
    return true;
  }
}
