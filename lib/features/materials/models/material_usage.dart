class MaterialUsage {
  final String siteId;
  final String materialName;
  final double quantity;
  final String unit;
  final DateTime reportingDate;
  final DateTime recordedAt;

  const MaterialUsage({
    required this.siteId,
    required this.materialName,
    required this.quantity,
    required this.unit,
    required this.reportingDate,
    required this.recordedAt,
  });
}
