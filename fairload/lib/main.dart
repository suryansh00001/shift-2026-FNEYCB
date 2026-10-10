import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/shift_ledger_provider.dart';
import 'presentation/providers/telemetry_provider.dart';
import 'presentation/screens/main_shell_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FairLoadApp());
}

class FairLoadApp extends StatelessWidget {
  const FairLoadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TelemetryProvider()),
        ChangeNotifierProvider(create: (_) => ShiftLedgerProvider()),
      ],
      child: MaterialApp(
        title: 'FairLoad — EV Micromobility Defense',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainShellScreen(),
      ),
    );
  }
}
