import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  late final SupabaseClient client;

  factory SupabaseService() => _instance;

  SupabaseService._internal();

  Future<void> init() async {
    await Supabase.initialize(
      url: 'https://YOUR_PROJECT_URL.supabase.co', 
      anonKey: 'YOUR_ANON_KEY', 
    );

    client = Supabase.instance.client;
  }

  /// Lấy client để thao tác Supabase ở các nơi khác
  SupabaseClient get supabase => client;
}
