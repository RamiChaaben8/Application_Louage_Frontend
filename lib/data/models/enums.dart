enum TicketStatus {
  active,
  refunded,
  used,
  cancelled;

  static TicketStatus fromJson(dynamic value) {
    if (value is int) {
      if (value >= 0 && value < TicketStatus.values.length) {
        return TicketStatus.values[value];
      }
      return TicketStatus.active;
    }
    if (value is String) {
      return TicketStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => TicketStatus.active,
      );
    }
    return TicketStatus.active;
  }
}

enum VehicleStatus {
  available,
  inUse,
  maintenance,
  outOfService;

  static VehicleStatus fromJson(dynamic value) {
    if (value is int) {
      if (value >= 0 && value < VehicleStatus.values.length) {
        return VehicleStatus.values[value];
      }
      return VehicleStatus.available;
    }
    if (value is String) {
      return VehicleStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => VehicleStatus.available,
      );
    }
    return VehicleStatus.available;
  }
}

enum TripStatus {
  pending,
  started,
  finished;

  static TripStatus fromJson(dynamic value) {
    if (value is int) {
      if (value >= 0 && value < TripStatus.values.length) {
        return TripStatus.values[value];
      }
      return TripStatus.pending;
    }
    if (value is String) {
      return TripStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => TripStatus.pending,
      );
    }
    return TripStatus.pending;
  }
}
