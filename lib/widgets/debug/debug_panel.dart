import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/obd_provider.dart';
import '../../services/obd/elm327_protocol.dart';
import '../../theme/colors.dart';
import 'at_command_input.dart';

/// Swipe-up debug panel overlay using DraggableScrollableSheet.
///
/// Shows raw PID data, connection info, response times,
/// and an AT command input for manual testing.
class DebugPanel extends ConsumerWidget {
  const DebugPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final data = ref.watch(latestDataProvider);
    final useMock = ref.watch(useMockProvider);
    final service = ref.watch(obdServiceProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.06,
      minChildSize: 0.06,
      maxChildSize: 0.80,
      snap: true,
      snapSizes: const [0.06, 0.45, 0.80],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
              // ── Drag handle ──
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Section: Connection Status ──
              _SectionHeader(title: 'Connection'),
              SwitchListTile(
                title: Text('Use Mock Data', style: theme.textTheme.bodySmall),
                value: useMock,
                onChanged: (val) {
                  ref.read(useMockProvider.notifier).toggle();
                },
                contentPadding: EdgeInsets.zero,
                activeTrackColor: theme.colorScheme.primary,
              ),
              _InfoRow(
                label: 'Source',
                value: useMock ? 'Mock Simulation' : 'BLE OBD-II',
              ),
              _InfoRow(
                label: 'Status',
                value: service.statusMessage,
              ),
              _InfoRow(
                label: 'Protocol',
                value: 'ISO 15765-4 CAN (29-bit, 500 kbps)',
              ),
              const SizedBox(height: 12),

              // ── Section: Live Data ──
              _SectionHeader(title: 'Live Data'),
              _buildPidRow(
                'Engine RPM',
                Elm327Protocol.pidRpm,
                data.rpm,
                '${data.rpm.toStringAsFixed(1)} rpm',
                Elm327Protocol.encodeResponse(Elm327Protocol.pidRpm, data.rpm),
              ),
              _buildPidRow(
                'EngineOil Temp',
                Elm327Protocol.pidEngineOilTemp,
                data.engineOilTemp,
                '${data.engineOilTemp.toStringAsFixed(1)} °C',
                Elm327Protocol.encodeResponse(
                    Elm327Protocol.pidEngineOilTemp, data.engineOilTemp),
              ),
              _buildPidRow(
                'Throttle Position',
                Elm327Protocol.pidThrottlePos,
                data.throttlePosition,
                '${data.throttlePosition.toStringAsFixed(1)} %',
                Elm327Protocol.encodeResponse(
                    Elm327Protocol.pidThrottlePos, data.throttlePosition),
              ),
              _buildPidRow(
                'Vehicle Speed',
                Elm327Protocol.pidSpeed,
                data.speed,
                '${data.speed.toStringAsFixed(1)} km/h',
                Elm327Protocol.encodeResponse(Elm327Protocol.pidSpeed, data.speed),
              ),
              _buildPidRow(
                'Intake Air Temp',
                Elm327Protocol.pidIntakeAirTemp,
                data.intakeAirTemp,
                '${data.intakeAirTemp.toStringAsFixed(1)} °C',
                Elm327Protocol.encodeResponse(
                    Elm327Protocol.pidIntakeAirTemp, data.intakeAirTemp),
              ),
              const SizedBox(height: 12),

              // ── Section: AT Command ──
              _SectionHeader(title: 'Manual Command'),
              AtCommandInput(
                onSend: (cmd) => service.sendRawCommand(cmd),
              ),
              const SizedBox(height: 24),
            ],
          ),
          ),
        );
      },
    );
  }

  Widget _buildPidRow(
    String name,
    String pid,
    double value,
    String decoded,
    String hex,
  ) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              // PID code
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.lavenderDark : AppColors.lavender)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  pid,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: isDark ? AppColors.lavenderDark : AppColors.lavender,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Name
              Expanded(
                flex: 3,
                child: Text(
                  name,
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Hex response
              Expanded(
                flex: 2,
                child: Text(
                  hex,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Decoded value
              Expanded(
                flex: 2,
                child: Text(
                  decoded,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
