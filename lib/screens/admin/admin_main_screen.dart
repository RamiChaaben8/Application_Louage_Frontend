import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/station_picker.dart';
import '../../core/utils/price_utils.dart';
import '../auth/login_screen.dart';
import '../../data/models/admin_user_model.dart';
import '../../data/models/station_model.dart';
import '../../data/models/trip_model.dart';
import '../../data/models/enums.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;
  String _userSearchQuery = '';
  String _userRoleFilter = 'All';
  bool _showTripHistory = false;
  int? _filterStartStationId;
  int? _filterEndStationId;
  String? _filterStationCity;
  String? _filterStartCity;
  String? _filterEndCity;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  String get _token =>
      context.read<AuthProvider>().currentUser?.token ?? '';

  void _loadData() {
    final ap = context.read<AdminProvider>();
    switch (_currentIndex) {
      case 0:
        ap.fetchUsers(_token);
        break;
      case 1:
        ap.fetchPendingDrivers(_token);
        break;
      case 2:
        ap.fetchStations();
        break;
      case 3:
        ap.fetchTrips();
        ap.fetchVehicles();
        ap.fetchStations();
        break;
    }
  }

  void _logout() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.logoutConfirmTitle),
        content: Text(l.logoutConfirmMsg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel)),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.logout),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  void _showLanguagePicker() {
    final localeProvider =
        Provider.of<LocaleProvider>(context, listen: false);
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(l.language,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 8),
              ...LocaleProvider.options.map((opt) => ListTile(
                    leading: Text(opt.flag,
                        style: const TextStyle(fontSize: 24)),
                    title: Text(opt.label),
                    trailing: localeProvider.locale == opt.locale
                        ? const Icon(Icons.check_circle,
                            color: AppTheme.primary)
                        : null,
                    onTap: () {
                      localeProvider.setLocale(opt.locale);
                      Navigator.pop(ctx);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.adminDashboard),
        actions: [
          IconButton(
              icon: const Icon(Icons.language_outlined),
              onPressed: _showLanguagePicker),
          IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadData),
          IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: _logout),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, ap, _) {
          if (ap.isLoading && ap.error == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (ap.error != null &&
              (ap.users.isEmpty &&
                  ap.pendingDrivers.isEmpty &&
                  ap.stations.isEmpty &&
                  ap.trips.isEmpty)) {
            return _buildErrorState(ap.error!);
          }
          switch (_currentIndex) {
            case 0:
              return _buildUsersTab(ap);
            case 1:
              return _buildApprovalsTab(ap);
            case 2:
              return _buildStationsTab(ap);
            case 3:
              return _buildTripsTab(ap);
            default:
              return const SizedBox.shrink();
          }
        },
      ),
      floatingActionButton: _buildFab(),
      bottomNavigationBar: Container(
        decoration:
            const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.divider))),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) {
            setState(() => _currentIndex = i);
            _loadData();
          },
          destinations: [
            NavigationDestination(
                icon: const Icon(Icons.people_outline_rounded),
                selectedIcon: const Icon(Icons.people_rounded),
                label: AppLocalizations.of(context).users),
            NavigationDestination(
                icon: const Icon(Icons.verified_user_outlined),
                selectedIcon: const Icon(Icons.verified_user_rounded),
                label: AppLocalizations.of(context).approvals),
            NavigationDestination(
                icon: const Icon(Icons.location_on_outlined),
                selectedIcon: const Icon(Icons.location_on_rounded),
                label: AppLocalizations.of(context).stations),
            NavigationDestination(
                icon: const Icon(Icons.route_outlined),
                selectedIcon: const Icon(Icons.route_rounded),
                label: AppLocalizations.of(context).trips),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline_rounded,
              size: 64, color: AppTheme.danger),
          const SizedBox(height: 16),
          Text(error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.danger, fontSize: 15)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l.retry),
            onPressed: _loadData,
          ),
        ]),
      ),
    );
  }

  Widget? _buildFab() {
    final l = AppLocalizations.of(context);
    switch (_currentIndex) {
      case 0:
        return FloatingActionButton.extended(
          onPressed: _showAddUserSheet,
          backgroundColor: AppTheme.primary,
          icon: const Icon(Icons.person_add_rounded, color: Colors.white),
          label: Text(l.add,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        );
      case 2:
        return FloatingActionButton.extended(
          onPressed: _showCreateStationDialog,
          backgroundColor: AppTheme.primary,
          icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
          label: Text(l.createStation,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        );
      case 3:
        return FloatingActionButton.extended(
          onPressed: _showCreateTripDialog,
          backgroundColor: AppTheme.primary,
          icon: const Icon(Icons.add_road_rounded, color: Colors.white),
          label: Text(l.createTrip,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        );
      default:
        return null;
    }
  }

  // ── USERS TAB ─────────────────────────────────────────────────────────────
  Widget _buildUsersTab(AdminProvider ap) {
    final l = AppLocalizations.of(context);
    var filtered = ap.users.where((u) {
      final matchesSearch =
          '${u.firstName} ${u.lastName} ${u.email}'.toLowerCase().contains(_userSearchQuery.toLowerCase());
      final matchesRole = _userRoleFilter == 'All' ||
          u.userType.toLowerCase() == _userRoleFilter.toLowerCase();
      return matchesSearch && matchesRole;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '${l.users}...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _userSearchQuery = v),
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _userRoleFilter,
                underline: const SizedBox(),
                borderRadius: BorderRadius.circular(12),
                items: ['All', 'Customer', 'Driver', 'Admin']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _userRoleFilter = v);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text(l.noUsers, style: const TextStyle(color: AppTheme.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    final (color, icon) = _userChipStyle(user.userType);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.12),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        title: Text('${user.firstName} ${user.lastName}',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(user.email,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: color.withValues(alpha: 0.3)),
                              ),
                              child: Text(user.userType,
                                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
                              onPressed: () => _confirmDeleteUser(user),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  (Color, IconData) _userChipStyle(String type) {
    switch (type.toLowerCase()) {
      case 'admin':
        return (Colors.purple, Icons.admin_panel_settings_rounded);
      case 'driver':
        return (Colors.orange, Icons.directions_car_rounded);
      default:
        return (AppTheme.primary, Icons.person_rounded);
    }
  }

  void _showAddUserSheet() {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
              Text(l.add,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.purple.withValues(alpha: 0.06),
                leading: const CircleAvatar(
                    backgroundColor: Colors.purple,
                    child: Icon(Icons.admin_panel_settings_rounded, color: Colors.white)),
                title: Text('Admin', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(l.adminDashboard),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCreateAdminDialog();
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.green.withValues(alpha: 0.06),
                leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.directions_car_rounded, color: Colors.white)),
                title: Text(l.driver, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(l.driverNotice),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCreateDriverDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateAdminDialog() {
    final l = AppLocalizations.of(context);
    final fnCtrl = TextEditingController();
    final lnCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.createAdmin),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                  controller: fnCtrl,
                  decoration: InputDecoration(labelText: l.firstName),
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 10),
              TextFormField(
                  controller: lnCtrl,
                  decoration: InputDecoration(labelText: l.lastName),
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 10),
              TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(labelText: l.email),
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 10),
              TextFormField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: InputDecoration(labelText: l.password),
                  validator: (v) => v!.length < 6 ? 'Min 6 chars' : null),
            ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                await context.read<AdminProvider>().createAdmin(
                      token: _token,
                      firstName: fnCtrl.text.trim(),
                      lastName: lnCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      password: passCtrl.text.trim(),
                    );
              }
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(AdminUser user) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.deleteUser),
        content: Text('${l.deleteUserConfirm}\n\n${user.firstName} ${user.lastName}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AdminProvider>().deleteUser(user.id, _token);
            },
            child: Text(l.delete),
          ),
        ],
      ),
    );
  }

  // ── APPROVALS TAB ─────────────────────────────────────────────────────────
  Widget _buildApprovalsTab(AdminProvider ap) {
    final l = AppLocalizations.of(context);
    final drivers = ap.pendingDrivers;

    if (drivers.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.check_circle_outline_rounded,
              size: 64, color: AppTheme.success),
          const SizedBox(height: 16),
          Text(l.noPendingDrivers,
              style: const TextStyle(
                  fontSize: 15, color: AppTheme.textSecondary)),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: drivers.length,
      itemBuilder: (context, index) {
        final driver = drivers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showDriverDetailDialog(driver),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.warning.withValues(alpha: 0.12),
                    child: const Icon(Icons.person_rounded, color: AppTheme.warning),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${driver.firstName} ${driver.lastName}',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(driver.email,
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary)),
                        if (driver.licenseNumber != null &&
                            driver.licenseNumber!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              '${l.licenseNumber}: ${driver.licenseNumber}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDriverDetailDialog(AdminUser driver) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.warning,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person_rounded,
                      size: 32, color: AppTheme.warning),
                ),
                const SizedBox(height: 10),
                Text('${driver.firstName} ${driver.lastName}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
                Text(driver.email,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(Icons.badge_outlined, l.licenseNumber,
                      driver.licenseNumber ?? 'N/A'),
                  const SizedBox(height: 12),
                  if (driver.vehicle != null) ...[
                    _infoRow(Icons.pin_outlined, l.plate,
                        driver.vehicle!.plate),
                    _infoRow(Icons.event_seat_outlined, l.capacity,
                        '${driver.vehicle!.capacity}'),
                  ] else
                    Text('No vehicle',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ]),
        ),
        actions: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.danger,
                side: const BorderSide(color: AppTheme.danger)),
            onPressed: () {
              Navigator.pop(ctx);
              _declineDriver(driver.id);
            },
            icon: const Icon(Icons.close_rounded, size: 16),
            label: Text(l.decline),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success),
            onPressed: () {
              Navigator.pop(ctx);
              _approveDriver(driver.id);
            },
            icon: const Icon(Icons.check_rounded, size: 16),
            label: Text(l.approve),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13)),
        Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13))),
      ]),
    );
  }

  void _approveDriver(int id) async {
    await context.read<AdminProvider>().approveDriver(id, _token);
  }

  void _declineDriver(int id) async {
    await context.read<AdminProvider>().declineDriver(id, _token);
  }

  void _showCreateDriverDialog() async {
    final adminProvider = context.read<AdminProvider>();
    if (adminProvider.stations.isEmpty) {
      await adminProvider.fetchStations();
    }
    if (!mounted) return;
    final allStations = adminProvider.stations;
    final l = AppLocalizations.of(context);

    final fnCtrl = TextEditingController();
    final lnCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final licenseCtrl = TextEditingController();
    final plateCtrl = TextEditingController();
    final capacityCtrl = TextEditingController(text: '7');
    final formKey = GlobalKey<FormState>();
    List<int> selectedStationIds = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModal) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l.createDriver),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Expanded(
                        child: TextFormField(
                            controller: fnCtrl,
                            decoration:
                                InputDecoration(labelText: l.firstName),
                            validator: (v) => v!.isEmpty ? 'Required' : null)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: TextFormField(
                            controller: lnCtrl,
                            decoration: InputDecoration(labelText: l.lastName),
                            validator: (v) => v!.isEmpty ? 'Required' : null)),
                  ]),
                  const SizedBox(height: 10),
                  TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(labelText: l.email),
                      validator: (v) => v!.isEmpty ? 'Required' : null),
                  const SizedBox(height: 10),
                  TextFormField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: InputDecoration(labelText: l.password),
                      validator: (v) => (v == null || v.length < 6) ? 'Min 6' : null),
                  const SizedBox(height: 10),
                  TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(labelText: l.phoneNumber),
                      validator: (v) => v!.isEmpty ? 'Required' : null),
                  const Divider(height: 24),
                  TextFormField(
                      controller: licenseCtrl,
                      decoration: InputDecoration(labelText: l.licenseNumber),
                      validator: (v) => v!.isEmpty ? 'Required' : null),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                        child: TextFormField(
                            controller: plateCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(labelText: l.plate),
                            validator: (v) => v!.isEmpty ? 'Required' : null)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: TextFormField(
                            controller: capacityCtrl,
                            keyboardType: TextInputType.number,
                            decoration:
                                InputDecoration(labelText: l.capacity),
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              return (n == null || n < 2) ? 'Min 2' : null;
                            })),
                  ]),
                  const Divider(height: 24),
                  Text(l.destinations,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  StationPicker(
                    stations: allStations,
                    selectedIds: selectedStationIds,
                    onChanged: () => setModal(() {}),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                if (selectedStationIds.length < 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.selectMin2Stations)));
                  return;
                }
                Navigator.pop(ctx);
                await context.read<AdminProvider>().createDriver(
                      token: _token,
                      firstName: fnCtrl.text.trim(),
                      lastName: lnCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      password: passCtrl.text.trim(),
                      phoneNum: int.tryParse(phoneCtrl.text.trim()) ?? 0,
                      licenseNumber: licenseCtrl.text.trim(),
                      plate: plateCtrl.text.trim(),
                      capacity: int.tryParse(capacityCtrl.text.trim()) ?? 7,
                      stationIds: selectedStationIds,
                    );
              },
              child: Text(l.save),
            ),
          ],
        ),
      ),
    );
  }

  // ── STATIONS TAB ──────────────────────────────────────────────────────────
  Widget _buildStationsTab(AdminProvider ap) {
    final l = AppLocalizations.of(context);
    final allStations = ap.stations;
    final cities =
        allStations.map((s) => s.city).toSet().toList()..sort();
    final stations = _filterStationCity == null
        ? allStations
        : allStations
            .where((s) => s.city == _filterStationCity)
            .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: l.city,
              prefixIcon: const Icon(Icons.location_city_outlined),
            ),
            initialValue: _filterStationCity,
            items: [
              DropdownMenuItem<String>(value: null, child: Text(l.anyCity)),
              ...cities.map((c) => DropdownMenuItem(value: c, child: Text(c))),
            ],
            onChanged: (v) => setState(() => _filterStationCity = v),
          ),
        ),
        Expanded(
          child: stations.isEmpty
              ? Center(
                  child: Text(l.noStations,
                      style: const TextStyle(color: AppTheme.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: stations.length,
                  itemBuilder: (context, index) {
                    final station = stations[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.location_city_rounded,
                              color: AppTheme.primary),
                        ),
                        title: Text(station.name,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(station.city),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: AppTheme.danger),
                          onPressed: () =>
                              _confirmDeleteStation(station),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showCreateStationDialog() {
    final l = AppLocalizations.of(context);
    final nameCtrl = TextEditingController();
    String? selectedCity;
    final formKey = GlobalKey<FormState>();
    final cities = context
        .read<AdminProvider>()
        .stations
        .map((s) => s.city)
        .toSet()
        .toList()
      ..sort();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModal) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l.createStation),
          content: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: l.city),
                initialValue: selectedCity,
                items: cities
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setModal(() => selectedCity = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: l.stationName),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx);
                  await context.read<AdminProvider>().createStation(
                      token: _token,
                      name: nameCtrl.text.trim(),
                      city: selectedCity!);
                }
              },
              child: Text(l.save),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteStation(Station station) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.delete),
        content: Text('${station.name} — ${station.city}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await context
                  .read<AdminProvider>()
                  .deleteStation(station.id, _token);
            },
            child: Text(l.delete),
          ),
        ],
      ),
    );
  }

  // ── TRIPS TAB ─────────────────────────────────────────────────────────────
  Widget _buildTripsTab(AdminProvider ap) {
    final l = AppLocalizations.of(context);
    var trips = List<Trip>.from(ap.trips);

    if (!_showTripHistory) {
      trips = trips.where((t) => t.status == TripStatus.pending).toList();
    }
    if (_filterStartStationId != null) {
      trips = trips.where((t) => t.startStationId == _filterStartStationId).toList();
    }
    if (_filterEndStationId != null) {
      trips = trips.where((t) => t.endStationId == _filterEndStationId).toList();
    }
    trips.sort((a, b) => a.departureTime.compareTo(b.departureTime));

    final allStations = ap.stations;
    final cities = allStations.map((s) => s.city).toSet().toList()..sort();
    final startStations = _filterStartCity == null
        ? allStations
        : allStations.where((s) => s.city == _filterStartCity).toList();
    final endStations = _filterEndCity == null
        ? allStations
        : allStations.where((s) => s.city == _filterEndCity).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(children: [
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: l.departureCity,
                    isDense: true,
                  ),
                  initialValue: _filterStartCity,
                  items: [
                    DropdownMenuItem<String>(value: null, child: Text(l.anyCity)),
                    ...cities.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                  ],
                  onChanged: (v) => setState(() {
                    _filterStartCity = v;
                    _filterStartStationId = null;
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: l.departureStation,
                    isDense: true,
                  ),
                  initialValue: _filterStartStationId,
                  items: [
                    const DropdownMenuItem<int>(value: null, child: Text('Any')),
                    ...startStations.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                  ],
                  onChanged: (v) => setState(() => _filterStartStationId = v),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: l.destinationCity,
                    isDense: true,
                  ),
                  initialValue: _filterEndCity,
                  items: [
                    DropdownMenuItem<String>(value: null, child: Text(l.anyCity)),
                    ...cities.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                  ],
                  onChanged: (v) => setState(() {
                    _filterEndCity = v;
                    _filterEndStationId = null;
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: l.destinationStation,
                    isDense: true,
                  ),
                  initialValue: _filterEndStationId,
                  items: [
                    const DropdownMenuItem<int>(value: null, child: Text('Any')),
                    ...endStations.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                  ],
                  onChanged: (v) => setState(() => _filterEndStationId = v),
                ),
              ),
            ]),
          ]),
        ),
        SwitchListTile(
          title: Text(l.status,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text('Show all trips history'),
          value: _showTripHistory,
          activeTrackColor: AppTheme.primary,
          onChanged: (v) => setState(() => _showTripHistory = v),
        ),
        Expanded(
          child: trips.isEmpty
              ? Center(child: Text(l.noTrips,
                  style: const TextStyle(color: AppTheme.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    final start = trip.startStation?.name ?? '#${trip.startStationId}';
                    final end = trip.endStation?.name ?? '#${trip.endStationId}';
                    final driverStr = trip.driverName?.isNotEmpty == true
                        ? trip.driverName!
                        : 'Unknown';
                    String matricul = 'No Vehicle';
                    int cap = 0;
                    if (trip.driverId != null) {
                      try {
                        final v = ap.vehicles
                            .firstWhere((v) => v.driverId == trip.driverId);
                        matricul = v.plate;
                        cap = v.capacity;
                      } catch (_) {}
                    }
                    final grasLabel = '$driverStr — $matricul';
                    final booked = trip.passengerNames.length;
                    final avail = cap > 0 ? cap - booked : 0;
                    final timeStr =
                        '${trip.departureTime.day}/${trip.departureTime.month} ${trip.departureTime.hour.toString().padLeft(2, '0')}:${trip.departureTime.minute.toString().padLeft(2, '0')}';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.route_rounded,
                              color: AppTheme.primary),
                        ),
                        title: Text('$start → $end',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(grasLabel,
                                style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 4),
                            Row(children: [
                              _badge(
                                  formatLouagePrice(
                                      trip.startStation?.city ?? '',
                                      trip.endStation?.city ?? '',
                                      fromStation:
                                          trip.startStation?.name ?? '',
                                      toStation:
                                          trip.endStation?.name ?? ''),
                                  AppTheme.success),
                              const SizedBox(width: 6),
                              _badge(
                                  cap > 0 ? '$avail/$cap' : 'No Vehicle',
                                  AppTheme.primary),
                              const SizedBox(width: 6),
                              _badge(timeStr, AppTheme.textSecondary),
                            ]),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _tripStatusIcon(trip.status),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: AppTheme.danger),
                              onPressed: () => _confirmDeleteTrip(trip),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(children: [
                              if (trip.status == TripStatus.pending) ...[
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primary),
                                    onPressed: () =>
                                        _confirmStartTrip(trip),
                                    child: const Text('Start'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.warning),
                                    onPressed: () => _showBookTicketDialog(
                                        trip, ap),
                                    child: Text(l.bookOfflineTicket,
                                        style: const TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ],
                              if (trip.status == TripStatus.started)
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.success),
                                    onPressed: () => ap.updateTripStatus(
                                        trip.id, TripStatus.finished, _token),
                                    child: const Text('Finish'),
                                  ),
                                ),
                              if (trip.status == TripStatus.finished)
                                Expanded(
                                  child: Center(
                                    child: Text('Finished ✓',
                                        style: TextStyle(
                                            color: AppTheme.success,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                            ]),
                          ),
                          if (trip.passengerNames.isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l.passengers,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: trip.passengerNames
                                        .map((name) => Chip(
                                              label: Text(name,
                                                  style: const TextStyle(
                                                      fontSize: 12)),
                                              avatar: const Icon(
                                                  Icons.person_outline,
                                                  size: 14),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _tripStatusIcon(TripStatus status) {
    switch (status) {
      case TripStatus.started:
        return const Icon(Icons.play_circle_rounded, color: AppTheme.primary);
      case TripStatus.finished:
        return const Icon(Icons.check_circle_rounded, color: AppTheme.success);
      default:
        return const Icon(Icons.schedule_rounded, color: AppTheme.warning);
    }
  }

  void _confirmStartTrip(Trip trip) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Start Trip'),
        content: const Text('Start this trip now?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context).cancel)),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminProvider>().updateTripStatus(
                  trip.id, TripStatus.started, _token);
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTrip(Trip trip) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.delete),
        content: Text(
            '${trip.startStation?.city ?? ''} → ${trip.endStation?.city ?? ''}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AdminProvider>().deleteTrip(trip.id, _token);
            },
            child: Text(l.delete),
          ),
        ],
      ),
    );
  }

  void _showBookTicketDialog(Trip trip, AdminProvider ap) {
    final l = AppLocalizations.of(context);
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.bookOfflineTicket),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(labelText: l.passengerName),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final name = nameCtrl.text.trim();
              Navigator.pop(ctx);
              final success = await ap.bookOfflineTicket(trip.id, name, _token);
              if (success && mounted) _showPrintedTicket(trip, name, ap);
            },
            child: Text(l.book),
          ),
        ],
      ),
    );
  }

  void _showPrintedTicket(Trip trip, String passengerName, AdminProvider ap) {
    String matricul = 'N/A';
    if (trip.driverId != null) {
      try {
        matricul = ap.vehicles
            .firstWhere((v) => v.driverId == trip.driverId)
            .plate;
      } catch (_) {}
    }
    final priceStr = formatLouagePrice(
        trip.startStation?.city ?? '', trip.endStation?.city ?? '',
        fromStation: trip.startStation?.name ?? '',
        toStation: trip.endStation?.name ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.textPrimary, width: 1.5)),
        content: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.directions_bus_rounded,
                size: 40, color: AppTheme.primary),
            const SizedBox(height: 8),
            const Text('LOUAGE TICKET',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 2)),
            const Divider(height: 24),
            _ticketRow(AppLocalizations.of(context).passenger, passengerName),
            _ticketRow(AppLocalizations.of(context).from,
                trip.startStation?.name ?? 'N/A'),
            _ticketRow(AppLocalizations.of(context).to,
                trip.endStation?.name ?? 'N/A'),
            _ticketRow('Vehicle', matricul),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10)),
              child: Text('$priceStr TND',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary)),
            ),
          ]),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.print_rounded),
            label: const Text('Print'),
          ),
        ],
      ),
    );
  }

  Widget _ticketRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(
            flex: 2,
            child: Text('$label:',
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    fontSize: 13))),
        Expanded(
            flex: 3,
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13))),
      ]),
    );
  }

  void _showCreateTripDialog() async {
    final adminProvider = context.read<AdminProvider>();
    if (adminProvider.stations.isEmpty) {
      await adminProvider.fetchStations();
    }
    final stations = adminProvider.stations;
    if (stations.length < 2 || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Need at least 2 stations first')));
      }
      return;
    }
    final l = AppLocalizations.of(context);
    final cities = stations.map((s) => s.city).toSet().toList()..sort();

    String? startCity;
    String? endCity;
    int? startId;
    int? endId;
    DateTime selectedDate =
        DateTime.now().add(const Duration(hours: 2));
    int? selectedDriverId;
    List<AdminUser> availableDrivers = [];
    bool loadingDrivers = false;

    List<Station> stationsFor(String? city) => city == null
        ? stations
        : stations.where((s) => s.city == city).toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModal) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l.createTrip),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.departureCity,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                DropdownButton<String>(
                  isExpanded: true,
                  value: startCity,
                  hint: const Text('Select city...'),
                  items: cities
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setModal(() {
                    startCity = v;
                    startId = null;
                    selectedDriverId = null;
                    availableDrivers = [];
                  }),
                ),
                if (startCity != null) ...[
                  const SizedBox(height: 8),
                  Text(l.departureStation,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  DropdownButton<int>(
                    isExpanded: true,
                    value: startId,
                    hint: const Text('Select station...'),
                    items: stationsFor(startCity)
                        .map((s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.name)))
                        .toList(),
                    onChanged: (v) async {
                      if (v != null) {
                        setModal(() {
                          startId = v;
                          selectedDriverId = null;
                          loadingDrivers = true;
                        });
                        await adminProvider.fetchAvailableDrivers(_token,
                            stationId: v);
                        setModal(() {
                          availableDrivers =
                              adminProvider.availableDrivers;
                          loadingDrivers = false;
                        });
                      }
                    },
                  ),
                ],
                const SizedBox(height: 12),
                Text(l.destinationCity,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                DropdownButton<String>(
                  isExpanded: true,
                  value: endCity,
                  hint: const Text('Select city...'),
                  items: cities
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setModal(() {
                    endCity = v;
                    endId = null;
                  }),
                ),
                if (endCity != null) ...[
                  const SizedBox(height: 8),
                  Text(l.destinationStation,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  DropdownButton<int>(
                    isExpanded: true,
                    value: endId,
                    hint: const Text('Select station...'),
                    items: stationsFor(endCity)
                        .map((s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.name)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setModal(() => endId = v);
                    },
                  ),
                ],
                const SizedBox(height: 12),
                Text(l.assignDriver,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (loadingDrivers)
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(child: CircularProgressIndicator()))
                else if (startId == null)
                  Text('Select a start station first',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))
                else if (availableDrivers.isEmpty)
                  Text('No available drivers',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))
                else
                  DropdownButton<int?>(
                    isExpanded: true,
                    value: selectedDriverId,
                    hint: const Text('Select driver...'),
                    items: [
                      const DropdownMenuItem<int?>(
                          value: null, child: Text('— None —')),
                      ...availableDrivers.map((d) => DropdownMenuItem<int?>(
                            value: d.id,
                            child: Text(
                                '${d.firstName} ${d.lastName}${d.currentStation != null ? ' — ${d.currentStation!.name}' : ''}'),
                          )),
                    ],
                    onChanged: (v) => setModal(() => selectedDriverId = v),
                  ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.departureTime,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}  ${selectedDate.hour.toString().padLeft(2, '0')}:${selectedDate.minute.toString().padLeft(2, '0')}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_month_rounded),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (d != null && context.mounted) {
                        final t = await showTimePicker(
                          context: context,
                          initialTime:
                              TimeOfDay.fromDateTime(selectedDate),
                        );
                        if (t != null) {
                          setModal(() => selectedDate = DateTime(
                              d.year, d.month, d.day, t.hour, t.minute));
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
            ElevatedButton(
              onPressed: () async {
                if (startId == null || endId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content:
                          Text('Select both start and end stations.')));
                  return;
                }
                if (startId == endId) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Start and End cannot be the same.')));
                  return;
                }
                Navigator.pop(ctx);
                await context.read<AdminProvider>().createTrip(
                      token: _token,
                      startStationId: startId!,
                      endStationId: endId!,
                      departureTime: selectedDate,
                      driverId: selectedDriverId,
                    );
              },
              child: Text(l.save),
            ),
          ],
        ),
      ),
    );
  }
}
