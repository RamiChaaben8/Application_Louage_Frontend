import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/ticket_model.dart';

class TicketService {
  // Buy a ticket for a trip
  Future<(Ticket?, String?)> buyTicket({
    required int tripId,
    required int customerId,
  }) async {
    try {
      final url = '${ApiConstants.ticketsEndpoint}/buy?customerId=$customerId';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tripId': tripId}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return (Ticket.fromJson(jsonDecode(response.body)), null);
      }
      return (null, _extractError(response.body, response.statusCode));
    } catch (e) {
      return (null, 'Error purchasing ticket: $e');
    }
  }

  // Get customer's tickets
  Future<List<Ticket>> getMyTickets({required int customerId}) async {
    try {
      final url = '${ApiConstants.ticketsEndpoint}/my-tickets?customerId=$customerId';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Ticket.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Request a refund on an active ticket
  Future<(Ticket?, String?)> refundTicket({
    required int ticketId,
    required int customerId,
  }) async {
    try {
      final url =
          '${ApiConstants.ticketsEndpoint}/$ticketId/refund?customerId=$customerId';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return (Ticket.fromJson(jsonDecode(response.body)), null);
      }
      return (null, _extractError(response.body, response.statusCode));
    } catch (e) {
      return (null, 'Error requesting refund: $e');
    }
  }

  String _extractError(String body, int statusCode) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is String) return decoded;
      if (decoded is Map && decoded.containsKey('message')) return decoded['message'];
      if (decoded is Map && decoded.containsKey('title')) return decoded['title'];
      return body.isNotEmpty ? body : 'Server error ($statusCode)';
    } catch (_) {
      return body.isNotEmpty ? body : 'Server error ($statusCode)';
    }
  }
}
