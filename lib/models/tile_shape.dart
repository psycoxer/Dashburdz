/// Defines the shape and size of a tile in the layout grid.
/// Widgets use this to determine how to render their contents.
enum TileShape {
  /// Massive tile taking up primary real estate (hero metrics).
  hero,
  
  /// Standard 1x1 block.
  square,
  
  /// Horizontal banner spanning multiple columns.
  wide,
  
  /// Vertical tower spanning multiple rows.
  tall,
  
  /// Tiny pill-shaped tile for tertiary metrics.
  chip,
}
