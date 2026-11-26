/// Compile-time environment configuration for Supabase cloud sync.
const String kDefaultSupabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: '',
);

const String kDefaultSupabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: '',
);

/// Runtime configuration holding Supabase endpoint and public anon key.
class SupabaseRuntimeConfig {
  const SupabaseRuntimeConfig({
    required this.url,
    required this.anonKey,
  });

  final String url;
  final String anonKey;

  /// Normalizes the Supabase URL to its origin, stripping `/rest/v1` or trailing slashes.
  String get normalizedUrl {
    final trimmed = url.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return trimmed;
    return uri.origin;
  }

  bool get isConfigured {
    final trimmedUrl = url.trim();
    final trimmedKey = anonKey.trim();
    if (trimmedUrl.isEmpty || trimmedKey.isEmpty) return false;
    final uri = Uri.tryParse(trimmedUrl);
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
  }

  Map<String, dynamic> toJson() => {
        'url': normalizedUrl,
        'anonKey': anonKey.trim(),
      };

  factory SupabaseRuntimeConfig.fromJson(Map<String, dynamic> json) {
    return SupabaseRuntimeConfig(
      url: json['url'] as String? ?? '',
      anonKey: json['anonKey'] as String? ?? '',
    );
  }

  static SupabaseRuntimeConfig? fromEnvironmentOrNull() {
    const envConfig = SupabaseRuntimeConfig(
      url: kDefaultSupabaseUrl,
      anonKey: kDefaultSupabaseAnonKey,
    );
    return envConfig.isConfigured ? envConfig : null;
  }
}
