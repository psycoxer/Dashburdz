# Dashburdz 🏍️🏎️

Dashburdz is a premium, state-of-the-art vehicle telemetry dashboard built in **Flutter**. Engineered exclusively for Android in an immersive landscape layout, Dashburdz transforms your device into a futuristic instrument cluster. It fetches real-time data from OBD-II (ELM327) BLE modules and renders beautiful, buttery-smooth pseudo-3D gauges, dynamic grid layouts, and context-aware riding modes.

---

## 📸 Core Capabilities

### Dynamic Riding Modes
Dashburdz features a reactive `TileGrid` architecture that seamlessly morphs and animates dashboard elements into different configurations based on the current context:
- ❄️ **Cold Engine / Warmup**: Prioritizes engine health metrics (Oil Temp, Intake Temp) with precise diagnostics while the vehicle reaches optimal operating temperatures.
- 🛣️ **Normal**: A balanced layout for everyday commuting, offering symmetrical RPM and Speed gauges with music integration.
- 🔥 **Power**: Aggressive, track-focused layout. The RPM gauge scales up to a massive `hero` tile, maximizing focus on shifts and throttle response.
- 🏞️ **Touring**: Minimalist layout emphasizing speed, a large clock, and media controls for long-range cruising.

### Holographic Engine Visualization
At the heart of the dashboard is a **pseudo-3D animated engine block** rendered entirely using `CustomPainter`:
- **Accelerometer-Driven Parallax**: The engine actively tilts and responds to your device's gyroscope/accelerometer, creating a stunning holographic depth effect using `Matrix4` transformations.
- **Real-time Synchronization**: The internal piston animates strictly in sync with the live RPM feed, while the cylinder glows dynamically based on Engine Load.

### Advanced Rendering & Shaders
- **Zero-Wrap Swept Gradients**: RPM and Speed arc gauges utilize complex `GradientRotation` and raw canvas manipulation to render flawless, artifact-free gradient sweeps (e.g., Lavender to Redline) without running into traditional Flutter 2π wrapping limitations.
- **Flexible Tile System**: Every metric widget (Gauges, Clocks, Media) can fluidly adapt to 5 distinct physical form factors (`chip`, `square`, `wide`, `tall`, `hero`) depending on the active riding mode. 

### Telemetry & Integration
- **BLE OBD-II Connectivity**: Streams raw hexadecimal telemetry from ELM327 Bluetooth Low Energy dongles, decoding critical PIDs (0x0C for RPM, 0x0D for Speed, etc.) with minimal latency.
- **Media Controls**: Integrated music tile with a live animated audio visualizer and real-time album art fetched dynamically via the iTunes API.

---

## 🛠️ Tech Stack & Architecture

- **Framework**: Flutter (Dart)
- **State Management**: [Riverpod](https://riverpod.dev/) for robust, testable, and reactive state injection.
- **Hardware Integration**: `flutter_blue_plus` for BLE communication and `sensors_plus` for accelerometer-based UI parallax.
- **Architecture Pattern**:
  - **Services Layer**: Pure Dart BLE communication and raw OBD-II frame parsing.
  - **Provider Layer**: Riverpod Notifiers that map raw OBD bytes into human-readable `VehicleData` state models, handling fallback simulation loops when hardware isn't present.
  - **Presentation Layer**: Highly granular, stateless UI components wrapped in a constraint-aware `LayoutBuilder` grid.

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- An Android Device (Emulators can be used, but lack hardware BLE/accelerometer capabilities for testing full functionality).
- (Optional) An ELM327 BLE OBD-II dongle for live vehicle telemetry.

### Installation & Run

1. **Clone the repository:**
   ```bash
   git clone https://github.com/psycoxer/Dashburdz.git
   cd Dashburdz
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run on your Android device:**
   ```bash
   flutter run --release
   ```
   > **Note:** Dashburdz enforces an immersive, edge-to-edge landscape orientation. Running in Release mode is highly recommended to experience the 60/120fps CustomPainter animations optimally.

---

## 📐 Design Philosophy

Dashburdz strictly avoids "griddish", boxy constraints. Inspired by modern hypercar interfaces and Apple's fluid design language, every tile scales organically. Components never clip; they scale down elegantly using advanced `FittedBox` mathematics, and transition seamlessly across riding modes using staggered, cubic-ease animation curves. 

Colors prioritize a rich, cyberpunk-inspired palette—deep space backgrounds, glowing lavenders, sage greens, and piercing redlines—ensuring minimal eye strain during night riding while retaining daylight visibility.

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
