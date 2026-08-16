enum TicketStatus {
  active,
  resale,
  used,
  cancelled
}

enum VehicleStatus {
  available,
  inUse,
  maintenance,
  outOfService
}

// Extension to help parse Enums from JSON
extension TicketStatusExtension on TicketStatus {
  static TicketStatus fromString(String status) {
    return TicketStatus.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == status.toLowerCase(),
      orElse: () => TicketStatus.active,
    );
  }
}

extension VehicleStatusExtension on VehicleStatus {
  static VehicleStatus fromString(String status) {
    return VehicleStatus.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == status.toLowerCase(),
      orElse: () => VehicleStatus.available,
    );
  }
}
