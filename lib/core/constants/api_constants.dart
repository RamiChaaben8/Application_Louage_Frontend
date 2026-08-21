class ApiConstants {
  // PC's local network IP — works for physical devices on the same WiFi
  // If using Android Emulator, change this to 'http://10.0.2.2:5113/api'
  static String get baseUrl => 'http://192.168.1.14:5113/api';

  static String get loginEndpoint => '$baseUrl/Auth/login';
  static String get registerCustomerEndpoint => '$baseUrl/Auth/register/customer';
  static String get registerDriverEndpoint => '$baseUrl/Auth/register/driver';
  static String get registerEndpoint => registerCustomerEndpoint;
  static String get tripsEndpoint => '$baseUrl/Trips';
  static String get ticketsEndpoint => '$baseUrl/Tickets';
  static String get stationsEndpoint => '$baseUrl/Stations';
  static String get vehiclesEndpoint => '$baseUrl/Vehicles';
  static String get adminBaseEndpoint => '$baseUrl/Admin';
  static String get adminUsersEndpoint => '$adminBaseEndpoint/users';
  static String get adminCreateAdminEndpoint => '$adminBaseEndpoint/create-admin';
  static String get adminPendingDriversEndpoint => '$adminBaseEndpoint/drivers/pending';
  static String adminApproveDriverEndpoint(int id) => '$adminBaseEndpoint/drivers/$id/approve';
  static String adminDeclineDriverEndpoint(int id) => '$adminBaseEndpoint/drivers/$id/decline';
  static String adminDeleteUserEndpoint(int id) => '$adminBaseEndpoint/users/$id';
  static String driverStatusEndpoint(int id) => '$baseUrl/Auth/driver-status/$id';
}