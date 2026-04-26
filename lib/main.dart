import 'package:flutter/material.dart';
import 'app/trip_central_app.dart';
import 'core/patterns/singleton/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseService.instance.initialize();

  runApp(const TripCentralApp());
}
