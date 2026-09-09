import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// A single demo row for [TableSection], modelling a fictitious fleet vehicle.
///
/// Carries a mix of field types (string, number, [DateTime], [Duration], and
/// a status enum-like string) so the demo table can exercise every kind of
/// default sort comparator [LayrzTable] supports out of the box.
class _DemoVehicle {
  /// Creates a new [_DemoVehicle].
  const _DemoVehicle({
    required this.plate,
    required this.driver,
    required this.odometerKm,
    required this.lastServiceAt,
    required this.idleTime,
    required this.status,
  });

  /// The vehicle's license plate, used as the row's primary label.
  final String plate;

  /// The name of the driver currently assigned to this vehicle.
  final String driver;

  /// The vehicle's total accumulated distance, in kilometers.
  final double odometerKm;

  /// The date and time this vehicle was last serviced.
  final DateTime lastServiceAt;

  /// How long this vehicle has been idle since its last trip.
  final Duration idleTime;

  /// The vehicle's current operational status.
  final String status;
}

/// Builds the table section for the showroom.
///
/// Exercises the real, assembled `LayrzTable<T>` public API end to end: a
/// [LayrzTableController] wired externally so sort/search/column state is
/// visible outside the table, a mix of fixed- and flex-width
/// [LayrzColumn]s, per-cell tap behaviors (a custom [LayrzColumn.onTap]
/// callback versus the default copy-to-clipboard fallback), a
/// [LayrzColumn.richTextBuilder] column to demonstrate rich-text display
/// with plain-text clipboard reconstruction, opt-in multiselect with an
/// [LayrzTable.actionsBuilder] rendering row-level edit/delete actions, and
/// the built-in search field.
///
/// A short on-screen hint lists the affordances that aren't obvious from
/// looking at the table alone: drag-to-reorder headers, the column
/// visibility menu, and the header's right-click/long-press context menu.
class TableSection extends StatefulWidget {
  /// Creates a new [TableSection].
  const TableSection({super.key});

  @override
  State<TableSection> createState() => _TableSectionState();
}

class _TableSectionState extends State<TableSection> {
  /// The controller backing the demo table, created once and disposed with
  /// this state since no external owner is supplied.
  late final LayrzTableController<_DemoVehicle> _controller;

  /// The sample dataset rendered by the table.
  late final List<_DemoVehicle> _vehicles;

  /// The number of rows currently passing the table's search filter,
  /// reported back via [LayrzTable.onFilteredCountChanged].
  int _filteredCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = LayrzTableController<_DemoVehicle>();
    _vehicles = _buildVehicles();
    _filteredCount = _vehicles.length;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Generates a fixed set of 24 sample vehicles covering a spread of
  /// statuses, odometer readings, service dates, and idle durations.
  List<_DemoVehicle> _buildVehicles() {
    const statuses = ['Active', 'Idle', 'Maintenance', 'Offline'];
    const drivers = [
      'Alex Rivera',
      'Bianca Solano',
      'Carlos Mendez',
      'Dana Whitfield',
      'Elena Torres',
      'Farid Haddad',
    ];
    final baseDate = DateTime(2026, 9, 9);

    return List.generate(24, (index) {
      final status = statuses[index % statuses.length];
      return _DemoVehicle(
        plate: 'FLT-${1000 + index}',
        driver: drivers[index % drivers.length],
        odometerKm: 12000.0 + (index * 837.5),
        lastServiceAt: baseDate.subtract(Duration(days: index * 11)),
        idleTime: Duration(minutes: (index * 47) % 720),
        status: status,
      );
    });
  }

  /// Shows a lightweight console confirmation for the "edit" row action, in
  /// place of a real dialog this demo doesn't need.
  void _onEdit(_DemoVehicle vehicle) {
    debugPrint('Edit tapped for ${vehicle.plate}');
  }

  /// Shows a lightweight console confirmation for the "delete" row action, in
  /// place of a real dialog this demo doesn't need.
  void _onDelete(_DemoVehicle vehicle) {
    debugPrint('Delete tapped for ${vehicle.plate}');
  }

  /// Shows a lightweight console confirmation for the plate column's custom
  /// tap callback, demonstrating the non-default [LayrzColumn.onTap] path.
  void _onPlateTap(_DemoVehicle vehicle) {
    debugPrint('Plate tapped: ${vehicle.plate} (driver: ${vehicle.driver})');
  }

  List<LayrzColumn<_DemoVehicle>> get _columns => [
    LayrzColumn<_DemoVehicle>(
      key: const ValueKey('plate'),
      headerText: 'Plate',
      valueBuilder: (vehicle) => vehicle.plate,
      width: 140,
      onTap: _onPlateTap,
    ),
    LayrzColumn<_DemoVehicle>(
      key: const ValueKey('driver'),
      headerText: 'Driver',
      valueBuilder: (vehicle) => vehicle.driver,
    ),
    LayrzColumn<_DemoVehicle>(
      key: const ValueKey('odometer'),
      headerText: 'Odometer (km)',
      valueBuilder: (vehicle) => vehicle.odometerKm.toStringAsFixed(1),
      alignment: Alignment.centerRight,
      width: 160,
    ),
    LayrzColumn<_DemoVehicle>(
      key: const ValueKey('lastService'),
      headerText: 'Last service',
      valueBuilder: (vehicle) => vehicle.lastServiceAt.toIso8601String(),
      width: 180,
    ),
    LayrzColumn<_DemoVehicle>(
      key: const ValueKey('idleTime'),
      headerText: 'Idle time',
      valueBuilder: (vehicle) {
        final hours = vehicle.idleTime.inHours;
        final minutes = vehicle.idleTime.inMinutes % 60;
        return '$hours:${minutes.toString().padLeft(2, '0')}:00';
      },
      alignment: Alignment.centerRight,
      width: 140,
    ),
    LayrzColumn<_DemoVehicle>(
      key: const ValueKey('status'),
      headerText: 'Status',
      valueBuilder: (vehicle) => vehicle.status,
      width: 150,
      richTextBuilder: (vehicle) => [
        TextSpan(
          text: '● ',
          style: TextStyle(color: _statusColor(vehicle.status)),
        ),
        TextSpan(text: vehicle.status),
      ],
    ),
    LayrzColumn<_DemoVehicle>(
      key: const ValueKey('isSortableOff'),
      headerText: 'Notes',
      valueBuilder: (vehicle) => 'See dispatch log',
      isSortable: false,
    ),
  ];

  /// Resolves a status string to an accent color for the status column's
  /// [LayrzColumn.richTextBuilder] dot.
  Color _statusColor(String status) {
    switch (status) {
      case 'Active':
        return const Color(0xFF2E7D32);
      case 'Idle':
        return const Color(0xFFF9A825);
      case 'Maintenance':
        return const Color(0xFF1565C0);
      case 'Offline':
      default:
        return const Color(0xFFD32F2F);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Table',
      description:
          'A virtualized, Material-free data table with sort, search, multiselect, and per-row '
          'actions. $_filteredCount of ${_vehicles.length} rows currently match the active search.',
      child: Padding(
        padding: EdgeInsets.all(tokens.spacing.sp3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Try it: drag a header to reorder columns, right-click (or long-press) a header for '
              'a context menu, use the column-visibility menu to hide/show columns, tap "Plate" to '
              'trigger a custom callback, tap any other cell to copy its text, and select rows to '
              'reveal the Edit/Delete actions.',
              style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
            ),
            SizedBox(height: tokens.spacing.sp3),
            SizedBox(
              height: 560,
              child: LayrzTable<_DemoVehicle>(
                items: _vehicles,
                columns: _columns,
                controller: _controller,
                canSearch: true,
                hasMultiselect: true,
                onFilteredCountChanged: (count) => setState(() => _filteredCount = count),
                actionsBuilder: (vehicle) => [
                  LayrzTableAction(icon: MdiIcons.pencilOutline, labelText: 'Edit', onTap: () => _onEdit(vehicle)),
                  LayrzTableAction(
                    icon: MdiIcons.trashCanOutline,
                    labelText: 'Delete',
                    onTap: () => _onDelete(vehicle),
                    color: tokens.colors.danger,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
