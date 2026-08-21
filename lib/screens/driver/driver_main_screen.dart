import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import '../../providers/trip_provider.dart';
import '../../data/models/enums.dart';
import '../auth/login_screen.dart';

class DriverMainScreen extends StatefulWidget {
  const DriverMainScreen({super.key});

  @override
  State<DriverMainScreen> createState() => _DriverMainScreenState();
}

class _DriverMainScreenState extends State<DriverMainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStatus();
    });
  }

  void _checkStatus() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    final tripProvider = Provider.of<TripProvider>(context, listen: false);

    final driverId = authProvider.currentUser?.userId ?? 0;
    if (driverId > 0) {
      driverProvider.checkDriverStatus(driverId);
      tripProvider.loadStations();
      tripProvider.searchTrips();
    }
  }

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await authProvider.logout();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final driverProvider = Provider.of<DriverProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Status',
            onPressed: _checkStatus,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: driverProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : driverProvider.isDeclined
              ? _buildDeclinedView(user)
              : driverProvider.isApproved
                  ? _buildActiveDashboard(driverProvider, user)
                  : _buildPendingVerificationView(user),
    );
  }

  // View 1: Pending Admin Verification Screen
  Widget _buildPendingVerificationView(dynamic user) {
    return RefreshIndicator(
      onRefresh: () async => _checkStatus(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber.shade400, width: 2),
              ),
              child: Icon(
                Icons.hourglass_top,
                size: 72,
                color: Colors.amber.shade800,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Verification Pending',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Awaiting Admin Approval',
                style: TextStyle(
                  color: Colors.amber.shade900,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.person, 'Driver Name', '${user?.firstName ?? ''} ${user?.lastName ?? ''}'),
                    const Divider(height: 24),
                    _buildInfoRow(Icons.email, 'Email', user?.email ?? 'N/A'),
                    const Divider(height: 24),
                    _buildInfoRow(Icons.badge, 'Driver ID', '#${user?.userId ?? ''}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your registration has been submitted. The station administrator is reviewing your license. Once approved, this screen will automatically unlock your dashboard.',
                      style: TextStyle(fontSize: 13, color: Colors.blue.shade900, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Check Verification Status', style: TextStyle(fontSize: 16)),
                onPressed: _checkStatus,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // View 2: Declined Screen
  Widget _buildDeclinedView(dynamic user) {
    return RefreshIndicator(
      onRefresh: () async => _checkStatus(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red.shade400, width: 2),
              ),
              child: Icon(
                Icons.cancel_outlined,
                size: 72,
                color: Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Registration Declined',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Application Not Approved',
                style: TextStyle(
                  color: Colors.red.shade900,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 22),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Your driver registration application was declined by the administrator. Please contact your local station administrator for more details.',
                      style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Re-check Status', style: TextStyle(fontSize: 16)),
                onPressed: _checkStatus,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // View 3: Active Verified Driver Dashboard
  Widget _buildActiveDashboard(DriverProvider driverProvider, dynamic user) {
    final vehicle = driverProvider.assignedVehicle;
    final tripProvider = Provider.of<TripProvider>(context);

    return RefreshIndicator(
      onRefresh: () async => _checkStatus(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Card(
              color: Colors.blue.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.directions_car, size: 32, color: Colors.blue),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, Driver ${user?.firstName ?? ''}!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'VERIFIED & ACTIVE',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Assigned Vehicle Card
            const Text(
              'Assigned Vehicle',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (vehicle != null) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Plate Number', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text(
                                vehicle.plate,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getVehicleStatusColor(vehicle.status).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _getVehicleStatusColor(vehicle.status)),
                            ),
                            child: Text(
                              vehicle.status.name.toUpperCase(),
                              style: TextStyle(
                                color: _getVehicleStatusColor(vehicle.status),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildVehicleStat(Icons.airline_seat_recline_normal, 'Capacity', '${vehicle.capacity} Seats'),
                          _buildVehicleStat(Icons.confirmation_number, 'Vehicle ID', '#${vehicle.id}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Status Controls
              const Text(
                'Update Vehicle Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: vehicle.status == VehicleStatus.available ? Colors.green : Colors.grey.shade300,
                        foregroundColor: vehicle.status == VehicleStatus.available ? Colors.white : Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Available'),
                      onPressed: () {
                        driverProvider.setVehicleStatus(VehicleStatus.available);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: vehicle.status == VehicleStatus.inUse ? Colors.blue : Colors.grey.shade300,
                        foregroundColor: vehicle.status == VehicleStatus.inUse ? Colors.white : Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.directions_car),
                      label: const Text('In Trip'),
                      onPressed: () {
                        driverProvider.setVehicleStatus(VehicleStatus.inUse);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: vehicle.status == VehicleStatus.maintenance ? Colors.orange : Colors.grey.shade300,
                        foregroundColor: vehicle.status == VehicleStatus.maintenance ? Colors.white : Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.build),
                      label: const Text('Service'),
                      onPressed: () {
                        driverProvider.setVehicleStatus(VehicleStatus.maintenance);
                      },
                    ),
                  ),
                ],
              ),
            ] else ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Icon(Icons.directions_car, color: Colors.blue.shade700, size: 32),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Vehicle Assignment Pending', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            SizedBox(height: 4),
                            Text('Your registration is approved! A vehicle will be assigned to your account by the administrator.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Active Station Trips
            // Active Station Trips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Station Trips Schedule',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCreateTripDialog(context, tripProvider, user?.userId),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Trip'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (tripProvider.isLoadingTrips)
              const Center(child: CircularProgressIndicator())
            else if (tripProvider.trips.isEmpty)
              const Center(child: Text('No trips scheduled today.'))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tripProvider.trips.length > 5 ? 5 : tripProvider.trips.length,
                itemBuilder: (context, index) {
                  final trip = tripProvider.trips[index];
                  final isMyTrip = trip.driverId == user?.userId;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      leading: const Icon(Icons.route, color: Colors.blue),
                      title: Text('${trip.startStation?.city ?? ""} ➔ ${trip.endStation?.city ?? ""}'),
                      subtitle: Text('Departure: ${trip.departureTime.hour.toString().padLeft(2, '0')}:${trip.departureTime.minute.toString().padLeft(2, '0')}'),
                      trailing: Chip(
                        label: Text(isMyTrip ? 'My Trip' : (trip.driverName ?? 'Station Trip')),
                        backgroundColor: isMyTrip ? Colors.green.shade100 : Colors.grey.shade200,
                      ),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          color: Colors.grey.shade50,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Passengers', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              if (trip.passengerNames.isEmpty)
                                const Text('No tickets sold yet.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                              else
                                ...trip.passengerNames.map((name) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person, size: 16, color: Colors.blueGrey),
                                      const SizedBox(width: 8),
                                      Text(name),
                                    ],
                                  ),
                                )),
                              const SizedBox(height: 16),
                              if (isMyTrip)
                                Row(
                                  children: [
                                    if (trip.status == TripStatus.pending)
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _confirmStartTrip(context, tripProvider, trip.id),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                                          child: const Text('Start Trip'),
                                        ),
                                      ),
                                    if (trip.status == TripStatus.started)
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => tripProvider.updateTripStatus(trip.id, TripStatus.finished),
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
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _confirmStartTrip(BuildContext context, TripProvider tripProvider, int tripId) {
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
              tripProvider.updateTripStatus(tripId, TripStatus.started);
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _showCreateTripDialog(BuildContext context, TripProvider tripProvider, int? driverId) {
    int? selectedStartStation;
    int? selectedEndStation;
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create New Trip'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Start Station'),
                      value: selectedStartStation,
                      items: tripProvider.stations.map((s) => DropdownMenuItem(value: s.id, child: Text(s.city))).toList(),
                      onChanged: (val) => setState(() => selectedStartStation = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'End Station'),
                      value: selectedEndStation,
                      items: tripProvider.stations.map((s) => DropdownMenuItem(value: s.id, child: Text(s.city))).toList(),
                      onChanged: (val) => setState(() => selectedEndStation = val),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Departure Time'),
                      subtitle: Text('${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}'),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(context: context, initialTime: selectedTime);
                        if (time != null) {
                          setState(() => selectedTime = time);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedStartStation == null || selectedEndStation == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select both stations')));
                      return;
                    }
                    if (selectedStartStation == selectedEndStation) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Start and end station cannot be the same')));
                      return;
                    }

                    final now = DateTime.now();
                    final depTime = DateTime(now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);

                    final success = await tripProvider.createTrip(
                      startStationId: selectedStartStation!,
                      endStationId: selectedEndStation!,
                      departureTime: depTime,
                      driverId: driverId,
                    );

                    if (success && mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip created successfully!')));
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create trip')));
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _getVehicleStatusColor(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.available:
        return Colors.green;
      case VehicleStatus.inUse:
        return Colors.blue;
      case VehicleStatus.maintenance:
        return Colors.orange;
      case VehicleStatus.outOfService:
        return Colors.red;
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildVehicleStat(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ],
    );
  }
}
