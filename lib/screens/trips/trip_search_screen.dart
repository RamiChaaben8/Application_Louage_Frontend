import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
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
      Provider.of<TripProvider>(context, listen: false).loadStations();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final customerId = authProvider.currentUser?.userId ?? 0;
      if (customerId > 0) {
        Provider.of<TicketProvider>(context, listen: false)
            .loadMyTickets(customerId);
      }
    });
  }

  void _bookTicket(Trip trip) async {
    final l = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final ticketProvider =
        Provider.of<TicketProvider>(context, listen: false);

    final customerId = authProvider.currentUser?.userId ?? 0;
    if (customerId == 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.loginAgain)));
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.confirmBooking),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RouteRow(
              from: '${trip.startStation?.city ?? l.departure} — ${trip.startStation?.name ?? ''}',
              to: '${trip.endStation?.city ?? l.to} — ${trip.endStation?.name ?? ''}',
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.access_time_outlined,
                    size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text(_formatDateTime(trip.departureTime)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.sell_outlined,
                    size: 16, color: AppTheme.primary),
                const SizedBox(width: 6),
                Text(
                  '$priceLabel TND',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(l.officialTariff,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.confirmAndBook),
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

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? l.ticketBooked
          : (ticketProvider.actionError ?? l.failedToBook)),
      backgroundColor: success ? AppTheme.success : AppTheme.danger,
    ));

    if (success) ticketProvider.loadMyTickets(customerId);
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tripProvider = Provider.of<TripProvider>(context);
    final ticketProvider = Provider.of<TicketProvider>(context);

    final bookedTripIds = ticketProvider.myTickets
        .where((t) => t.status == TicketStatus.active)
        .map((t) => t.tripId)
        .toSet();

    return RefreshIndicator(
      onRefresh: () async {
        await tripProvider.loadStations();
        if (_hasSearched) await tripProvider.searchTrips();
      },
      child: CustomScrollView(
        slivers: [
          // Search card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.search_rounded,
                              color: AppTheme.primary),
                          const SizedBox(width: 8),
                          Text(l.findYourLouage,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Departure
                      _buildCityDropdown(
                        context: context,
                        label: l.departureCity,
                        icon: Icons.trip_origin,
                        iconColor: AppTheme.primary,
                        value: tripProvider.selectedStartCity,
                        cities: tripProvider.cities,
                        anyLabel: l.anyCity,
                        onChanged: (v) => tripProvider.setStartCity(v),
                      ),
                      const SizedBox(height: 10),
                      _buildStationDropdown(
                        context: context,
                        label: l.departureStation,
                        icon: Icons.trip_origin,
                        iconColor: AppTheme.primary,
                        value: tripProvider.selectedStartStation,
                        stations: tripProvider
                            .stationsForCity(tripProvider.selectedStartCity),
                        anyLabel: l.anyStation,
                        onChanged: (v) => tripProvider.setStartStation(v),
                      ),
                      const SizedBox(height: 10),

                      // Route divider
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(Icons.south,
                                size: 18, color: AppTheme.textSecondary),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Destination
                      _buildCityDropdown(
                        context: context,
                        label: l.destinationCity,
                        icon: Icons.location_on_rounded,
                        iconColor: AppTheme.danger,
                        value: tripProvider.selectedEndCity,
                        cities: tripProvider.cities,
                        anyLabel: l.anyCity,
                        onChanged: (v) => tripProvider.setEndCity(v),
                      ),
                      const SizedBox(height: 10),
                      _buildStationDropdown(
                        context: context,
                        label: l.destinationStation,
                        icon: Icons.location_on_rounded,
                        iconColor: AppTheme.danger,
                        value: tripProvider.selectedEndStation,
                        stations: tripProvider
                            .stationsForCity(tripProvider.selectedEndCity),
                        anyLabel: l.anyStation,
                        onChanged: (v) => tripProvider.setEndStation(v),
                      ),
                      const SizedBox(height: 10),

                      // Date picker
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                                tripProvider.selectedDate ?? DateTime.now(),
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 1)),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 30)),
                          );
                          if (picked != null) {
                            tripProvider.setSelectedDate(picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  color: AppTheme.textSecondary, size: 18),
                              const SizedBox(width: 12),
                              Text(
                                tripProvider.selectedDate != null
                                    ? '${tripProvider.selectedDate!.year}-${tripProvider.selectedDate!.month.toString().padLeft(2, '0')}-${tripProvider.selectedDate!.day.toString().padLeft(2, '0')}'
                                    : l.selectDate,
                                style: TextStyle(
                                  color: tripProvider.selectedDate != null
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary,
                                  fontSize: 15,
                                ),
                              ),
                              const Spacer(),
                              if (tripProvider.selectedDate != null)
                                GestureDetector(
                                  onTap: () =>
                                      tripProvider.setSelectedDate(null),
                                  child: const Icon(Icons.clear,
                                      size: 18,
                                      color: AppTheme.textSecondary),
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
                              icon: const Icon(Icons.search_rounded, size: 18),
                              label: Text(l.searchTrips),
                              onPressed: () {
                                setState(() => _hasSearched = true);
                                tripProvider.searchTrips();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () {
                              setState(() => _hasSearched = false);
                              tripProvider.clearFilters();
                            },
                            child: Text(l.clear),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Results
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
                    Icon(Icons.directions_car_outlined,
                        size: 64,
                        color: AppTheme.divider),
                    const SizedBox(height: 16),
                    Text(
                      l.searchPrompt,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 15),
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
                    Icon(Icons.search_off_rounded,
                        size: 64, color: AppTheme.divider),
                    const SizedBox(height: 16),
                    Text(
                      l.noTripsFound,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 15),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final trip = tripProvider.trips[index];
                    final isBooked = bookedTripIds.contains(trip.id);
                    return _TripCard(
                      trip: trip,
                      isBooked: isBooked,
                      onBook: () => _bookTicket(trip),
                      formatDateTime: _formatDateTime,
                    );
                  },
                  childCount: tripProvider.trips.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCityDropdown({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color iconColor,
    required String? value,
    required List<String> cities,
    required String anyLabel,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: iconColor, size: 18),
      ),
      items: [
        DropdownMenuItem<String>(value: null, child: Text(anyLabel)),
        ...cities.map((c) => DropdownMenuItem(value: c, child: Text(c))),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildStationDropdown({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color iconColor,
    required Station? value,
    required List<Station> stations,
    required String anyLabel,
    required ValueChanged<Station?> onChanged,
  }) {
    return DropdownButtonFormField<Station>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: iconColor, size: 18),
      ),
      items: [
        DropdownMenuItem<Station>(value: null, child: Text(anyLabel)),
        ...stations
            .map((s) => DropdownMenuItem(value: s, child: Text(s.name))),
      ],
      onChanged: onChanged,
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;
  final bool isBooked;
  final VoidCallback onBook;
  final String Function(DateTime) formatDateTime;

  const _TripCard({
    required this.trip,
    required this.isBooked,
    required this.onBook,
    required this.formatDateTime,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final priceLabel = formatLouagePrice(
      trip.startStation?.city ?? '',
      trip.endStation?.city ?? '',
      fromStation: trip.startStation?.name ?? '',
      toStation: trip.endStation?.name ?? '',
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.startStation?.city ?? l.departure,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary),
                      ),
                      Text(
                        trip.startStation?.name ?? '',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_rounded,
                      color: AppTheme.primary, size: 18),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        trip.endStation?.city ?? l.to,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary),
                      ),
                      Text(
                        trip.endStation?.name ?? '',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Time + price + book
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 15, color: AppTheme.textSecondary),
                const SizedBox(width: 5),
                Text(
                  formatDateTime(trip.departureTime),
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.priceBadge,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.priceBadgeBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sell_outlined,
                          size: 13, color: AppTheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        '$priceLabel TND',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isBooked ? null : onBook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isBooked ? AppTheme.divider : AppTheme.primary,
                    foregroundColor:
                        isBooked ? AppTheme.textSecondary : Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isBooked)
                        const Icon(Icons.check_circle_outline, size: 14),
                      if (isBooked) const SizedBox(width: 4),
                      Text(
                        isBooked ? l.booked : l.book,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final String from;
  final String to;
  const _RouteRow({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.trip_origin, size: 14, color: AppTheme.primary),
          const SizedBox(width: 6),
          Expanded(
              child: Text('${l.from}: $from',
                  style: const TextStyle(fontSize: 13))),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.location_on_rounded,
              size: 14, color: AppTheme.danger),
          const SizedBox(width: 6),
          Expanded(
              child: Text('${l.to}: $to',
                  style: const TextStyle(fontSize: 13))),
        ]),
      ],
    );
  }
}
