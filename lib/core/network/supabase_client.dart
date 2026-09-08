import 'package:supabase_flutter/supabase_flutter.dart';

/// The one Supabase client every `*_api.dart` file talks through.
///
/// `Supabase.instance.client` is already a shared, singleton, once-configured
/// client covering Postgrest (data), Auth, Realtime, Storage and Edge
/// Function invocation — this is CLAUDE.md §9's "one shared client" rule,
/// reinterpreted per plan 005's Assumption #1: no feature ever instantiates
/// its own client.
SupabaseClient get supabase => Supabase.instance.client;
