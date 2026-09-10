import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../data/models/station_model.dart';
import '../../data/models/trip_model.dart';
import '../../data/models/enums.dart';
import '../../core/utils/price_utils.dart';

class TripSearchScreen extends StatefulWidget {
  const TripSearchScreen({super.key});

  @override
  State<TripSearchScreen> createState() => _TripSearchScreenState();
}

class _TripSearchScreenState extends State<TripSearchScreen> {
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load stations for the search form
      Provider.of<TripProvider>(context, listen: false).loadStations();
      // Pre-load the customer's tickets so Book buttons show correct state
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final customerId = authProvider.currentUser?.userId ?? 0;
      if (customerId > 0) {
        Provider.of<TicketProvider>(context, listen: false).loadMyTickets(customerId);
      }
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

    final fromCity = trip.startStation?.city ?? '';
    final toCity = trip.endStation?.city ?? '';
    final priceLabel = formatLouagePrice(fromCity, toCity,
        fromStation: trip.startStation?.name ?? '',
        toStation: trip.endStation?.name ?? '');

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
            Text(
              'Price: $priceLabel',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 4),
            Text(
              'Official tariff (A/C louage, Dec 2022)',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
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
      // Reload My Tickets so the new ticket appears immediately
      ticketProvider.loadMyTickets(customerId);
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
    final ticketProvider = Provider.of<TicketProvider>(context);

    // Build a set of tripIds the current customer already has an active ticket for
    final bookedTripIds = ticketProvider.myTickets
        .where((t) => t.status == TicketStatus.active)
        .map((t) => t.tripId)
        .toSet();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await tripProvider.loadStations();
          if (_hasSearched) await tripProvider.searchTrips();
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

                        // ── Departure: city then station ──────────
                        DropdownButtonFormField<String>(
                          initialValue: tripProvider.selectedStartCity,
                          decoration: const InputDecoration(
                            labelText: 'Departure City',
                            prefixIcon: Icon(Icons.location_city, color: Colors.blue),
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String>(value: null, child: Text('Any City')),
                            ...tripProvider.cities.map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            ),
                          ],
                          onChanged: (v) => tripProvider.setStartCity(v),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<Station>(
                          initialValue: tripProvider.selectedStartStation,
                          decoration: const InputDecoration(
                            labelText: 'Departure Station',
                            prefixIcon: Icon(Icons.trip_origin, color: Colors.blue),
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<Station>(value: null, child: Text('Any Station')),
                            ...tripProvider
                                .stationsForCity(tripProvider.selectedStartCity)
                                .map((s) => DropdownMenuItem(value: s, child: Text(s.name))),
                          ],
                          onChanged: (val) => tripProvider.setStartStation(val),
                        ),
                        const SizedBox(height: 12),

                        // ── Destination: city then station ────────
                        DropdownButtonFormField<String>(
                          initialValue: tripProvider.selectedEndCity,
                          decoration: const InputDecoration(
                            labelText: 'Destination City',
                            prefixIcon: Icon(Icons.location_city, color: Colors.red),
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String>(value: null, child: Text('Any City')),
                            ...tripProvider.cities.map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            ),
                          ],
                          onChanged: (v) => tripProvider.setEndCity(v),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<Station>(
                          initialValue: tripProvider.selectedEndStation,
                          decoration: const InputDecoration(
                            labelText: 'Destination Station',
                            prefixIcon: Icon(Icons.location_on, color: Colors.red),
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<Station>(value: null, child: Text('Any Station')),
                            ...tripProvider
                                .stationsForCity(tripProvider.selectedEndCity)
                                .map((s) => DropdownMenuItem(value: s, child: Text(s.name))),
                          ],
                          onChanged: (val) => tripProvider.setEndStation(val),
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
                                  setState(() => _hasSearched = true);
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
                                setState(() => _hasSearched = false);
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
            else if (!_hasSearched)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Select your departure and destination,\nthen tap Search.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
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
                        'No trips found.\nTry different stations or date.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
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
                                  Row(
                                    children: [
                                      // ── Price badge ──────────────────────────
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.blue.shade100),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.sell_outlined, size: 14, color: Colors.blue.shade700),
                                            const SizedBox(width: 4),
                                            Text(
                                              formatLouagePrice(
                                                trip.startStation?.city ?? '',
                                                trip.endStation?.city ?? '',
                                                fromStation: trip.startStation?.name ?? '',
                                                toStation: trip.endStation?.name ?? '',
                                              ),
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: bookedTripIds.contains(trip.id)
                                            ? null
                                            : () => _bookTicket(trip),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: bookedTripIds.contains(trip.id)
                                              ? Colors.grey.shade400
                                              : Colors.blue,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (bookedTripIds.contains(trip.id))
                                              const Icon(Icons.check_circle_outline, size: 16),
                                            if (bookedTripIds.contains(trip.id))
                                              const SizedBox(width: 4),
                                            Text(bookedTripIds.contains(trip.id) ? 'Booked' : 'Book'),
                                          ],
                                        ),
                                      ),
                                    ],
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
