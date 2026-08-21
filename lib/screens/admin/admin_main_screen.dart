import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../../data/models/admin_user_model.dart';
import '../../data/models/station_model.dart';
import '../../data/models/vehicle_model.dart';
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
        adminProvider.fetchVehicles();
        break;
      case 4:
        adminProvider.fetchTrips();
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
              return _buildVehiclesTab(adminProvider);
            case 4:
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
            icon: Icon(Icons.directions_car),
            label: 'Vehicles',
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
          onPressed: _showCreateVehicleDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Vehicle'),
        );
      case 4:
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

  // 4. VEHICLES TAB
  Widget _buildVehiclesTab(AdminProvider adminProvider) {
    final vehicles = adminProvider.vehicles;

    if (vehicles.isEmpty) {
      return const Center(child: Text('No vehicles added yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = vehicles[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.teal,
              child: Icon(Icons.directions_car, color: Colors.white),
            ),
            title: Text(vehicle.plate, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Capacity: ${vehicle.capacity} seats | Driver ID: ${vehicle.driverId}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDeleteVehicle(vehicle),
            ),
          ),
        );
      },
    );
  }

  void _showCreateVehicleDialog() {
    final plateCtrl = TextEditingController();
    final capCtrl = TextEditingController(text: '8');
    final driverIdCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Vehicle'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: plateCtrl,
                decoration: const InputDecoration(labelText: 'Plate (e.g. 123 TUN 4567)'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: capCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Capacity (Seats)'),
                validator: (v) => int.tryParse(v ?? '') == null ? 'Valid number required' : null,
              ),
              TextFormField(
                controller: driverIdCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Driver User ID'),
                validator: (v) => int.tryParse(v ?? '') == null ? 'Valid driver ID required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop();
                final messenger = ScaffoldMessenger.of(context);
                final success = await context.read<AdminProvider>().createVehicle(
                      token: _token,
                      plate: plateCtrl.text.trim(),
                      capacity: int.parse(capCtrl.text.trim()),
                      driverId: int.parse(driverIdCtrl.text.trim()),
                    );
                if (success && mounted) {
                  messenger.showSnackBar(const SnackBar(content: Text('Vehicle added!')));
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteVehicle(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Vehicle?'),
        content: Text('Are you sure you want to delete vehicle ${vehicle.plate}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final messenger = ScaffoldMessenger.of(context);
              final success = await context.read<AdminProvider>().deleteVehicle(vehicle.id, _token);
              if (success && mounted) {
                messenger.showSnackBar(const SnackBar(content: Text('Vehicle deleted')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 5. TRIPS TAB
  Widget _buildTripsTab(AdminProvider adminProvider) {
    final trips = adminProvider.trips;

    if (trips.isEmpty) {
      return const Center(child: Text('No trips available.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final trip = trips[index];
        final start = trip.startStation?.name ?? 'Station #${trip.startStationId}';
        final end = trip.endStation?.name ?? 'Station #${trip.endStationId}';
        final timeStr = '${trip.departureTime.day}/${trip.departureTime.month}/${trip.departureTime.year} ${trip.departureTime.hour.toString().padLeft(2, '0')}:${trip.departureTime.minute.toString().padLeft(2, '0')}';

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.indigo,
              child: Icon(Icons.route, color: Colors.white),
            ),
            title: Text('$start -> $end', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Departure: $timeStr'),
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
                    if (trip.status == TripStatus.pending)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _confirmStartTripAdmin(trip),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                          child: const Text('Start Trip'),
                        ),
                      ),
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
                  onChanged: (v) {
                    if (v != null) setModalState(() => startId = v);
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

