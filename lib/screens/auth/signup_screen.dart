import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/station_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/station_picker.dart';
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

  bool _obscurePassword = true;
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
    final truncated =
        cleaned.length > 8 ? cleaned.substring(cleaned.length - 8) : cleaned;
    return int.tryParse(truncated) ?? 0;
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    final l = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final phone = _parsePhoneNumber(_phoneController.text);
    if (phone <= 0) {
      _showError(l.validPhone);
      return;
    }

    bool success = false;

    if (_selectedRole == 'driver') {
      final plate = _plateController.text.trim().toUpperCase();
      final license = _licenseController.text.trim();
      final capacity = int.tryParse(_capacityController.text.trim()) ?? 8;

      if (plate.isEmpty || license.isEmpty) {
        _showError(l.provideLicenseAndPlate);
        return;
      }
      if (_selectedStationIds.length < 2) {
        _showError(l.selectMin2Stations);
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
      Widget dest = authProvider.isDriver
          ? const DriverMainScreen()
          : const MainNavigationScreen();
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => dest));
    } else {
      _showError(authProvider.error ?? l.registrationFailed);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.danger,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDriver = _selectedRole == 'driver';

    return Scaffold(
      appBar: AppBar(
        title: Text(l.createAccount),
        leading: BackButton(
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Role selector
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _RoleTab(
                      label: l.passenger,
                      icon: Icons.person_rounded,
                      selected: !isDriver,
                      onTap: () => setState(() => _selectedRole = 'customer'),
                    ),
                    _RoleTab(
                      label: l.driver,
                      icon: Icons.directions_car_rounded,
                      selected: isDriver,
                      onTap: () => setState(() => _selectedRole = 'driver'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Driver notice
              if (isDriver)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppTheme.warning, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(l.driverNotice,
                            style: const TextStyle(
                                fontSize: 13, color: AppTheme.textPrimary)),
                      ),
                    ],
                  ),
                ),

              // Personal info
              _SectionHeader(label: l.firstName),
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline),
                  labelText: l.firstName,
                ),
                validator: (v) => v!.isEmpty ? l.enterFirstName : null,
              ),
              const SizedBox(height: 14),
              _SectionHeader(label: l.lastName),
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline),
                  labelText: l.lastName,
                ),
                validator: (v) => v!.isEmpty ? l.enterLastName : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined),
                  labelText: l.email,
                ),
                validator: (v) => v!.isEmpty ? l.enterEmail : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.phone_outlined),
                  labelText: l.phoneNumber,
                ),
                validator: (v) => v!.isEmpty ? l.enterPhone : null,
              ),
              const SizedBox(height: 14),

              // Driver-only fields
              if (isDriver) ...[
                TextFormField(
                  controller: _licenseController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.badge_outlined),
                    labelText: l.licenseNumber,
                  ),
                  validator: (v) => v!.isEmpty ? l.enterLicense : null,
                ),
                const SizedBox(height: 20),
                _SubSectionHeader(
                    icon: Icons.directions_car_outlined, label: l.vehicleInfo),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _plateController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.pin_outlined),
                    labelText: l.vehiclePlate,
                  ),
                  validator: (v) => v!.isEmpty ? l.enterPlate : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _capacityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.event_seat_outlined),
                    labelText: l.seatingCapacity,
                  ),
                  validator: (v) =>
                      (int.tryParse(v ?? '') == null ||
                              int.parse(v!) < 2)
                          ? l.capacityMin
                          : null,
                ),
                const SizedBox(height: 20),
                _SubSectionHeader(
                    icon: Icons.map_outlined, label: l.destinations),
                const SizedBox(height: 12),
                if (_isLoadingStations)
                  const Center(child: CircularProgressIndicator())
                else
                  StationPicker(
                    stations: _stations,
                    selectedIds: _selectedStationIds,
                    onChanged: () => setState(() {}),
                  ),
                const SizedBox(height: 14),
              ],

              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  labelText: l.password,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) =>
                    v!.length < 6 ? l.passwordMin : null,
              ),
              const SizedBox(height: 28),

              authProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _register,
                      child: Text(
                        isDriver ? l.registerAsDriver : l.signUpAsPassenger,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: Text(l.haveAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected ? Colors.white : AppTheme.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _SubSectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SubSectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.textSecondary)),
      ],
    );
  }
}
