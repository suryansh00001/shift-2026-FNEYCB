# FairLoad — Flutter Application

> Physics-Bounded EV Micromobility & Overload Defense Engine  
> IIT (BHU) Varanasi · SHIFT Hackathon 2026

For the complete project overview, technical architecture, and research documentation, please see the [Root README](../README.md) and the [Academic Case Study](../FAIRLOAD_CASE_STUDY.md).

## Quick Start

```bash
# Get dependencies
flutter pub get

# Run test suite (Physics balance, Battery Joule heating, LFP vs NMC chemistry)
flutter test

# Run code analyzer
flutter analyze

# Run Flutter app
flutter run
```

## Key Engine Features

1. **Cockpit HUD (`lib/presentation/screens/hud_screen.dart`)**: Real-time 270° C-rate tachometer, cell temperature, dynamic ₹ asset wear tracking, and NeuroPace™ predictive advisory.
2. **Vehicle & Battery Chemistry Configurator (`lib/presentation/widgets/vehicle_battery_selector_sheet.dart`)**: Switch between 4 battery chemistry profiles (NMC 20Ah, NMC 26Ah, LFP 30Ah, NMC 15Ah) and 3 commercial vehicle frame presets.
3. **Live Sensor Service (`lib/services/live_sensor_service.dart`)**: Madgwick/Complementary filtering, Varanasi pothole rejection filter ($>14\text{ m/s}^3$), and reverse mass estimation.
4. **GPS Weather Sync (`lib/services/weather_service.dart`)**: Real-time outdoor air temperature syncing via Open-Meteo API using device coordinates.
5. **Corridor Stress Simulator (`lib/presentation/screens/simulator_screen.dart`)**: Pre-mapped GPS/elevation traces for Chowkaghat Flyover, Cantt Overbridge, and Lanka Gallis.
6. **Defense Slip Generator (`lib/services/pdf_slip_service.dart`)**: Cryptographically verifiable legal dispute PDF citing Section 56 of the Indian Contract Act, 1872.
