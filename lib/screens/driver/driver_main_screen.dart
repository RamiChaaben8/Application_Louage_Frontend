import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/trip_provider.dart';
import '../../data/models/enums.dart';
import '../auth/login_screen.dart';

class DriverMainScreen extends StatefulWidget {
  const DriverMainScreen({super.key});

  @override
  State<DriverMainScreen> createState() => _DriverMainScreenState();
}

class _DriverMainScreenState extends State<DriverMainScreen> {
  int _selectedTripTab = 0;
  bool _hasPromptedStationSelection = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkStatus());
  }

  void _checkStatus() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final driver = Provider.of<DriverProvider>(context, listen: false);
    final trips = Provider.of<TripProvider>(context, listen: false);
    final id = auth.currentUser?.userId ?? 0;
    if (id > 0) {
      await driver.checkDriverStatus(
        id,
        fallbackStatus: auth.currentUser?.status,
        onStatusUpdated: (s) => auth.updateUserStatus(s),
      );
      await trips.loadStations();
      await trips.loadDriverTrips(id);

      if (mounted &&
          (driver.isApproved || driver.isUserApproved(auth.currentUser))) {
        if (driver.currentStation == null && !_hasPromptedStationSelection) {
          _hasPromptedStationSelection = true;
          _showSelectStationDialog(driver, trips, id, isInitial: true);
        }
      }
    }
  }

  void _showSelectStationDialog(DriverProvider dp, TripProvider tp, int driverId, {bool isInitial = false}) {
    final l = AppLocalizations.of(context);
    final availableStations =
        dp.driverStations.isNotEmpty ? dp.driverStations : tp.stations;
    int? selectedId = dp.currentStation?.id ??
        (availableStations.isNotEmpty ? availableStations.first.id : null);

    showDialog(
      context: context,
      barrierDismissible: !isInitial,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setState2) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.location_on_rounded,
                  color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isInitial ? l.setCurrentStation : l.currentStation,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              isInitial
                  ? 'Please select your current station:'
                  : 'Select your new station:',
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            if (availableStations.isEmpty)
              const Text('No stations available.')
            else
              DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: l.stations,
                  prefixIcon: const Icon(Icons.pin_drop_rounded),
                ),
                initialValue: selectedId,
                items: availableStations
                    .map((s) => DropdownMenuItem(
                        value: s.id, child: Text('${s.city} (${s.name})')))
                    .toList(),
                onChanged: (v) => setState2(() => selectedId = v),
              ),
          ]),
          actions: [
            if (!isInitial)
              TextButton(
                  onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
            ElevatedButton(
              onPressed: selectedId == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      final ok = await dp.updateCurrentStation(driverId, selectedId!);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(ok
                            ? '${l.currentStation}: ${dp.currentStation?.city ?? ''}'
                            : 'Failed to update station'),
                        backgroundColor: ok ? AppTheme.success : AppTheme.danger,
                      ));
                    },
              child: Text(l.confirm),
            ),
          ],
        ),
      ),
    );
  }

  void _logout() async {
    final l = AppLocalizations.of(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.logoutConfirmTitle),
        content: Text(l.logoutConfirmMsg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.logout),
          ),
        ],
      ),
    );
    if (ok == true) {
      await auth.logout();
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  void _showLanguagePicker() {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(l.language,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 8),
            ...LocaleProvider.options.map((opt) => ListTile(
                  leading: Text(opt.flag, style: const TextStyle(fontSize: 24)),
                  title: Text(opt.label),
                  trailing: localeProvider.locale == opt.locale
                      ? const Icon(Icons.check_circle, color: AppTheme.primary)
                      : null,
                  onTap: () {
                    localeProvider.setLocale(opt.locale);
                    Navigator.pop(ctx);
                  },
                )),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final auth = Provider.of<AuthProvider>(context);
    final driver = Provider.of<DriverProvider>(context);
    final user = auth.currentUser;
    final isApproved = driver.isApproved || driver.isUserApproved(user);
    final isDeclined = driver.isDeclined && !isApproved;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.drive_eta_rounded, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(l.driverDashboard,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        actions: [
          IconButton(
              icon: const Icon(Icons.language_outlined),
              onPressed: _showLanguagePicker),
          IconButton(
              icon: const Icon(Icons.refresh_rounded), onPressed: _checkStatus),
          IconButton(
              icon: const Icon(Icons.logout_rounded), onPressed: _logout),
        ],
      ),
      body: (driver.isLoading &&
              driver.driverStatus == null &&
              user?.status == null)
          ? const Center(child: CircularProgressIndicator())
          : isDeclined
              ? _buildDeclinedView(user, l)
              : isApproved
                  ? _buildActiveDashboard(driver, user, l)
                  : _buildPendingView(user, l),
    );
  }

  // ── PENDING VIEW ──────────────────────────────────────────────────────────
  Widget _buildPendingView(dynamic user, AppLocalizations l) {
    return _scrollable([
      _banner(
        icon: Icons.hourglass_top_rounded,
        iconBg: Colors.amber.shade100,
        iconColor: Colors.amber.shade800,
        gradColors: [const Color(0xFF7B4F00), const Color(0xFFF59E0B)],
        title: l.pendingApproval,
        sub: l.pendingApprovalMsg,
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(children: [
          _card([
            _detailRow(Icons.person_outline_rounded, l.firstName,
                '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim()),
            _kDivider,
            _detailRow(Icons.email_outlined, l.email, user?.email ?? 'N/A'),
            _kDivider,
            _detailRow(Icons.badge_outlined, 'ID', '#${user?.userId ?? ''}'),
          ]),
          const SizedBox(height: 16),
          _notice(Icons.info_outline_rounded, AppTheme.primary, l.pendingApprovalMsg),
          const SizedBox(height: 24),
          _primaryBtn(Icons.refresh_rounded, l.retry, AppTheme.primary, _checkStatus),
        ]),
      ),
    ]);
  }

  // ── DECLINED VIEW ─────────────────────────────────────────────────────────
  Widget _buildDeclinedView(dynamic user, AppLocalizations l) {
    return _scrollable([
      _banner(
        icon: Icons.cancel_outlined,
        iconBg: Colors.red.shade100,
        iconColor: Colors.red.shade700,
        gradColors: [const Color(0xFF7F1D1D), const Color(0xFFEF4444)],
        title: 'Application Declined',
        sub: 'Your registration was not approved',
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(children: [
          _notice(Icons.error_outline_rounded, AppTheme.danger,
              'Your driver registration application was declined. Please contact your local station administrator.'),
          const SizedBox(height: 24),
          _primaryBtn(Icons.refresh_rounded, l.retry, AppTheme.danger, _checkStatus),
        ]),
      ),
    ]);
  }

  // ── ACTIVE DASHBOARD ──────────────────────────────────────────────────────
  Widget _buildActiveDashboard(DriverProvider dp, dynamic user, AppLocalizations l) {
    final vehicle = dp.assignedVehicle;
    final tp = Provider.of<TripProvider>(context);
    return _scrollable([
      _welcomeHeader(user),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionLabel(l.currentStation, Icons.location_on_rounded),
          const SizedBox(height: 12),
          _currentStationCard(dp, tp, user, l),
          const SizedBox(height: 24),
          _sectionLabel('Vehicle', Icons.directions_car_rounded),
          const SizedBox(height: 12),
          if (vehicle != null) ...[
            _vehicleCard(vehicle, dp, l),
            const SizedBox(height: 28),
          ] else ...[
            _notice(Icons.directions_car_outlined, AppTheme.warning,
                'No vehicle assigned yet. The administrator will assign one to your account.'),
            const SizedBox(height: 28),
          ],
          _buildTripsSection(tp, dp, user, l),
        ]),
      ),
    ]);
  }

  Widget _buildTripsSection(TripProvider tp, DriverProvider dp, dynamic user, AppLocalizations l) {
    final driverId = user?.userId;
    final driverTrips = tp.trips.where((t) => t.driverId == driverId).toList();
    final activeTrips =
        driverTrips.where((t) => t.status != TripStatus.finished).toList();
    final finishedTrips =
        driverTrips.where((t) => t.status == TripStatus.finished).toList();
    final isInActiveTrip = activeTrips.any(
        (t) => t.status == TripStatus.pending || t.status == TripStatus.started);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _sectionLabel(l.myTrips, Icons.route_rounded),
        if (!isInActiveTrip)
          ElevatedButton.icon(
            onPressed: () => _createTripDialog(tp, dp, user?.userId),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text(l.createTrip,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.block_rounded, size: 13, color: AppTheme.warning),
              const SizedBox(width: 5),
              Text('Trip in progress',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.warning)),
            ]),
          ),
      ]),
      if (isInActiveTrip) ...[
        const SizedBox(height: 8),
        _notice(Icons.info_outline_rounded, AppTheme.warning,
            'You have an active trip. Finish it before creating a new one.'),
      ],
      const SizedBox(height: 12),

      // Tab selector
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: AppTheme.divider, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          _tripTab(0, Icons.directions_bus_rounded,
              'Active (${activeTrips.length})', activeTrips.length, AppTheme.primary),
          _tripTab(1, Icons.check_circle_outline_rounded,
              'Done (${finishedTrips.length})', finishedTrips.length, AppTheme.success),
        ]),
      ),
      const SizedBox(height: 12),

      if (tp.isLoadingTrips)
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()))
      else if (_selectedTripTab == 0)
        _buildTripsList(activeTrips, tp, dp, user, l,
            emptyMessage: 'No active or upcoming trips scheduled.')
      else
        _buildTripsList(finishedTrips, tp, dp, user, l,
            emptyMessage: 'No completed trips yet.', isCompletedTab: true),
    ]);
  }

  Widget _tripTab(int index, IconData icon, String label, int count, Color activeColor) {
    final sel = _selectedTripTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTripTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: sel
                ? [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2))]
                : [],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon,
                size: 15,
                color: sel ? activeColor : AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    color: sel ? activeColor : AppTheme.textSecondary)),
          ]),
        ),
      ),
    );
  }

  Widget _buildTripsList(List<dynamic> trips, TripProvider tp, DriverProvider dp,
      dynamic user, AppLocalizations l,
      {required String emptyMessage, bool isCompletedTab = false}) {
    if (trips.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Center(
          child: Column(children: [
            Icon(
              isCompletedTab
                  ? Icons.assignment_turned_in_outlined
                  : Icons.route_outlined,
              size: 48,
              color: AppTheme.divider,
            ),
            const SizedBox(height: 10),
            Text(emptyMessage,
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ]),
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
        Color sc;
        IconData si;
        String sl;
        switch (trip.status) {
          case TripStatus.started:
            sc = AppTheme.primary;
            si = Icons.play_circle_fill_rounded;
            sl = 'Ongoing';
            break;
          case TripStatus.finished:
            sc = AppTheme.success;
            si = Icons.check_circle_rounded;
            sl = 'Finished';
            break;
          default:
            sc = AppTheme.warning;
            si = Icons.schedule_rounded;
            sl = 'Pending';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: mine
                ? Border.all(color: AppTheme.primary.withValues(alpha: 0.4), width: 1.5)
                : Border.all(color: AppTheme.divider),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCompletedTab
                      ? AppTheme.success.withValues(alpha: 0.1)
                      : (mine
                          ? AppTheme.primary.withValues(alpha: 0.1)
                          : AppTheme.surface),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCompletedTab
                      ? Icons.check_circle_rounded
                      : Icons.route_rounded,
                  color: isCompletedTab
                      ? AppTheme.success
                      : (mine ? AppTheme.primary : AppTheme.textSecondary),
                  size: 20,
                ),
              ),
              title: Text(
                '${trip.startStation?.city ?? ''} → ${trip.endStation?.city ?? ''}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.access_time_rounded,
                        size: 12, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${trip.departureTime.hour.toString().padLeft(2, '0')}:${trip.departureTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ]),
                  const SizedBox(height: 5),
                  Row(children: [
                    _smallBadge(
                        '${dp.assignedVehicle != null ? (dp.assignedVehicle!.capacity - trip.passengerNames.length).clamp(0, 999) : '?'} seats left',
                        AppTheme.primary),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: sc.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(si, color: sc, size: 11),
                        const SizedBox(width: 3),
                        Text(sl,
                            style: TextStyle(
                                color: sc,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ]),
                ]),
              ),
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.people_alt_outlined,
                          size: 15, color: AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                          '${l.passengers} (${trip.passengerNames.length})',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppTheme.textSecondary)),
                    ]),
                    const SizedBox(height: 10),
                    if (trip.passengerNames.isEmpty)
                      Text(l.noPassengers,
                          style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontStyle: FontStyle.italic,
                              fontSize: 13))
                    else
                      ...trip.passengerNames.map((n) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(children: [
                              Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(alpha: 0.08),
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.person_outline_rounded,
                                      size: 13, color: AppTheme.primary)),
                              const SizedBox(width: 8),
                              Text(n, style: const TextStyle(fontSize: 13)),
                            ]),
                          )),
                    if (mine) ...[
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 14),
                      if (trip.status == TripStatus.pending)
                        _actionBtn(Icons.play_arrow_rounded, 'Start Trip',
                            AppTheme.primary, () => _confirmStart(tp, dp, trip.id)),
                      if (trip.status == TripStatus.started)
                        _actionBtn(Icons.flag_rounded, 'Finish Trip',
                            AppTheme.success, () => _confirmFinish(tp, dp, trip, user)),
                      if (trip.status == TripStatus.finished)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppTheme.success.withValues(alpha: 0.3))),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.check_circle_rounded,
                                color: AppTheme.success, size: 18),
                            const SizedBox(width: 8),
                            Text('Trip Completed',
                                style: const TextStyle(
                                    color: AppTheme.success,
                                    fontWeight: FontWeight.w700)),
                          ]),
                        ),
                    ],
                  ]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Welcome header ────────────────────────────────────────────────────────
  Widget _welcomeHeader(dynamic user) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [AppTheme.primary, AppTheme.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Row(children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.35), width: 2),
          ),
          child: const Icon(Icons.person_rounded, size: 32, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hello, ${user?.firstName ?? 'Driver'}! 👋',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.verified_rounded, color: Color(0xFF4ADE80), size: 14),
                SizedBox(width: 5),
                Text('VERIFIED  ·  ACTIVE',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8)),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _banner(
      {required IconData icon,
      required Color iconBg,
      required Color iconColor,
      required List<Color> gradColors,
      required String title,
      required String sub}) {
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: gradColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight)),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 44),
      child: Column(children: [
        Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 46, color: iconColor)),
        const SizedBox(height: 18),
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(sub,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
      ]),
    );
  }

  Widget _currentStationCard(DriverProvider dp, TripProvider tp, dynamic user, AppLocalizations l) {
    final station = dp.currentStation;
    final driverId = user?.userId ?? 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: station != null
                ? AppTheme.primary.withValues(alpha: 0.1)
                : AppTheme.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.location_on_rounded,
              color: station != null ? AppTheme.primary : AppTheme.warning,
              size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.currentStation,
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text(
              station != null
                  ? '${station.city} (${station.name})'
                  : 'Not Selected',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: station != null
                      ? AppTheme.textPrimary
                      : AppTheme.warning),
            ),
          ]),
        ),
        ElevatedButton.icon(
          onPressed: () =>
              _showSelectStationDialog(dp, tp, driverId),
          icon: Icon(
              station != null
                  ? Icons.edit_location_alt_rounded
                  : Icons.add_location_alt_rounded,
              size: 16),
          label: Text(station != null ? 'Change' : 'Select',
              style: const TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              foregroundColor: AppTheme.primary,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
        ),
      ]),
    );
  }

  Widget _vehicleCard(dynamic vehicle, DriverProvider dp, AppLocalizations l) {
    final sc = _statusColor(vehicle.status);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(children: [
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.directions_car_rounded,
                    color: AppTheme.primary, size: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Plate',
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                Text(vehicle.plate,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: sc.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sc.withValues(alpha: 0.4))),
              child: Text(_statusLabel(vehicle.status),
                  style: TextStyle(
                      color: sc,
                      fontWeight: FontWeight.w700,
                      fontSize: 11)),
            ),
          ]),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Expanded(
                child: _vehicleStat(Icons.event_seat_outlined, l.capacity,
                    '${vehicle.capacity} seats')),
            Container(width: 1, height: 32, color: AppTheme.divider),
            Expanded(
                child: _vehicleStat(
                    Icons.confirmation_number_outlined, 'ID', '#${vehicle.id}')),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(l.updateStatus,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
              if (dp.isUpdatingStatus) ...[
                const SizedBox(width: 8),
                const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _statusBtn(Icons.check_circle_outline_rounded, 'Available',
                  vehicle.status == VehicleStatus.available, AppTheme.success, () async {
                await dp.setVehicleStatus(VehicleStatus.available);
              }),
              const SizedBox(width: 8),
              _statusBtn(Icons.directions_car_rounded, 'In Trip',
                  vehicle.status == VehicleStatus.inUse, AppTheme.primary, () async {
                await dp.setVehicleStatus(VehicleStatus.inUse);
              }),
              const SizedBox(width: 8),
              _statusBtn(Icons.build_circle_outlined, 'Service',
                  vehicle.status == VehicleStatus.maintenance, AppTheme.warning,
                  () async {
                await dp.setVehicleStatus(VehicleStatus.maintenance);
              }),
            ]),
          ]),
        ),
      ]),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────
  void _confirmStart(TripProvider tp, DriverProvider dp, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Start Trip', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Start this trip now? Vehicle status will change to In Trip.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context).cancel)),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await tp.updateTripStatus(id, TripStatus.started);
              if (!mounted) return;
              if (ok && dp.assignedVehicle != null) {
                await dp.setVehicleStatus(VehicleStatus.inUse);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'Trip started!' : (tp.error ?? 'Failed')),
                  backgroundColor: ok ? AppTheme.success : AppTheme.danger,
                ));
              }
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _confirmFinish(TripProvider tp, DriverProvider dp, dynamic trip, dynamic user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Finish Trip', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Finish this trip? Your station will update to the arrival station.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context).cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await tp.updateTripStatus(trip.id, TripStatus.finished);
              if (!mounted) return;
              if (ok) {
                if (dp.assignedVehicle != null) {
                  await dp.setVehicleStatus(VehicleStatus.available);
                }
                final driverId = user?.userId ?? 0;
                if (driverId > 0) {
                  await dp.checkDriverStatus(driverId);
                  await tp.loadDriverTrips(driverId);
                }
                if (!mounted) return;
                setState(() => _selectedTripTab = 1);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      'Trip completed! Location updated to ${trip.endStation?.city ?? 'destination'}.'),
                  backgroundColor: AppTheme.success,
                ));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(tp.error ?? 'Failed to finish trip'),
                  backgroundColor: AppTheme.danger,
                ));
              }
            },
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }

  void _createTripDialog(TripProvider tp, DriverProvider dp, int? driverId) {
    final l = AppLocalizations.of(context);
    final availableStations =
        dp.driverStations.isNotEmpty ? dp.driverStations : tp.stations;
    int? ss = dp.currentStation?.id;
    int? es;
    TimeOfDay t = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, ss2) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l.createTrip,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: l.startStation,
                  prefixIcon: const Icon(Icons.trip_origin),
                ),
                initialValue: ss,
                items: availableStations
                    .map((s) => DropdownMenuItem(
                        value: s.id, child: Text(s.city)))
                    .toList(),
                onChanged: (v) => ss2(() => ss = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: l.endStation,
                  prefixIcon: const Icon(Icons.location_on_rounded),
                ),
                initialValue: es,
                items: availableStations
                    .map((s) => DropdownMenuItem(
                        value: s.id, child: Text(s.city)))
                    .toList(),
                onChanged: (v) => ss2(() => es = v),
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final nt = await showTimePicker(context: ctx2, initialTime: t);
                  if (nt != null) ss2(() => t = nt);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.divider),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.access_time_rounded, color: AppTheme.textSecondary),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l.departureTime,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                      Text(
                          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                    ]),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppTheme.textSecondary),
                  ]),
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(ctx);
                if (ss == null || es == null) {
                  messenger.showSnackBar(
                      const SnackBar(content: Text('Select both stations')));
                  return;
                }
                if (ss == es) {
                  messenger.showSnackBar(
                      const SnackBar(content: Text('Stations must differ')));
                  return;
                }
                final now = DateTime.now();
                final ok = await tp.createTrip(
                  startStationId: ss!,
                  endStationId: es!,
                  departureTime:
                      DateTime(now.year, now.month, now.day, t.hour, t.minute),
                  driverId: driverId,
                );
                if (!mounted) return;
                if (ok) {
                  navigator.pop();
                  messenger.showSnackBar(
                      const SnackBar(content: Text('Trip created!')));
                } else {
                  messenger.showSnackBar(
                      const SnackBar(content: Text('Failed to create trip')));
                }
              },
              child: Text(l.save),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Color _statusColor(VehicleStatus s) {
    switch (s) {
      case VehicleStatus.available:
        return AppTheme.success;
      case VehicleStatus.inUse:
        return AppTheme.primary;
      case VehicleStatus.maintenance:
        return AppTheme.warning;
      case VehicleStatus.outOfService:
        return AppTheme.danger;
    }
  }

  String _statusLabel(dynamic s) {
    if (s == null) return 'UNKNOWN';
    if (s is VehicleStatus) {
      switch (s) {
        case VehicleStatus.available:
          return 'AVAILABLE';
        case VehicleStatus.inUse:
          return 'IN TRIP';
        case VehicleStatus.maintenance:
          return 'SERVICE';
        case VehicleStatus.outOfService:
          return 'OUT OF SERVICE';
      }
    }
    return s.toString().split('.').last.toUpperCase();
  }

  Widget _scrollable(List<Widget> children) => RefreshIndicator(
        onRefresh: () async => _checkStatus(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      );

  Widget _sectionLabel(String label, IconData icon) => Row(children: [
        Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: AppTheme.primary)),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
      ]);

  Widget _card(List<Widget> children) => Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider)),
        padding: const EdgeInsets.all(20),
        child: Column(children: children),
      );

  Widget _detailRow(IconData icon, String label, String value) =>
      Row(children: [
        Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: AppTheme.primary, size: 16)),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      ]);

  Widget _notice(IconData icon, Color color, String text) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textPrimary, height: 1.5))),
        ]),
      );

  Widget _primaryBtn(IconData icon, String label, Color color, VoidCallback cb) =>
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: cb,
          icon: Icon(icon, size: 18),
          label: Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 15)),
          style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
      );

  Widget _vehicleStat(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
        ]),
      );

  Widget _statusBtn(IconData icon, String label, bool sel, Color color, VoidCallback cb) =>
      Expanded(
        child: InkWell(
          onTap: cb,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: sel ? color : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: sel ? color : AppTheme.divider,
                  width: sel ? 0 : 1.5),
              boxShadow: sel
                  ? [BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3))]
                  : [],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon,
                  color: sel ? Colors.white : AppTheme.textSecondary, size: 20),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      color: sel ? Colors.white : AppTheme.textSecondary,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 10)),
            ]),
          ),
        ),
      );

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback cb) =>
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: cb,
          icon: Icon(icon, size: 18),
          label: Text(label,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 0),
        ),
      );

  Widget _smallBadge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6)),
        child: Text(text,
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      );
}

const _kDivider = Padding(
  padding: EdgeInsets.symmetric(vertical: 10),
  child: Divider(height: 1, color: AppTheme.divider),
);
