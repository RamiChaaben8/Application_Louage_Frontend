import 'package:flutter/material.dart';
import '../data/models/ticket_model.dart';
import '../data/sources/ticket_service.dart';

class TicketProvider with ChangeNotifier {
  final TicketService _ticketService = TicketService();

  List<Ticket> _myTickets = [];
  bool _isLoadingMyTickets = false;
  bool _isActionLoading = false;
  String? _actionError;

  List<Ticket> get myTickets => _myTickets;
  bool get isLoadingMyTickets => _isLoadingMyTickets;
  bool get isActionLoading => _isActionLoading;
  String? get actionError => _actionError;

  Future<void> loadMyTickets(int customerId) async {
    _isLoadingMyTickets = true;
    notifyListeners();

    _myTickets = await _ticketService.getMyTickets(customerId: customerId);

    _isLoadingMyTickets = false;
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

  Future<bool> refundTicket({
    required int ticketId,
    required int customerId,
  }) async {
    _isActionLoading = true;
    _actionError = null;
    notifyListeners();

    final (ticket, error) = await _ticketService.refundTicket(
      ticketId: ticketId,
      customerId: customerId,
    );

    _isActionLoading = false;
    if (error != null) {
      _actionError = error;
      notifyListeners();
      return false;
    }

    // Update the ticket in the local list immediately
    if (ticket != null) {
      final idx = _myTickets.indexWhere((t) => t.id == ticket.id);
      if (idx != -1) _myTickets[idx] = ticket;
    }
    notifyListeners();
    return true;
  }
}
