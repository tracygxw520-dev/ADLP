import 'package:flutter_test/flutter_test.dart';
import 'package:pawboleh/models/content_production.dart';

void main() {
  test('parses a partial visual result with a poster and no video', () {
    final production = ContentProduction.fromJson({
      'id': 'campaign-123',
      'product_name': 'Canvas tote',
      'product_description': 'A light everyday tote bag.',
      'status': 'partial',
      'poster_url': '/assets/campaign-123-poster.png',
      'error_message': 'The promo video was blocked by safety moderation.',
    });

    expect(production.status, ContentProductionStatus.partial);
    expect(production.posterUrl, '/assets/campaign-123-poster.png');
    expect(production.videoUrl, isNull);
    expect(production.isInProgress, isFalse);
  });
}
