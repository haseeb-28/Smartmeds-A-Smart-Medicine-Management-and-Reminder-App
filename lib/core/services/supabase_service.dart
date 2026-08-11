import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles Supabase initialization and gives easy access
/// to the client from anywhere in the app.
class SupabaseService {
  SupabaseService._();

  // Replace these with environment-backed Supabase credentials in production.
  // Do not commit real keys to source control.
  static const String supabaseUrl = 'https://hrngsgvyvphuyqabnytl.supabase.co';
  static const String supabasePublishableKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhybmdzZ3Z5dnBodXlxYWJueXRsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQzOTQ4MDYsImV4cCI6MjA5OTk3MDgwNn0.B_YubQYgiQUcr3cMsVlRygUatisSvunlLt6KN81_uqI';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => Supabase.instance.client.auth;
}
