import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/connection_indicator.dart';
import '../widgets/dashboard/tile_grid.dart';
import '../widgets/debug/debug_panel.dart';
import '../widgets/theme_toggle.dart';
import '../widgets/warmup_indicator.dart';

/// Main dashboard screen — landscape-only, fullscreen, immersive.
///
/// Composites the tile grid, status indicators, theme toggle,
/// warmup indicator, and the swipe-up debug panel.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Enter immersive mode — hide status bar and nav bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Main tile grid ──
          const Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(8, 8, 8, 28), // Bottom space for debug handle
              child: TileGrid(),
            ),
          ),

          // ── Top-right controls ──
          Positioned(
            top: 10,
            right: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const WarmupIndicator(),
                const SizedBox(width: 10),
                const ThemeToggle(),
                const SizedBox(width: 8),
                const ConnectionIndicator(),
              ],
            ),
          ),

          // ── Swipe-up debug panel ──
          const Positioned.fill(
            child: DebugPanel(),
          ),
        ],
      ),
    );
  }
}
