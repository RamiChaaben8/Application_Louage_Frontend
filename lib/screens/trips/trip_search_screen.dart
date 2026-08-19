import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../data/models/station_model.dart';
import '../../data/models/trip_model.dart';

class TripSearchScreen extends StatefulWidget {
  const TripSearchScreen({super.key});

  @override
  State<TripSearchScreen> createState() => _TripSearchScreenState();
}

class _TripSearchScreenState extends State<TripSearchScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tripProvider = Provider.of<TripProvider>(context, listen: false);
      tripProvider.loadStations();
      tripProvider.searchTrips();
    });
  }

  void _bookTicket(Trip trip) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);

    final customerId = authProvider.currentUser?.userId ?? 0;
    if (customerId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in again.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: ${trip.startStation?.city ?? 'Departure'} (${trip.startStation?.name ?? ''})'),
            Text('To: ${trip.endStation?.city ?? 'Destination'} (${trip.endStation?.name ?? ''})'),
            const SizedBox(height: 8),
            Text('Departure: ${_formatDateTime(trip.departureTime)}'),
            const SizedBox(height: 8),
            const Text('Price: 50.00 TND', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm & Book'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final success = await ticketProvider.buyTicket(
      tripId: trip.id,
      customerId: customerId,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ticket booked successfully! Check My Tickets.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ticketProvider.actionError ?? 'Failed to book ticket.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = Provider.of<TripProvider>(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await tripProvider.loadStations();
          await tripProvider.searchTrips();
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Find Your Louage Trip',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        // Departure Station Dropdown
                        DropdownButtonFormField<Station>(
                          value: tripProvider.selectedStartStation,
                          decoration: const InputDecoration(
                            labelText: 'Departure Station',
                            prefixIcon: Icon(Icons.trip_origin, color: Colors.blue),
                            border: OutlineInputBorder(),
                          ),
                          items: tripProvider.stations.map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Text('${s.city} - ${s.name}'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            tripProvider.setStartStation(val);
                          },
                        ),
                        const SizedBox(height: 12),
                        // Destination Station Dropdown
                        DropdownButtonFormField<Station>(
                          value: tripProvider.selectedEndStation,
                          decoration: const InputDecoration(
                            labelText: 'Destination Station',
                            prefixIcon: Icon(Icons.location_on, color: Colors.red),
                            border: OutlineInputBorder(),
                          ),
                          items: tripProvider.stations.map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Text('${s.city} - ${s.name}'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            tripProvider.setEndStation(val);
                          },
                        ),
                        const SizedBox(height: 12),
                        // Date Picker
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: tripProvider.selectedDate ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(const Duration(days: 1)),
                              lastDate: DateTime.now().add(const Duration(days: 30)),
                            );
                            if (picked != null) {
                              tripProvider.setSelectedDate(picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Colors.blue),
                                const SizedBox(width: 12),
                                Text(
                                  tripProvider.selectedDate != null
                                      ? '${tripProvider.selectedDate!.year}-${tripProvider.selectedDate!.month.toString().padLeft(2, '0')}-${tripProvider.selectedDate!.day.toString().padLeft(2, '0')}'
                                      : 'Select Date (Optional)',
                                  style: TextStyle(
                                    color: tripProvider.selectedDate != null ? Colors.black87 : Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                                const Spacer(),
                                if (tripProvider.selectedDate != null)
                                  IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () => tripProvider.setSelectedDate(null),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                icon: const Icon(Icons.search),
                                label: const Text('Search Trips'),
                                onPressed: () {
                                  tripProvider.searchTrips();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () {
                                tripProvider.clearFilters();
                              },
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (tripProvider.isLoadingTrips)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (tripProvider.trips.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No trips found for selected criteria.',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final trip = tripProvider.trips[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          trip.startStation?.city ?? 'Departure',
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          trip.startStation?.name ?? '',
                                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Icon(Icons.arrow_forward, color: Colors.blue),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          trip.endStation?.city ?? 'Destination',
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          trip.endStation?.name ?? '',
                                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 18, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(
                                        _formatDateTime(trip.departureTime),
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _bookTicket(trip),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('Book'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: tripProvider.trips.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
