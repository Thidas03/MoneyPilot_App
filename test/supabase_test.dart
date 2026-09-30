import 'package:flutter_test/flutter_test.dart';
import 'package:moneypilot/core/supabase/supabase_config.dart';
import 'package:moneypilot/core/supabase/supabase_service.dart';

void main() {
  group('SupabaseConfig & SupabaseService tests', () {
    tearDown(() {
      SupabaseConfig.reset();
      SupabaseService.instance.resetForTesting();
    });

    test('SupabaseConfig: defaults to unconfigured in test environment', () {
      expect(SupabaseConfig.isConfigured, isFalse);
      expect(SupabaseConfig.maskedAnonKey, equals('(empty)'));
    });

    test('SupabaseConfig: detects placeholders and flags as unconfigured', () {
      SupabaseConfig.setCredentials(
        url: 'https://your-project-id.supabase.co',
        anonKey: 'your-anon-publishable-key-here',
      );
      expect(SupabaseConfig.isConfigured, isFalse);
    });

    test('SupabaseConfig: valid credentials mark isConfigured as true and mask anon key', () {
      SupabaseConfig.setCredentials(
        url: 'https://abcdefgh.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.abcdef123456',
      );
      expect(SupabaseConfig.isConfigured, isTrue);
      expect(SupabaseConfig.url, equals('https://abcdefgh.supabase.co'));
      expect(SupabaseConfig.publishableKey, equals(SupabaseConfig.anonKey));
      expect(SupabaseConfig.maskedAnonKey.startsWith('eyJhbG...'), isTrue);
      expect(SupabaseConfig.maskedAnonKey.endsWith('3456'), isTrue);
    });

    test('SupabaseService: graceful offline/mock fallback when credentials missing', () async {
      final service = SupabaseService.instance;
      expect(service.isInitialized, isFalse);
      expect(service.client, isNull);

      // Must not throw when unconfigured
      await service.initialize();

      expect(service.isInitialized, isFalse);
      expect(service.client, isNull);
    });
  });
}
