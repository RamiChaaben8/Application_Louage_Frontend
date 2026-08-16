class ApiConstants {
  // PC's local network IP — works for physical devices on the same WiFi
  // If using Android Emulator, change this back to 'http://10.0.2.2:5113/api'
  static String get baseUrl => 'http://192.168.1.14:5113/api';

  static String get loginEndpoint => '$baseUrl/Auth/login';
  static String get registerEndpoint => '$baseUrl/Auth/register/customer';
  static String get tripsEndpoint => '$baseUrl/Trips';
  static String get ticketsEndpoint => '$baseUrl/Tickets';
  static String get stationsEndpoint => '$baseUrl/Stations';
}