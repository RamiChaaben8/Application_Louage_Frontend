import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  String get _token => context.read<AuthProvider>().currentUser?.token ?? '';

  void _loadData() {
    final adminProvider = context.read<AdminProvider>();
    switch (_currentIndex) {
      case 0:
        adminProvider.fetchUsers(_token);
        break;
      case 1:
        adminProvider.fetchPendingDrivers(_token);
        break;
      case 2:
        adminProvider.fetchStations();
        break;
      case 3:
        adminProvider.fetchTrips();
        adminProvider.fetchVehicles();
        adminProvider.fetchStations();
        break;
    }
  }

  void _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (adminProvider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      adminProvider.error!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          switch (_currentIndex) {
            case 0:
              return _buildUsersTab(adminProvider);
            case 1:
              return _buildPendingDriversTab(adminProvider);
            case 2:
              return _buildStationsTab(adminProvider);
            case 3:
              return _buildTripsTab(adminProvider);
            default:
              return const SizedBox.shrink();
          }
        },
      ),
      floatingActionButton: _buildFab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          _loadData();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.verified_user),
            label: 'Approvals',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on),
            label: 'Stations',
          ),
          NavigationDestination(
            icon: Icon(Icons.route),
            label: 'Trips',
          ),
        ],
      ),
    );
  }

  Widget? _buildFab() {
    switch (_currentIndex) {
      case 0:
        return FloatingActionButton.extended(
          onPressed: _showCreateAdminDialog,
          icon: const Icon(Icons.person_add),
          label: const Text('New Admin'),
        );
      case 2:
        return FloatingActionButton.extended(
          onPressed: _showCreateStationDialog,
          icon: const Icon(Icons.add_location_alt),
          label: const Text('Add Station'),
        );
      case 3:
        return FloatingActionButton.extended(
          onPressed: _showCreateTripDialog,
          icon: const Icon(Icons.add_road),
          label: const Text('Create Trip'),
        );
      default:
        return null;
    }
  }

  // 1. USERS TAB
  Widget _buildUsersTab(AdminProvider adminProvider) {
    var filtered = adminProvider.users.where((u) {
      final matchesSearch = '${u.firstName} ${u.lastName} ${u.email}'
          .toLowerCase()
          .contains(_userSearchQuery.toLowerCase());
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
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _userSearchQuery = val;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _userRoleFilter,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All')),
                  DropdownMenuItem(value: 'Customer', child: Text('Customer')),
                  DropdownMenuItem(value: 'Driver', child: Text('Driver')),
                  DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _userRoleFilter = v;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No users found.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    Color chipColor = Colors.blue;
                    if (user.userType.toLowerCase() == 'admin') chipColor = Colors.purple;
                    if (user.userType.toLowerCase() == 'driver') chipColor = Colors.orange;

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: chipColor.withValues(alpha: 0.15),
                          child: Icon(
                            user.userType.toLowerCase() == 'admin'
                                ? Icons.admin_panel_settings
                                : (user.userType.toLowerCase() == 'driver'
                                    ? Icons.directions_car
                                    : Icons.person),
                            color: chipColor,
                          ),
                        ),
                        title: Text(
                          '${user.firstName} ${user.lastName}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(user.email),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(
                                user.userType,
                                style: TextStyle(fontSize: 11, color: chipColor),
                              ),
                              backgroundColor: chipColor.withValues(alpha: 0.1),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _confirmDeleteUser(context, user),
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

  void _showCreateAdminDialog() {
    final fnCtrl = TextEditingController();
    final lnCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Admin'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: fnCtrl,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: lnCtrl,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop();
                final messenger = ScaffoldMessenger.of(context);
                final success = await context.read<AdminProvider>().createAdmin(
                      token: _token,
                      firstName: fnCtrl.text.trim(),
                      lastName: lnCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      password: passCtrl.text.trim(),
                    );
                if (success && mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Admin created successfully!')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(BuildContext context, AdminUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User?'),
        content: Text('Are you sure you want to delete ${user.firstName} ${user.lastName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final messenger = ScaffoldMessenger.of(context);
              final success = await context.read<AdminProvider>().deleteUser(user.id, _token);
              if (success && mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('User deleted successfully')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 2. PENDING DRIVERS TAB
  Widget _buildPendingDriversTab(AdminProvider adminProvider) {
    final drivers = adminProvider.pendingDrivers;

    if (drivers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 12),
            Text('No pending driver approvals!', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: drivers.length,
      itemBuilder: (context, index) {
        final driver = drivers[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showDriverDetailDialog(driver),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.orangeAccent,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${driver.firstName} ${driver.lastName}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(driver.email,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        if (driver.licenseNumber != null && driver.licenseNumber!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'License: ${driver.licenseNumber}',
                              style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDriverDetailDialog(AdminUser driver) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 36, color: Colors.orange),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${driver.firstName} ${driver.lastName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      driver.email,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),

              // Driver info section
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Driver Information',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 8),
                    _infoRow(Icons.badge, 'License', driver.licenseNumber ?? 'N/A'),

                    const SizedBox(height: 16),

                    // Vehicle info section
                    const Text(
                      'Vehicle Information',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 8),
                    if (driver.vehicle != null) ...[
                      _infoRow(Icons.pin, 'Plate', driver.vehicle!.plate),
                      _infoRow(Icons.event_seat, 'Capacity', '${driver.vehicle!.capacity} seats'),
                    ] else
                      const Text('No vehicle information provided.',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _declineDriver(driver.id);
            },
            icon: const Icon(Icons.close, color: Colors.red),
            label: const Text('Decline', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _approveDriver(driver.id);
            },
            icon: const Icon(Icons.check),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  void _approveDriver(int driverId) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await context.read<AdminProvider>().approveDriver(driverId, _token);
    if (success && mounted) {
      messenger.showSnackBar(const SnackBar(content: Text('Driver approved successfully!')));
    }
  }

  void _declineDriver(int driverId) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await context.read<AdminProvider>().declineDriver(driverId, _token);
    if (success && mounted) {
      messenger.showSnackBar(const SnackBar(content: Text('Driver declined.')));
    }
  }

  // 3. STATIONS TAB
  Widget _buildStationsTab(AdminProvider adminProvider) {
    final stations = adminProvider.stations;

    if (stations.isEmpty) {
      return const Center(child: Text('No stations configured yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: stations.length,
      itemBuilder: (context, index) {
        final station = stations[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.location_city, color: Colors.white),
            ),
            title: Text(station.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('City: ${station.city}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDeleteStation(station),
            ),
          ),
        );
      },
    );
  }

  void _showCreateStationDialog() {
    final nameCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Station'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Station Name (e.g. Bab Alioua)'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: cityCtrl,
                decoration: const InputDecoration(labelText: 'City (e.g. Tunis)'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop();
                final messenger = ScaffoldMessenger.of(context);
                final success = await context.read<AdminProvider>().createStation(
                      token: _token,
                      name: nameCtrl.text.trim(),
                      city: cityCtrl.text.trim(),
                    );
                if (success && mounted) {
                  messenger.showSnackBar(const SnackBar(content: Text('Station added!')));
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteStation(Station station) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Station?'),
        content: Text('Are you sure you want to delete station ${station.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final messenger = ScaffoldMessenger.of(context);
              final success = await context.read<AdminProvider>().deleteStation(station.id, _token);
              if (success && mounted) {
                messenger.showSnackBar(const SnackBar(content: Text('Station deleted')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }


  // 4. TRIPS TAB
  Widget _buildTripsTab(AdminProvider adminProvider) {
    var trips = List<Trip>.from(adminProvider.trips);

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
    
    final stations = adminProvider.stations;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Start Station', isDense: true),
                  value: _filterStartStationId,
                  items: [
                    const DropdownMenuItem<int>(value: null, child: Text('All')),
                    ...stations.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                  ],
                  onChanged: (val) => setState(() => _filterStartStationId = val),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'End Station', isDense: true),
                  value: _filterEndStationId,
                  items: [
                    const DropdownMenuItem<int>(value: null, child: Text('All')),
                    ...stations.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                  ],
                  onChanged: (val) => setState(() => _filterEndStationId = val),
                ),
              ),
            ],
          ),
        ),
        CheckboxListTile(
          title: const Text('Show Trip History', style: TextStyle(fontWeight: FontWeight.bold)),
          value: _showTripHistory,
          onChanged: (val) {
            setState(() {
              _showTripHistory = val ?? false;
            });
          },
        ),
        Expanded(
          child: trips.isEmpty
              ? const Center(child: Text('No trips available.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    final start = trip.startStation?.name ?? 'Station #${trip.startStationId}';
                    final end = trip.endStation?.name ?? 'Station #${trip.endStationId}';
                    final timeStr = '${trip.departureTime.day}/${trip.departureTime.month}/${trip.departureTime.year} ${trip.departureTime.hour.toString().padLeft(2, '0')}:${trip.departureTime.minute.toString().padLeft(2, '0')}';

                    int capacity = 0;
                    String matricul = 'No Vehicle';
                    if (trip.driverId != null) {
                      try {
                        final v = adminProvider.vehicles.firstWhere((v) => v.driverId == trip.driverId);
                        capacity = v.capacity;
                        matricul = v.plate;
                      } catch (_) {}
                    }
                    final booked = trip.passengerNames.length;
                    final available = capacity > 0 ? (capacity - booked) : 0;
                    
                    final driverStr = trip.driverName?.isNotEmpty == true ? trip.driverName! : 'Unknown Driver';
                    final grasName = '$driverStr - $matricul';

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.indigo,
                          child: Icon(Icons.route, color: Colors.white),
                        ),
                        title: Text(grasName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Route: $start \u2192 $end', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.indigo)),
                            const SizedBox(height: 2),
                            Text('Departure: $timeStr'),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.green.shade200)),
                                  child: const Text('Price: 50 TND', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.blue.shade200)),
                                  child: Text(capacity > 0 ? '$available / $capacity Seats' : 'No Vehicle', style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (trip.status == TripStatus.started)
                              const Icon(Icons.play_circle_fill, color: Colors.green),
                            if (trip.status == TripStatus.finished)
                              const Icon(Icons.check_circle, color: Colors.grey),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _confirmDeleteTrip(trip),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                if (trip.status == TripStatus.pending) ...[
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _confirmStartTripAdmin(trip),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                                      child: const Text('Start Trip'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _showBookTicketDialog(trip, adminProvider),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                                      child: const Text('Book Ticket'),
                                    ),
                                  ),
                                ],
                                if (trip.status == TripStatus.started)
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => adminProvider.updateTripStatus(trip.id, TripStatus.finished, _token),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                      child: const Text('Finish Trip'),
                                    ),
                                  ),
                                if (trip.status == TripStatus.finished)
                                  const Expanded(
                                    child: Center(child: Text('Trip Finished', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                                  ),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showBookTicketDialog(Trip trip, AdminProvider adminProvider) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Book Ticket'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Passenger Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final passenger = nameCtrl.text.trim();
              Navigator.pop(ctx);
              final success = await adminProvider.bookOfflineTicket(trip.id, passenger, _token);
              if (success && mounted) {
                _printTicket(trip, passenger, adminProvider);
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to book ticket on server.')));
              }
            },
            child: const Text('Book & Print'),
          ),
        ],
      ),
    );
  }

  void _printTicket(Trip trip, String passengerName, AdminProvider adminProvider) {
    if (adminProvider.vehicles.isEmpty) {
      adminProvider.fetchVehicles().then((_) {
        if (!mounted) return;
        _showPrintedTicketDialog(trip, passengerName, adminProvider);
      });
    } else {
      _showPrintedTicketDialog(trip, passengerName, adminProvider);
    }
  }

  void _showPrintedTicketDialog(Trip trip, String passengerName, AdminProvider adminProvider) {
    String matricul = 'Not Assigned';
    if (trip.driverId != null) {
      try {
        final vehicle = adminProvider.vehicles.firstWhere((v) => v.driverId == trip.driverId);
        matricul = vehicle.plate;
      } catch (_) {}
    }
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.directions_bus, size: 40, color: Colors.indigo),
              const SizedBox(height: 8),
              const Text('LOUAGE TICKET', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 2)),
              const Divider(color: Colors.black, thickness: 1.5, height: 24),
              _ticketRow('Passenger', passengerName),
              _ticketRow('From', trip.startStation?.name ?? 'Unknown'),
              _ticketRow('To', trip.endStation?.name ?? 'Unknown'),
              _ticketRow('Vehicle Matricul', matricul),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('Price: 50 TND', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.print),
            label: const Text('Print'),
          ),
        ],
      ),
    );
  }

  Widget _ticketRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey))),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }


  void _confirmStartTripAdmin(Trip trip) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start Trip'),
        content: const Text('Are you sure you want to start this trip now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminProvider>().updateTripStatus(trip.id, TripStatus.started, _token);
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _showCreateTripDialog() async {
    final adminProvider = context.read<AdminProvider>();
    if (adminProvider.stations.isEmpty) {
      await adminProvider.fetchStations();
    }
    final stations = adminProvider.stations;
    if (stations.length < 2) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 2 stations first!')),
      );
      return;
    }

    int startId = stations.first.id;
    int endId = stations[1].id;
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 2));
    int? selectedDriverId;
    List<AdminUser> availableDrivers = [];
    bool loadingDrivers = false;

    // Helper to load available drivers for a given station
    Future<List<AdminUser>> loadDriversForStation(int stationId) async {
      await adminProvider.fetchAvailableDrivers(_token, stationId: stationId);
      return adminProvider.availableDrivers;
    }

    // Load initial drivers for the default start station
    availableDrivers = await loadDriversForStation(startId);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Create New Trip'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Start Station:', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<int>(
                  isExpanded: true,
                  value: startId,
                  items: stations
                      .map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Text('${s.name} (${s.city})'),
                          ))
                      .toList(),
                  onChanged: (v) async {
                    if (v != null) {
                      setModalState(() {
                        startId = v;
                        selectedDriverId = null;
                        loadingDrivers = true;
                      });
                      final drivers = await loadDriversForStation(v);
                      setModalState(() {
                        availableDrivers = drivers;
                        loadingDrivers = false;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                const Text('End Station:', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<int>(
                  isExpanded: true,
                  value: endId,
                  items: stations
                      .map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Text('${s.name} (${s.city})'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setModalState(() => endId = v);
                  },
                ),
                const SizedBox(height: 12),
                const Text('Driver (optional):', style: TextStyle(fontWeight: FontWeight.bold)),
                if (loadingDrivers)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (availableDrivers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No available drivers at selected start station.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  )
                else
                  DropdownButton<int?>(
                    isExpanded: true,
                    value: selectedDriverId,
                    hint: const Text('Select a driver...'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('— None —')),
                      ...availableDrivers.map((d) => DropdownMenuItem<int?>(
                            value: d.id,
                            child: Text(
                              '${d.firstName} ${d.lastName}${d.currentStation != null ? " — ${d.currentStation!.name}" : ""}',
                            ),
                          )),
                    ],
                    onChanged: (v) => setModalState(() => selectedDriverId = v),
                  ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Departure Time:'),
                  subtitle: Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year} ${selectedDate.hour.toString().padLeft(2, '0')}:${selectedDate.minute.toString().padLeft(2, '0')}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_month),
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (pickedDate != null && context.mounted) {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDate),
                        );
                        if (pickedTime != null) {
                          setModalState(() {
                            selectedDate = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (startId == endId) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Start and End station cannot be the same.')),
                  );
                  return;
                }
                Navigator.of(ctx).pop();
                final messenger = ScaffoldMessenger.of(context);
                final success = await context.read<AdminProvider>().createTrip(
                      token: _token,
                      startStationId: startId,
                      endStationId: endId,
                      departureTime: selectedDate,
                      driverId: selectedDriverId,
                    );
                if (success && mounted) {
                  messenger.showSnackBar(const SnackBar(content: Text('Trip created!')));
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteTrip(Trip trip) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Trip?'),
        content: const Text('Are you sure you want to delete this trip?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final messenger = ScaffoldMessenger.of(context);
              final success = await context.read<AdminProvider>().deleteTrip(trip.id, _token);
              if (success && mounted) {
                messenger.showSnackBar(const SnackBar(content: Text('Trip deleted')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

