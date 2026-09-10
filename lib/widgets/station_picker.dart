import 'package:flutter/material.dart';
import '../data/models/station_model.dart';

/// Displays all stations grouped by city.
/// Each city is an [ExpansionTile]; stations inside are checkboxes.
/// [selectedIds] is the live list of selected station IDs (mutated in place).
/// [onChanged] is called after every toggle so the parent can call setState.
class StationPicker extends StatefulWidget {
  final List<Station> stations;
  final List<int> selectedIds;
  final VoidCallback onChanged;

  const StationPicker({
    super.key,
    required this.stations,
    required this.selectedIds,
    required this.onChanged,
  });

  @override
  State<StationPicker> createState() => _StationPickerState();
}

class _StationPickerState extends State<StationPicker> {
  // Build city → stations map once; preserve insertion order
  late final Map<String, List<Station>> _byCity;

  @override
  void initState() {
    super.initState();
    _byCity = {};
    for (final s in widget.stations) {
      (_byCity[s.city] ??= []).add(s);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No stations available.', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: _byCity.entries.map((entry) {
        final city = entry.key;
        final cityStations = entry.value;
        final selectedInCity =
            cityStations.where((s) => widget.selectedIds.contains(s.id)).length;

        return Card(
          margin: const EdgeInsets.only(bottom: 4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            title: Text(city, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: selectedInCity > 0
                ? Chip(
                    label: Text('$selectedInCity',
                        style: const TextStyle(fontSize: 11, color: Colors.white)),
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  )
                : null,
            children: cityStations.map((station) {
              final checked = widget.selectedIds.contains(station.id);
              return CheckboxListTile(
                dense: true,
                contentPadding: const EdgeInsets.only(left: 16, right: 8),
                title: Text(station.name, style: const TextStyle(fontSize: 13)),
                value: checked,
                onChanged: (v) {
                  if (v == true) {
                    widget.selectedIds.add(station.id);
                  } else {
                    widget.selectedIds.remove(station.id);
                  }
                  widget.onChanged();
                },
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
