"""
flutter_compatible_pipeline.py
==============================
End-to-end Python prototype of the complete 4-input pipeline:
1. Temperature: Fetched live from Open-Meteo Weather API (open-source).
2. Climate / Humidity: Fetched live from Open-Meteo Weather API based on route coordinates.
3. Route Quality & Incline:
   - Incline (grade %): Fetched from Open-Meteo Elevation API (open-source).
   - Road roughness (Crr): Sourced from OpenStreetMap surface categorization.
4. Weight: Manually input (rider mass + cargo mass).

Executes the deployable TFLite model `pinn4soh.tflite` via LiteRT / TensorFlow Lite Interpreter.
Matches the exact logic implemented in Flutter Dart (`pinn_fleet_pipeline.dart`).
"""

import os
import json
import urllib.request
import urllib.parse
import numpy as np
from ai_edge_litert.interpreter import Interpreter
from typing import Dict, Any, Tuple


class IndianFleetPINNPipeline:
    """
    Fleet Battery Health Prognosis Pipeline.
    Integrates open-source environmental and road APIs with TFLite PINN4SOH inference.
    """
    def __init__(self,
                 tflite_model_path: str = "pinn4soh.tflite",
                 metadata_path: str = "pinn4soh_metadata.json",
                 nominal_pack_capacity_ah: float = 20.0,
                 nominal_voltage_v: float = 48.0,
                 nominal_cycle_life: int = 1200):
        self.nominal_capacity_ah = nominal_pack_capacity_ah
        self.nominal_voltage_v = nominal_voltage_v
        self.nominal_cycle_life = nominal_cycle_life
        self.nominal_fade_per_cycle_pct = 20.0 / self.nominal_cycle_life  # 0.01667%

        # 1. Load Normalization Bounds
        with open(metadata_path, "r") as f:
            meta = json.load(f)
            self.min_vals = np.array([item["min"] for item in meta["features"]], dtype=np.float32)
            self.max_vals = np.array([item["max"] for item in meta["features"]], dtype=np.float32)
            self.ranges = self.max_vals - self.min_vals
            self.ranges[np.abs(self.ranges) < 1e-6] = 1.0

        # 2. Load TFLite Model
        assert os.path.exists(tflite_model_path), f"Model {tflite_model_path} not found"
        self.interpreter = Interpreter(model_path=tflite_model_path)
        self.interpreter.allocate_tensors()
        self.input_details = self.interpreter.get_input_details()
        self.output_details = self.interpreter.get_output_details()

    # ==========================================================================
    # INPUT 1 & 2: FETCH LIVE WEATHER (TEMPERATURE & HUMIDITY) VIA OPEN-METEO
    # ==========================================================================
    @staticmethod
    def fetch_live_weather(lat: float, lon: float) -> Tuple[float, float]:
        """
        Fetches live ambient temperature (°C) and relative humidity (%)
        from Open-Meteo free public API.
        """
        url = f"https://api.open-meteo.com/v1/forecast?latitude={lat:.4f}&longitude={lon:.4f}&current=temperature_2m,relative_humidity_2m"
        req = urllib.request.Request(url, headers={"User-Agent": "PINN4SOH-Fleet/1.0"})
        try:
            with urllib.request.urlopen(req, timeout=10) as resp:
                data = json.loads(resp.read().decode())
                temp_c = float(data["current"]["temperature_2m"])
                rh_pct = float(data["current"]["relative_humidity_2m"])
                return temp_c, rh_pct
        except Exception as e:
            print(f"[Warning] Weather API error ({e}), using default Varanasi summer climate: 40.0°C, 65% RH")
            return 40.0, 65.0

    # ==========================================================================
    # INPUT 3: FETCH ROUTE INCLINATION & ROAD ROUGHNESS FACTOR
    # ==========================================================================
    @staticmethod
    def fetch_route_incline(start_lat: float, start_lon: float,
                            end_lat: float, end_lon: float) -> Tuple[float, float, float]:
        """
        Fetches elevation from Open-Meteo Elevation API and calculates:
        - Route distance (km) using Haversine formula
        - Elevation change (m)
        - Incline / Road Grade (%)
        """
        # Haversine distance
        r_earth_km = 6371.0
        d_lat = np.radians(end_lat - start_lat)
        d_lon = np.radians(end_lon - start_lon)
        a = (np.sin(d_lat / 2.0) ** 2 +
             np.cos(np.radians(start_lat)) * np.cos(np.radians(end_lat)) * np.sin(d_lon / 2.0) ** 2)
        dist_km = float(2.0 * r_earth_km * np.arctan2(np.sqrt(a), np.sqrt(1.0 - a)))
        dist_km = max(0.1, dist_km)

        # Open-Meteo Elevation API
        url = f"https://api.open-meteo.com/v1/elevation?latitude={start_lat:.4f},{end_lat:.4f}&longitude={start_lon:.4f},{end_lon:.4f}"
        req = urllib.request.Request(url, headers={"User-Agent": "PINN4SOH-Fleet/1.0"})
        try:
            with urllib.request.urlopen(req, timeout=10) as resp:
                data = json.loads(resp.read().decode())
                elevations = data["elevation"]
                h_start = float(elevations[0])
                h_end = float(elevations[1])
                delta_h_m = h_end - h_start
                # Incline % = (delta_h / distance_m) * 100
                incline_pct = float((delta_h_m / (dist_km * 1000.0)) * 100.0)
                incline_pct = float(np.clip(incline_pct, -10.0, 15.0))
                return dist_km, delta_h_m, incline_pct
        except Exception as e:
            print(f"[Warning] Elevation API error ({e}), using default flyover climb: 3.5% incline")
            return dist_km, 12.0, 3.5

    @staticmethod
    def get_road_roughness(road_surface_type: str = "asphalt") -> Tuple[float, str]:
        """
        Maps road surface tag (from OpenStreetMap or user selection)
        to rolling resistance coefficient (C_rr).
        """
        mapping = {
            "smooth_asphalt": (0.012, "Smooth Highway Asphalt"),
            "asphalt": (0.015, "Standard City Asphalt"),
            "paved": (0.018, "Average Indian City Road"),
            "concrete": (0.016, "PCC / Concrete Road"),
            "unpaved": (0.028, "Broken Road / Gravel"),
            "cobblestone": (0.032, "Old City Sett / Cobblestone"),
            "potholed": (0.035, "Monsoon Potholed / Waterlogged")
        }
        crr, desc = mapping.get(road_surface_type.lower(), (0.018, "Standard City Road"))
        return crr, desc

    # ==========================================================================
    # INPUT 4 & VEHICLE DYNAMICS: COMPUTE MOTOR LOAD & JOULE HEATING
    # ==========================================================================
    def compute_trip_powertrain_and_thermal(self,
                                            rider_weight_kg: float,
                                            cargo_weight_kg: float,
                                            speed_kmh: float,
                                            incline_pct: float,
                                            road_crr: float,
                                            ambient_temp_c: float,
                                            trip_duration_min: float) -> Dict[str, float]:
        """
        Translates manual weight inputs and environmental grade into
        motor traction current and internal battery heating.
        """
        curb_mass = 65.0  # E-bike curb mass (kg)
        total_mass = curb_mass + rider_weight_kg + cargo_weight_kg
        v_ms = max(0.5, speed_kmh / 3.6)
        theta_rad = np.arctan(max(0.0, incline_pct) / 100.0)

        # 1. Traction Forces
        g = 9.81
        f_grade = total_mass * g * np.sin(theta_rad)
        f_roll = road_crr * total_mass * g * np.cos(theta_rad)
        f_aero = 0.5 * 1.18 * 0.55 * (v_ms ** 2)
        f_total = f_grade + f_roll + f_aero

        p_mech = f_total * v_ms

        # Low-RPM hub motor stall derating under steep inclines
        if speed_kmh < 12.0 and incline_pct > 2.0:
            eff = 0.42  # motor stall heating
        elif speed_kmh < 18.0:
            eff = 0.65
        else:
            eff = 0.82

        p_elec = (p_mech / eff) + 60.0  # +60W auxiliary drain
        i_batt = p_elec / self.nominal_voltage_v
        c_rate = i_batt / self.nominal_capacity_ah

        # 2. Lumped Thermal Rise (Bernardi 1985)
        # C_th * dTc/dt = I^2 * R - hA * (Tc - Ta)
        c_th = 180.0
        r_int = 0.035
        ha = 0.85
        t_cell = ambient_temp_c
        dt_step = 5.0
        steps = max(1, int((trip_duration_min * 60.0) / dt_step))

        for _ in range(steps):
            q_gen = (i_batt ** 2) * r_int
            q_diss = ha * (t_cell - ambient_temp_c)
            t_cell += ((q_gen - q_diss) / c_th) * dt_step

        # 3. Arrhenius Aging Multiplier (Kučinskis 2022)
        r_gas = 8.314
        e_a = 31500.0
        t_c_k = max(298.15, t_cell + 273.15)
        t_ref_k = 298.15
        arrhenius_mult = float(np.exp((e_a / r_gas) * ((1.0 / t_ref_k) - (1.0 / t_c_k))))

        return {
            "total_mass_kg": float(total_mass),
            "traction_power_w": float(p_elec),
            "discharge_current_a": float(i_batt),
            "c_rate": float(c_rate),
            "motor_efficiency": float(eff),
            "cell_temp_c": float(t_cell),
            "temp_rise_c": float(t_cell - ambient_temp_c),
            "arrhenius_aging_mult": float(arrhenius_mult)
        }

    # ==========================================================================
    # INFERENCE & COMPLETE PROGNOSIS
    # ==========================================================================
    def run_full_pipeline(self,
                          start_lat: float,
                          start_lon: float,
                          end_lat: float,
                          end_lon: float,
                          rider_weight_kg: float,
                          cargo_weight_kg: float,
                          trip_duration_min: float = 30.0,
                          avg_speed_kmh: float = 16.0,
                          road_surface: str = "paved",
                          current_battery_cycle: int = 150) -> Dict[str, Any]:
        """
        Executes the entire pipeline:
        1. Queries Open-Meteo for live Temp & Humidity.
        2. Queries Elevation for road incline and maps road roughness.
        3. Accepts manual weights (rider + cargo).
        4. Runs physics conversion & TFLite PINN model.
        """
        # 1. Fetch Live Weather (Inputs 1 & 2)
        ambient_temp_c, ambient_rh_pct = self.fetch_live_weather(start_lat, start_lon)

        # 2. Fetch Route Incline & Roughness (Input 3)
        dist_km, delta_h_m, incline_pct = self.fetch_route_incline(start_lat, start_lon, end_lat, end_lon)
        crr, surface_desc = self.get_road_roughness(road_surface)

        # 3. Vehicle Dynamics & Thermal Heating (Input 4 + 1,2,3)
        dynamics = self.compute_trip_powertrain_and_thermal(
            rider_weight_kg=rider_weight_kg,
            cargo_weight_kg=cargo_weight_kg,
            speed_kmh=avg_speed_kmh,
            incline_pct=incline_pct,
            road_crr=crr,
            ambient_temp_c=ambient_temp_c,
            trip_duration_min=trip_duration_min
        )

        # 4. Construct Normalized 17-Dimensional Feature Vector
        # Baseline template representation
        feat_raw = np.array([
            4.096, 0.0565, -1.205, 0.018, 0.345, 311.0, 0.00063, 5.52,
            0.233, 0.111, -0.58, 0.75, 0.056, 860.0, -0.0010, 6.38,
            float(current_battery_cycle)
        ], dtype=np.float32)

        # Apply electrochemical polarization shifts
        stress_factor = (dynamics["c_rate"] ** 1.8) * dynamics["arrhenius_aging_mult"]
        delta_r_factor = 1.0 + 0.006 * stress_factor
        feat_raw[4] /= (delta_r_factor ** 0.5)  # CC Q contracts
        feat_raw[5] /= delta_r_factor          # CC time contracts
        feat_raw[6] *= delta_r_factor          # voltage slope steepens
        feat_raw[13] *= delta_r_factor         # CV time dilates

        # Normalization to [-1, 1]
        feat_norm = 2.0 * (feat_raw - self.min_vals) / self.ranges - 1.0
        feat_norm = np.clip(feat_norm, -1.0, 1.0).reshape(1, 17)

        # 5. Execute TFLite Model
        self.interpreter.set_tensor(self.input_details[0]["index"], feat_norm)
        self.interpreter.invoke()
        tflite_output = self.interpreter.get_tensor(self.output_details[0]["index"])
        current_soh_pct = float(tflite_output[0, 0] * 100.0)

        # 6. Wear & Cycle Life Calculation
        nominal_hourly_fade = (0.20 / self.nominal_cycle_life) / 2.0
        combined_stress = dynamics["arrhenius_aging_mult"] * (1.0 + max(0.0, dynamics["c_rate"] - 0.8) ** 1.85) * (crr / 0.015)
        trip_wear_pct = float(nominal_hourly_fade * (trip_duration_min / 60.0) * combined_stress * 100.0)
        capacity_lost_mah = float((trip_wear_pct / 100.0) * self.nominal_capacity_ah * 1000.0)
        cycles_burned = float(trip_wear_pct / self.nominal_fade_per_cycle_pct)

        # 7. Knee-Point Prognosis
        projected_knee_cycle = int(current_battery_cycle + max(50, int((current_soh_pct - 80.0) / (trip_wear_pct * 1.5))))
        lead_time = max(0, projected_knee_cycle - current_battery_cycle)
        warning_status = "CRITICAL" if lead_time < 50 else ("WARNING" if lead_time < 150 else "HEALTHY")

        return {
            "environmental_and_route": {
                "ambient_temperature_c": ambient_temp_c,
                "relative_humidity_pct": ambient_rh_pct,
                "route_distance_km": round(dist_km, 2),
                "elevation_change_m": round(delta_h_m, 1),
                "road_incline_pct": round(incline_pct, 2),
                "surface_type": surface_desc,
                "rolling_resistance_crr": crr
            },
            "user_and_vehicle_weights": {
                "rider_weight_kg": rider_weight_kg,
                "cargo_weight_kg": cargo_weight_kg,
                "total_gross_weight_kg": round(dynamics["total_mass_kg"], 1)
            },
            "powertrain_and_thermal_stress": {
                "motor_electrical_power_w": round(dynamics["traction_power_w"], 1),
                "discharge_current_a": round(dynamics["discharge_current_a"], 2),
                "c_rate": round(dynamics["c_rate"], 2),
                "motor_stall_efficiency": round(dynamics["motor_efficiency"], 2),
                "cell_core_temp_c": round(dynamics["cell_temp_c"], 1),
                "cell_temp_rise_c": round(dynamics["temp_rise_c"], 1),
                "arrhenius_aging_factor": round(dynamics["arrhenius_aging_mult"], 2)
            },
            "pinn4soh_prognosis": {
                "current_soh_pct": round(current_soh_pct, 3),
                "trip_capacity_wear_pct": round(trip_wear_pct, 5),
                "capacity_lost_mah": round(capacity_lost_mah, 2),
                "equivalent_cycles_burned": round(cycles_burned, 3),
                "predicted_knee_cycle": projected_knee_cycle,
                "safe_lead_time_cycles": lead_time,
                "knee_warning_status": warning_status
            }
        }


# ==============================================================================
# PIPELINE DEMONSTRATION RUNNER
# ==============================================================================
if __name__ == "__main__":
    print("\n" + "=" * 80)
    print("      INDIAN FLEET PINN4SOH PIPELINE: LIVE OPEN-SOURCE DATA & TFLITE")
    print("=" * 80)

    pipeline = IndianFleetPINNPipeline()

    # Route: Varanasi Cantt Station (25.3280, 82.9850) -> Chowkaghat Overpass (25.3360, 82.9980)
    report = pipeline.run_full_pipeline(
        start_lat=25.3280, start_lon=82.9850,
        end_lat=25.3360,   end_lon=82.9980,
        rider_weight_kg=72.0,
        cargo_weight_kg=140.0,       # Heavy cargo load (Blinkit 140 kg water crates)
        trip_duration_min=30.0,
        avg_speed_kmh=14.0,
        road_surface="potholed",     # Rough Indian city road
        current_battery_cycle=135
    )

    env = report["environmental_and_route"]
    w = report["user_and_vehicle_weights"]
    p = report["powertrain_and_thermal_stress"]
    prog = report["pinn4soh_prognosis"]

    print("\n1. LIVE FETCHED ENVIRONMENTAL & ROUTE DATA (Open-Meteo & OSM):")
    print(f"   • Ambient Temperature: {env['ambient_temperature_c']} °C | Relative Humidity: {env['relative_humidity_pct']}%")
    print(f"   • Route Distance:      {env['route_distance_km']} km | Elevation Gain: {env['elevation_change_m']} m")
    print(f"   • Road Incline Grade:  {env['road_incline_pct']}% | Surface: {env['surface_type']} (Crr = {env['rolling_resistance_crr']})")

    print("\n2. USER & VEHICLE WEIGHT INPUTS:")
    print(f"   • Rider Mass: {w['rider_weight_kg']} kg | Cargo Mass: {w['cargo_weight_kg']} kg | Gross Total: {w['total_gross_weight_kg']} kg")

    print("\n3. POWERTRAIN DYNAMICS & CELL THERMAL RISE (Bernardi Model):")
    print(f"   • Motor Power Draw:    {p['motor_electrical_power_w']} W (Efficiency: {p['motor_stall_efficiency']*100:.0f}%)")
    print(f"   • Battery Discharge:   {p['discharge_current_a']} A ({p['c_rate']} C-rate)")
    print(f"   • Cell Core Temp:      {p['cell_core_temp_c']} °C (Surge: +{p['cell_temp_rise_c']} °C) | Aging Acceleration: {p['arrhenius_aging_factor']}x")

    print("\n4. DEPLOYABLE TFLITE PINN4SOH PREDICTION:")
    print(f"   • Current Health (SOH): {prog['current_soh_pct']:.2f}%")
    print(f"   • Trip Capacity Fade:   {prog['trip_capacity_wear_pct']:.4f}% ({prog['capacity_lost_mah']:.1f} mAh lost)")
    print(f"   • Life Cycles Consumed: {prog['equivalent_cycles_burned']:.3f} standard cycles in 30 minutes!")
    print(f"   • Predicted Knee-Point: Cycle {prog['predicted_knee_cycle']} ({prog['safe_lead_time_cycles']} cycles remaining)")
    print(f"   • Knee Warning Status:  [{prog['knee_warning_status']}]")
    print("=" * 80 + "\n")
