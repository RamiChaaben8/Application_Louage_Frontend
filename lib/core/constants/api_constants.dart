import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  // Current PC local network IP on Wi-Fi (for physical Android/iOS devices)
  static const String localIp = '192.168.1.186';
  static const String port = '5113';

  // Automatically select the proper host depending on whether app is running on Desktop/Web or Mobile
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:$port/api';
    }
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        return 'http://localhost:$port/api';
      }
    } catch (_) {}
    return 'http://$localIp:$port/api';
  }

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
  static String driverCurrentStationEndpoint(int id) => '$baseUrl/Auth/driver/$id/current-station';
  static String adminAvailableDriversEndpoint({int? stationId}) => stationId != null
      ? '$adminBaseEndpoint/drivers/available?stationId=$stationId'
      : '$adminBaseEndpoint/drivers/available';
}