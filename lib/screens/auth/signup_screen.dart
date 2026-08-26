import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../data/models/station_model.dart';
import '../../providers/auth_provider.dart';
import '../home/main_navigation_screen.dart';
import '../driver/driver_main_screen.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _licenseController = TextEditingController();
  final _plateController = TextEditingController();
  final _capacityController = TextEditingController(text: '8');

  // Role selection: 'customer' or 'driver'
  String _selectedRole = 'customer';

  bool _isLoadingStations = false;
  List<Station> _stations = [];
  final List<int> _selectedStationIds = [];

  @override
  void initState() {
    super.initState();
    _fetchStations();
  }

  Future<void> _fetchStations() async {
    setState(() => _isLoadingStations = true);
    try {
      final res = await http.get(Uri.parse(ApiConstants.stationsEndpoint));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _stations = data.map((e) => Station.fromJson(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching stations: $e');
    } finally {
      setState(() => _isLoadingStations = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _licenseController.dispose();
    _plateController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  int _parsePhoneNumber(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'\D'), '');
    if (cleaned.isEmpty) return 0;
    // Take the last 8 digits if prefixed with country code to guarantee it fits safely in 32-bit int
    final truncated = cleaned.length > 8 ? cleaned.substring(cleaned.length - 8) : cleaned;
    return int.tryParse(truncated) ?? 0;
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final phone = _parsePhoneNumber(_phoneController.text);
      if (phone <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid phone number (at least 8 digits)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      bool success = false;

      if (_selectedRole == 'driver') {
        final plate = _plateController.text.trim().toUpperCase();
        final license = _licenseController.text.trim();
        final capacity = int.tryParse(_capacityController.text.trim()) ?? 8;

        if (plate.isEmpty || license.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please provide both driver license and vehicle plate'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        if (_selectedStationIds.length < 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select at least 2 stations your louage goes to'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        success = await authProvider.registerDriver(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          phoneNum: phone,
          licenseNumber: license,
          plate: plate,
          capacity: capacity,
          stationIds: _selectedStationIds,
        );
      } else {
        success = await authProvider.registerCustomer(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          phoneNum: phone,
        );
      }

      if (!mounted) return;

      if (success) {
        if (authProvider.isDriver) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DriverMainScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Registration failed.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Role Selection Segmented Control
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRole = 'customer';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'customer' ? Colors.blue : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 18,
                                  color: _selectedRole == 'customer' ? Colors.white : Colors.black87,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Passenger',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _selectedRole == 'customer' ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRole = 'driver';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'driver' ? Colors.blue : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.directions_car,
                                  size: 18,
                                  color: _selectedRole == 'driver' ? Colors.white : Colors.black87,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Driver',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _selectedRole == 'driver' ? Colors.white : Colors.black87,
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
                const SizedBox(height: 16),

                // Driver Notice Card
                if (_selectedRole == 'driver')
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber.shade800),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Driver accounts require Admin verification and vehicle assignment before starting work.',
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),

                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Enter your first name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Enter your last name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Enter your email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Enter your phone number' : null,
                ),
                const SizedBox(height: 16),

                // Driver-only fields
                if (_selectedRole == 'driver') ...[
                  TextFormField(
                    controller: _licenseController,
                    decoration: const InputDecoration(
                      labelText: 'Driver License Number',
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Enter your license number' : null,
                  ),
                  const SizedBox(height: 16),
                  // Vehicle section header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: const Row(
                      children: [
                        Icon(Icons.directions_car, size: 18, color: Colors.blueGrey),
                        SizedBox(width: 8),
                        Text(
                          'Vehicle Information',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextFormField(
                    controller: _plateController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Plate (e.g. 123 TUN 4567)',
                      prefixIcon: Icon(Icons.pin),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Enter vehicle plate number' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _capacityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Seating Capacity',
                      prefixIcon: Icon(Icons.event_seat),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        int.tryParse(v ?? '') == null || int.parse(v!) < 2
                            ? 'Capacity must be at least 2 seats'
                            : null,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: const Row(
                      children: [
                        Icon(Icons.map, size: 18, color: Colors.blueGrey),
                        SizedBox(width: 8),
                        Text(
                          'Destinations (Min 2 required)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isLoadingStations)
                    const Center(child: CircularProgressIndicator())
                  else if (_stations.isEmpty)
                    const Text('No stations available.')
                  else
                    Wrap(
                      spacing: 8.0,
                      children: _stations.map((station) {
                        final isSelected = _selectedStationIds.contains(station.id);
                        return FilterChip(
                          label: Text(station.name),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                _selectedStationIds.add(station.id);
                              } else {
                                _selectedStationIds.remove(station.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.length < 6 ? 'Password must be at least 6 characters' : null,
                ),
                const SizedBox(height: 24),
                authProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _register,
                        child: Text(
                          _selectedRole == 'driver' ? 'Register as Driver' : 'Sign Up as Passenger',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text('Already have an account? Log In'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
