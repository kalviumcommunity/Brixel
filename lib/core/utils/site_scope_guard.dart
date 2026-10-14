class SiteScopeGuard {
  const SiteScopeGuard._();

  static void validate({
    required String activeSiteId,
    required String recordSiteId,
  }) {
    if (activeSiteId.trim().isEmpty) {
      throw ArgumentError('Active site ID cannot be empty.');
    }

    if (recordSiteId.trim().isEmpty) {
      throw ArgumentError('Record site ID cannot be empty.');
    }

    if (activeSiteId != recordSiteId) {
      throw ArgumentError(
        'Cannot write a record for a different construction site.',
      );
    }
  }
}
