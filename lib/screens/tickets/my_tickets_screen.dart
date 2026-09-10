import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
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
    if (customerId > 0) ticketProvider.loadMyTickets(customerId);
  }

  void _confirmRefund(Ticket ticket) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.refundTicket),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l.ticket} #${ticket.id}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${l.pricePaid}: ${ticket.price.toStringAsFixed(2)} TND'),
            const SizedBox(height: 12),
            Text(l.refundConfirmMsg,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger),
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
                    ? l.ticketRefunded
                    : (ticketProvider.actionError ?? l.refundFailed)),
                backgroundColor:
                    success ? AppTheme.success : AppTheme.danger,
              ));
            },
            child: Text(l.confirmRefund),
          ),
        ],
      ),
    );
  }

  Color _statusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.active:
        return AppTheme.success;
      case TicketStatus.refunded:
        return AppTheme.warning;
      case TicketStatus.used:
        return AppTheme.textSecondary;
      case TicketStatus.cancelled:
        return AppTheme.danger;
    }
  }

  String _statusLabel(TicketStatus status, AppLocalizations l) {
    switch (status) {
      case TicketStatus.active:
        return l.statusActive;
      case TicketStatus.refunded:
        return l.statusRefunded;
      case TicketStatus.used:
        return l.statusUsed;
      case TicketStatus.cancelled:
        return l.statusCancelled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ticketProvider = Provider.of<TicketProvider>(context);

    return RefreshIndicator(
      onRefresh: () async => _loadTickets(),
      child: ticketProvider.isLoadingMyTickets
          ? const Center(child: CircularProgressIndicator())
          : ticketProvider.myTickets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.confirmation_number_outlined,
                          size: 72,
                          color: AppTheme.divider),
                      const SizedBox(height: 16),
                      Text(
                        l.noTickets,
                        style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondary),
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
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header row
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary
                                            .withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                          Icons.confirmation_number_rounded,
                                          size: 16,
                                          color: AppTheme.primary),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '${l.ticket} #${ticket.id}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        color.withValues(alpha: 0.12),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    border: Border.all(color: color),
                                  ),
                                  child: Text(
                                    _statusLabel(ticket.status, l),
                                    style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),

                            // Date / Time
                            Row(
                              children: [
                                _InfoChip(
                                  icon: Icons.calendar_today_outlined,
                                  label:
                                      '${l.date}: ${ticket.date.isNotEmpty ? ticket.date : 'N/A'}',
                                ),
                                const SizedBox(width: 16),
                                _InfoChip(
                                  icon: Icons.access_time_outlined,
                                  label:
                                      '${l.time}: ${ticket.time.isNotEmpty ? ticket.time : 'N/A'}',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Price + refund
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${ticket.price.toStringAsFixed(2)} TND',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary),
                                ),
                                if (ticket.status ==
                                    TicketStatus.active)
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.undo_rounded,
                                        size: 16),
                                    label: Text(l.refund),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.danger,
                                      side: const BorderSide(
                                          color: AppTheme.danger),
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8),
                                    ),
                                    onPressed: () =>
                                        _confirmRefund(ticket),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textSecondary)),
      ],
    );
  }
}
