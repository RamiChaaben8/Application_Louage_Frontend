import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../data/models/ticket_model.dart';
import '../../data/models/enums.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTickets());
  }

  void _loadTickets() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    final customerId = authProvider.currentUser?.userId ?? 0;
    if (customerId > 0) {
      ticketProvider.loadMyTickets(customerId);
    }
  }

  void _confirmRefund(Ticket ticket) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refund Ticket'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ticket #${ticket.id}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Price paid: ${ticket.price.toStringAsFixed(2)} TND'),
            const SizedBox(height: 12),
            const Text(
              'Are you sure you want to refund this ticket? This cannot be undone.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              final ticketProvider =
                  Provider.of<TicketProvider>(context, listen: false);
              final customerId = authProvider.currentUser?.userId ?? 0;

              Navigator.pop(ctx);

              final success = await ticketProvider.refundTicket(
                ticketId: ticket.id,
                customerId: customerId,
              );

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(success
                    ? 'Ticket refunded successfully.'
                    : (ticketProvider.actionError ?? 'Refund failed.')),
                backgroundColor: success ? Colors.green : Colors.red,
              ));
            },
            child: const Text('Confirm Refund'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.active:
        return Colors.green;
      case TicketStatus.refunded:
        return Colors.orange;
      case TicketStatus.used:
        return Colors.grey;
      case TicketStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketProvider = Provider.of<TicketProvider>(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _loadTickets(),
        child: ticketProvider.isLoadingMyTickets
            ? const Center(child: CircularProgressIndicator())
            : ticketProvider.myTickets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.confirmation_number_outlined,
                            size: 70, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'You have no tickets yet.',
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: ticketProvider.myTickets.length,
                    itemBuilder: (context, index) {
                      final ticket = ticketProvider.myTickets[index];
                      final color = _statusColor(ticket.status);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Ticket #${ticket.id}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: color),
                                    ),
                                    child: Text(
                                      ticket.status.name.toUpperCase(),
                                      style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text('Date: ${ticket.date.isNotEmpty ? ticket.date : "N/A"}'),
                                  const Spacer(),
                                  const Icon(Icons.access_time,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text('Time: ${ticket.time.isNotEmpty ? ticket.time : "N/A"}'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Price: ${ticket.price.toStringAsFixed(2)} TND',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue),
                                  ),
                                  if (ticket.status == TicketStatus.active)
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.undo, size: 16),
                                      label: const Text('Refund'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red.shade700,
                                        side: BorderSide(
                                            color: Colors.red.shade700),
                                      ),
                                      onPressed: () => _confirmRefund(ticket),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
