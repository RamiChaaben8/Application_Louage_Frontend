import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import '../../providers/trip_provider.dart';
import '../../data/models/enums.dart';
import '../auth/login_screen.dart';

const _kPrimary = Color(0xFF1A3A6B);
const _kAccent  = Color(0xFF2979FF);
const _kSurface = Color(0xFFF4F6FB);

class DriverMainScreen extends StatefulWidget {
  const DriverMainScreen({super.key});
  @override
  State<DriverMainScreen> createState() => _DriverMainScreenState();
}

class _DriverMainScreenState extends State<DriverMainScreen> {
  int _selectedTripTab = 0; // 0 = Active/Scheduled, 1 = Completed History

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkStatus());
  }

  void _checkStatus() {
    final auth   = Provider.of<AuthProvider>(context, listen: false);
    final driver = Provider.of<DriverProvider>(context, listen: false);
    final trips  = Provider.of<TripProvider>(context, listen: false);
    final id = auth.currentUser?.userId ?? 0;
    if (id > 0) {
      driver.checkDriverStatus(
        id,
        fallbackStatus: auth.currentUser?.status,
        onStatusUpdated: (s) => auth.updateUserStatus(s),
      );
      trips.loadStations();
      trips.searchTrips();
    }
  }

  void _logout() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await auth.logout();
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  AppBar _appBar() => AppBar(
    backgroundColor: _kPrimary,
    foregroundColor: Colors.white,
    elevation: 0,
    title: Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.drive_eta_rounded, size: 20, color: Colors.white),
      ),
      const SizedBox(width: 10),
      const Text('Driver Portal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
    ]),
    actions: [
      IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _checkStatus),
      IconButton(icon: const Icon(Icons.logout_rounded), onPressed: _logout),
      const SizedBox(width: 4),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final auth   = Provider.of<AuthProvider>(context);
    final driver = Provider.of<DriverProvider>(context);
    final user   = auth.currentUser;
    final isApproved = driver.isApproved || driver.isUserApproved(user);
    final isDeclined = driver.isDeclined && !isApproved;

    return Scaffold(
      backgroundColor: _kSurface,
      appBar: _appBar(),
      body: (driver.isLoading && driver.driverStatus == null && user?.status == null)
          ? const Center(child: CircularProgressIndicator())
          : isDeclined
              ? _buildDeclinedView(user)
              : isApproved
                  ? _buildActiveDashboard(driver, user)
                  : _buildPendingView(user),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VIEW 1 – Pending
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPendingView(dynamic user) {
    return _scrollable([
      _banner(
        icon: Icons.hourglass_top_rounded,
        iconBg: Colors.amber.shade100,
        iconColor: Colors.amber.shade800,
        grad: [const Color(0xFF7B4F00), const Color(0xFFF59E0B)],
        title: 'Awaiting Verification',
        sub: 'Your application is under review',
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(children: [
          _card([
            _detailRow(Icons.person_outline, 'Driver Name', '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim()),
            _kDivider,
            _detailRow(Icons.email_outlined, 'Email', user?.email ?? 'N/A'),
            _kDivider,
            _detailRow(Icons.badge_outlined, 'Driver ID', '#${user?.userId ?? ''}'),
          ]),
          const SizedBox(height: 16),
          _notice(
            Icons.info_outline_rounded,
            _kAccent,
            'Your registration has been submitted. The station administrator is reviewing your license. Once approved, your dashboard will unlock automatically.',
          ),
          const SizedBox(height: 24),
          _primaryBtn(Icons.refresh_rounded, 'Check Verification Status', _checkStatus),
        ]),
      ),
    ]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VIEW 2 – Declined
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDeclinedView(dynamic user) {
    return _scrollable([
      _banner(
        icon: Icons.cancel_outlined,
        iconBg: Colors.red.shade100,
        iconColor: Colors.red.shade700,
        grad: [const Color(0xFF7F1D1D), const Color(0xFFEF4444)],
        title: 'Application Declined',
        sub: 'Your registration was not approved',
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(children: [
          _notice(
            Icons.error_outline_rounded,
            Colors.red.shade600,
            'Your driver registration application was declined. Please contact your local station administrator for details.',
          ),
          const SizedBox(height: 24),
          _primaryBtn(Icons.refresh_rounded, 'Re-check Status', _checkStatus, color: Colors.red.shade700),
        ]),
      ),
    ]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VIEW 3 – Active Dashboard
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildActiveDashboard(DriverProvider dp, dynamic user) {
    final vehicle = dp.assignedVehicle;
    final tp = Provider.of<TripProvider>(context);
    return _scrollable([
      _welcomeHeader(user),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionLabel('Assigned Vehicle', Icons.directions_car_rounded),
          const SizedBox(height: 12),
          if (vehicle != null) ...[
            _vehicleCard(vehicle, dp),
            const SizedBox(height: 28),
          ] else ...[
            _notice(Icons.directions_car_outlined, Colors.orange.shade700, 'No vehicle assigned yet. The administrator will assign one to your account.'),
            const SizedBox(height: 28),
          ],
          // ── Trips Section with Tabs (Active / Completed) ──
          _buildTripsSection(tp, dp, user),
        ]),
      ),
    ]);
  }

  Widget _buildTripsSection(TripProvider tp, DriverProvider dp, dynamic user) {
    final activeTrips = tp.trips.where((t) => t.status != TripStatus.finished).toList();
    final finishedTrips = tp.trips.where((t) => t.status == TripStatus.finished).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionLabel('Trips Schedule', Icons.route_rounded),
            FilledButton.icon(
              onPressed: () => _createTripDialog(tp, user?.userId),
              icon: const Icon(Icons.add_rounded, size: 17),
              label: const Text('New Trip', style: TextStyle(fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                backgroundColor: _kAccent,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Filter Tabs
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTripTab = 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedTripTab == 0 ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: _selectedTripTab == 0
                          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))]
                          : [],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_bus_rounded, size: 16, color: _selectedTripTab == 0 ? _kAccent : Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Text(
                          'Active (${activeTrips.length})',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _selectedTripTab == 0 ? FontWeight.w700 : FontWeight.w500,
                            color: _selectedTripTab == 0 ? _kAccent : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTripTab = 1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedTripTab == 1 ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: _selectedTripTab == 1
                          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))]
                          : [],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 16, color: _selectedTripTab == 1 ? Colors.green.shade700 : Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Text(
                          'Completed (${finishedTrips.length})',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _selectedTripTab == 1 ? FontWeight.w700 : FontWeight.w500,
                            color: _selectedTripTab == 1 ? Colors.green.shade700 : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (tp.isLoadingTrips)
          const Padding(padding: EdgeInsets.symmetric(vertical: 48), child: Center(child: CircularProgressIndicator()))
        else if (_selectedTripTab == 0)
          _buildTripsList(activeTrips, tp, dp, user, emptyMessage: 'No active or upcoming trips scheduled.')
        else
          _buildTripsList(finishedTrips, tp, dp, user, emptyMessage: 'No completed trips yet.', isCompletedTab: true),
      ],
    );
  }

  Widget _buildTripsList(List<dynamic> trips, TripProvider tp, DriverProvider dp, dynamic user, {required String emptyMessage, bool isCompletedTab = false}) {
    if (trips.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(isCompletedTab ? Icons.assignment_turned_in_outlined : Icons.route_outlined, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 10),
              Text(emptyMessage, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: trips.length,
      itemBuilder: (ctx, i) {
        final trip = trips[i];
        final mine = trip.driverId == user?.userId;
        Color sc; IconData si; String sl;
        switch (trip.status) {
          case TripStatus.started:  sc = _kAccent;             si = Icons.play_circle_fill_rounded; sl = 'Ongoing';  break;
          case TripStatus.finished: sc = Colors.green.shade600; si = Icons.check_circle_rounded;     sl = 'Finished'; break;
          default:                  sc = Colors.orange.shade600; si = Icons.schedule_rounded;        sl = 'Pending';
        }
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: mine ? Border.all(color: _kAccent.withValues(alpha: 0.4), width: 1.5) : null,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: isCompletedTab ? Colors.green.shade50 : (mine ? const Color(0xFFEFF6FF) : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCompletedTab ? Icons.check_circle_rounded : Icons.route_rounded,
                  color: isCompletedTab ? Colors.green.shade600 : (mine ? _kAccent : Colors.grey.shade500),
                  size: 22,
                ),
              ),
              title: Text('${trip.startStation?.city ?? ''} \u2192 ${trip.endStation?.city ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      '${trip.departureTime.hour.toString().padLeft(2, '0')}:${trip.departureTime.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (mine)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(6)),
                      child: const Text('MY TRIP', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: sc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(si, color: sc, size: 11),
                        const SizedBox(width: 3),
                        Text(sl, style: TextStyle(color: sc, fontSize: 10, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: _kSurface, borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.people_alt_outlined, size: 15, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text('Passengers (${trip.passengerNames.length})', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey.shade700)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (trip.passengerNames.isEmpty)
                        Text('No tickets sold yet.', style: TextStyle(color: Colors.grey.shade400, fontStyle: FontStyle.italic, fontSize: 13))
                      else
                        ...trip.passengerNames.map((n) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(color: Colors.blueGrey.shade50, shape: BoxShape.circle), child: Icon(Icons.person_outline_rounded, size: 14, color: Colors.blueGrey.shade400)),
                              const SizedBox(width: 8),
                              Text(n, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        )),
                      if (mine) ...[
                        const SizedBox(height: 14),
                        const Divider(height: 1, color: Color(0x14000000)),
                        const SizedBox(height: 14),
                        if (trip.status == TripStatus.pending)
                          _actionBtn(Icons.play_arrow_rounded, 'Start Trip', _kAccent, () => _confirmStart(tp, dp, trip.id)),
                        if (trip.status == TripStatus.started)
                          _actionBtn(Icons.flag_rounded, 'Finish Trip', Colors.green.shade600, () => _confirmFinish(tp, dp, trip.id)),
                        if (trip.status == TripStatus.finished)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 18),
                                const SizedBox(width: 8),
                                Text('Trip Completed', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Welcome header ───────────────────────────────────────────────────────
  Widget _welcomeHeader(dynamic user) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [_kPrimary, Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    ),
    padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
    child: Row(children: [
      Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
        ),
        child: const Icon(Icons.person_rounded, size: 34, color: Colors.white),
      ),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Hello, ${user?.firstName ?? 'Driver'}! 👋',
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.verified_rounded, color: Color(0xFF4ADE80), size: 14),
            SizedBox(width: 5),
            Text('VERIFIED  ·  ACTIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
          ]),
        ),
      ])),
    ]),
  );

  // ─── Status banner ─────────────────────────────────────────────────────────
  Widget _banner({required IconData icon, required Color iconBg, required Color iconColor, required List<Color> grad, required String title, required String sub}) =>
    Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight)),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 44),
      child: Column(children: [
        Container(width: 88, height: 88, decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle), child: Icon(icon, size: 46, color: iconColor)),
        const SizedBox(height: 18),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(sub, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
      ]),
    );

  // ─── Vehicle card ─────────────────────────────────────────────────────────
  Widget _vehicleCard(dynamic vehicle, DriverProvider dp) {
    final sc = _statusColor(vehicle.status);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 16), child: Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(14)), child: Icon(Icons.directions_car_rounded, color: _kAccent, size: 28)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Plate Number', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
            Text(vehicle.plate, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 2)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: sc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(30), border: Border.all(color: sc.withValues(alpha: 0.5))),
            child: Text(_statusLabel(vehicle.status), style: TextStyle(color: sc, fontWeight: FontWeight.w700, fontSize: 11)),
          ),
        ])),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: _kSurface, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Expanded(child: _vehicleStat(Icons.airline_seat_recline_normal_rounded, 'Capacity', '${vehicle.capacity} Seats')),
            Container(width: 1, height: 36, color: Colors.black12),
            Expanded(child: _vehicleStat(Icons.confirmation_number_outlined, 'Vehicle ID', '#${vehicle.id}')),
          ]),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Update Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            if (dp.isUpdatingStatus) ...[
              const SizedBox(width: 8),
              const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _statusBtn(Icons.check_circle_outline_rounded, 'Available', vehicle.status == VehicleStatus.available, Colors.green.shade600, () async {
              final ok = await dp.setVehicleStatus(VehicleStatus.available);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'Vehicle status updated to Available' : 'Failed to update vehicle status'),
                  duration: const Duration(seconds: 2),
                ));
              }
            }),
            const SizedBox(width: 8),
            _statusBtn(Icons.directions_car_rounded, 'In Trip', vehicle.status == VehicleStatus.inUse, _kAccent, () async {
              final ok = await dp.setVehicleStatus(VehicleStatus.inUse);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'Vehicle status updated to In Trip' : 'Failed to update vehicle status'),
                  duration: const Duration(seconds: 2),
                ));
              }
            }),
            const SizedBox(width: 8),
            _statusBtn(Icons.build_circle_outlined, 'Service', vehicle.status == VehicleStatus.maintenance, Colors.orange.shade600, () async {
              final ok = await dp.setVehicleStatus(VehicleStatus.maintenance);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'Vehicle status updated to Service/Maintenance' : 'Failed to update vehicle status'),
                  duration: const Duration(seconds: 2),
                ));
              }
            }),
          ]),
        ])),
      ]),
    );
  }

  void _confirmStart(TripProvider tp, DriverProvider dp, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Start Trip', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to start this trip now? Your vehicle status will change to In Trip.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await tp.updateTripStatus(id, TripStatus.started);
              if (!mounted) return;
              if (ok) {
                if (dp.assignedVehicle != null) {
                  await dp.setVehicleStatus(VehicleStatus.inUse);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Trip started! Vehicle status updated to In Trip.'),
                      backgroundColor: _kPrimary,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(tp.error ?? 'Failed to start trip'),
                    backgroundColor: Colors.red.shade600,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: _kAccent),
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _confirmFinish(TripProvider tp, DriverProvider dp, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Finish Trip', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to finish this trip? Your vehicle status will change to Available.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await tp.updateTripStatus(id, TripStatus.finished);
              if (!mounted) return;
              if (ok) {
                if (dp.assignedVehicle != null) {
                  await dp.setVehicleStatus(VehicleStatus.available);
                }
                if (mounted) {
                  setState(() => _selectedTripTab = 1);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Trip marked as finished! Vehicle status updated to Available.'),
                      backgroundColor: Colors.green.shade600,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(tp.error ?? 'Failed to finish trip'),
                    backgroundColor: Colors.red.shade600,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.green.shade600),
            child: const Text('Finish Trip'),
          ),
        ],
      ),
    );
  }

  void _createTripDialog(TripProvider tp, int? driverId) {
    int? ss; int? es; TimeOfDay t = TimeOfDay.now();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, ss2) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('New Trip', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<int>(
              decoration: InputDecoration(labelText: 'Start Station', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.location_on_outlined)),
              initialValue: ss, items: tp.stations.map((s) => DropdownMenuItem(value: s.id, child: Text(s.city))).toList(), onChanged: (v) => ss2(() => ss = v),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              decoration: InputDecoration(labelText: 'End Station', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.flag_outlined)),
              initialValue: es, items: tp.stations.map((s) => DropdownMenuItem(value: s.id, child: Text(s.city))).toList(), onChanged: (v) => ss2(() => es = v),
            ),
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final nt = await showTimePicker(context: ctx2, initialTime: t);
                if (nt != null) ss2(() => t = nt);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Icon(Icons.access_time_rounded, color: Colors.grey.shade600),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Departure Time', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    Text('${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ]),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                ]),
              ),
            ),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(ctx);
                if (ss == null || es == null) { messenger.showSnackBar(const SnackBar(content: Text('Please select both stations'))); return; }
                if (ss == es) { messenger.showSnackBar(const SnackBar(content: Text('Stations must differ'))); return; }
                final now = DateTime.now();
                final ok = await tp.createTrip(
                  startStationId: ss!, endStationId: es!,
                  departureTime: DateTime(now.year, now.month, now.day, t.hour, t.minute),
                  driverId: driverId,
                );
                if (!mounted) return;
                if (ok) {
                  navigator.pop();
                  messenger.showSnackBar(const SnackBar(content: Text('Trip created successfully!')));
                } else {
                  messenger.showSnackBar(const SnackBar(content: Text('Failed to create trip')));
                }
              },
              style: FilledButton.styleFrom(backgroundColor: _kAccent),
              child: const Text('Create Trip'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Small helpers ────────────────────────────────────────────────────────
  Color _statusColor(VehicleStatus s) {
    switch (s) {
      case VehicleStatus.available:    return Colors.green.shade600;
      case VehicleStatus.inUse:        return _kAccent;
      case VehicleStatus.maintenance:  return Colors.orange.shade600;
      case VehicleStatus.outOfService: return Colors.red.shade600;
    }
  }

  String _statusLabel(dynamic s) {
    if (s == null) return 'UNKNOWN';
    if (s is VehicleStatus) {
      switch (s) {
        case VehicleStatus.available:    return 'AVAILABLE';
        case VehicleStatus.inUse:        return 'IN TRIP';
        case VehicleStatus.maintenance:  return 'SERVICE / MAINTENANCE';
        case VehicleStatus.outOfService: return 'OUT OF SERVICE';
      }
    }
    return s.toString().split('.').last.toUpperCase();
  }

  Widget _scrollable(List<Widget> children) => RefreshIndicator(
    onRefresh: () async => _checkStatus(),
    child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
  );

  Widget _sectionLabel(String label, IconData icon) => Row(children: [
    Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: _kAccent)),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
  ]);

  Widget _card(List<Widget> children) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))]),
    padding: const EdgeInsets.all(20), child: Column(children: children),
  );

  Widget _detailRow(IconData icon, String label, String value) => Row(children: [
    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: _kAccent, size: 18)),
    const SizedBox(width: 14),
    Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
    const Spacer(),
    Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
  ]);

  Widget _notice(IconData icon, Color color, String text) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.25))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 20), const SizedBox(width: 12),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5))),
    ]),
  );

  Widget _primaryBtn(IconData icon, String label, VoidCallback cb, {Color color = _kAccent}) => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: cb, icon: Icon(icon, size: 18), label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      style: FilledButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    ),
  );

  Widget _vehicleStat(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(children: [
      Icon(icon, size: 18, color: _kAccent), const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      ]),
    ]),
  );

  Widget _statusBtn(IconData icon, String label, bool sel, Color color, VoidCallback cb) => Expanded(
    child: InkWell(
      onTap: cb, borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: sel ? color : Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sel ? color : Colors.grey.shade300, width: sel ? 0 : 1.5),
          boxShadow: sel ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))] : [],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: sel ? Colors.white : Colors.grey.shade500, size: 22),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(color: sel ? Colors.white : Colors.grey.shade600, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, fontSize: 11)),
        ]),
      ),
    ),
  );

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback cb) => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: cb, icon: Icon(icon, size: 18), label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      style: FilledButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
    ),
  );
}

const _kDivider = Padding(
  padding: EdgeInsets.symmetric(vertical: 12),
  child: Divider(height: 1, color: Color(0x14000000)),
);
