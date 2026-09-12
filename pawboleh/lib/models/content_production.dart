/// Lifecycle states returned by the campaign-generation API.
enum ContentProductionStatus { pending, generating, completed, failed, unknown }

extension ContentProductionStatusX on ContentProductionStatus {
  String get label => switch (this) {
        ContentProductionStatus.pending => 'Queued',
        ContentProductionStatus.generating => 'Generating',
        ContentProductionStatus.completed => 'Complete',
        ContentProductionStatus.failed => 'Needs attention',
        ContentProductionStatus.unknown => 'Unknown',
      };

  static ContentProductionStatus fromWire(String value) => switch (value) {
        'pending' => ContentProductionStatus.pending,
        'generating' => ContentProductionStatus.generating,
        'completed' => ContentProductionStatus.completed,
        'failed' => ContentProductionStatus.failed,
        _ => ContentProductionStatus.unknown,
      };
}

/// Payload used to start a generated marketing campaign.
class CreateContentProductionRequest {
  const CreateContentProductionRequest({
    required this.productName,
    required this.productDescription,
    this.productImageUrl,
    this.targetAudience,
  });

  final String productName;
  final String productDescription;
  final String? productImageUrl;
  final String? targetAudience;

  Map<String, Object> toJson() {
    final result = <String, Object>{
      'product_name': productName,
      'product_description': productDescription,
    };
    if (productImageUrl != null && productImageUrl!.trim().isNotEmpty) {
      result['product_image_url'] = productImageUrl!.trim();
    }
    if (targetAudience != null && targetAudience!.trim().isNotEmpty) {
      result['target_audience'] = targetAudience!.trim();
    }
    return result;
  }
}

/// A campaign and its generated copy and media assets.
class ContentProduction {
  const ContentProduction({
    required this.id,
    required this.productName,
    required this.productDescription,
    required this.status,
    required this.createdAt,
    this.productImageUrl,
    this.marketingConcept,
    this.headline,
    this.tagline,
    this.callToAction,
    this.targetAudience,
    this.posterUrl,
    this.videoUrl,
    this.errorMessage,
  });

  final String id;
  final String productName;
  final String productDescription;
  final String? productImageUrl;
  final String? marketingConcept;
  final String? headline;
  final String? tagline;
  final String? callToAction;
  final String? targetAudience;
  final String? posterUrl;
  final String? videoUrl;
  final ContentProductionStatus status;
  final String? errorMessage;
  final DateTime? createdAt;

  bool get isInProgress =>
      status == ContentProductionStatus.pending ||
      status == ContentProductionStatus.generating;

  factory ContentProduction.fromJson(Map<String, dynamic> json) {
    final createdAtValue = _string(json['created_at']);
    return ContentProduction(
      id: _string(json['id']) ?? '',
      productName: _string(json['product_name']) ?? 'Untitled product',
      productDescription: _string(json['product_description']) ?? '',
      productImageUrl: _string(json['product_image_url']),
      marketingConcept: _string(json['marketing_concept']),
      headline: _string(json['headline']),
      tagline: _string(json['tagline']),
      callToAction: _string(json['call_to_action']),
      targetAudience: _string(json['target_audience']),
      posterUrl: _string(json['poster_url']),
      videoUrl: _string(json['video_url']),
      status: ContentProductionStatusX.fromWire(
        _string(json['status'])?.toLowerCase() ?? '',
      ),
      errorMessage: _string(json['error_message']),
      createdAt: createdAtValue == null ? null : DateTime.tryParse(createdAtValue),
    );
  }

  static String? _string(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
