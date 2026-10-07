class SafetyIncident {
  final String siteId;
  final String description;
  final String location;
  final String severity;
  final DateTime occurredAt;
  final DateTime recordedAt;

  const SafetyIncident({
    required this.siteId,
    required this.description,
    required this.location,
    required this.severity,
    required this.occurredAt,
    required this.recordedAt,
  });
}