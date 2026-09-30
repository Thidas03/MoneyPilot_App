import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/supabase/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase client if environment credentials are present.
  await SupabaseService.instance.initialize();

  runApp(
    const ProviderScope(
      child: MoneyPilotApp(),
    ),
  );
}
