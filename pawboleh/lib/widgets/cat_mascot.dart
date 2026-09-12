import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// What the cat mascot is holding — mirrors the tool each screen represents.
enum CatProp { mic, camera, none }

/// A cute, fully vector cat mascot drawn with [CustomPainter]. No image
/// assets required, so it scales crisply at any size and adapts easily
/// (swap [furColor] per brand, swap [prop] per screen).
///
/// Used on the Dashboard's "Paw Live" (holding a mic) and "Paw Snap"
/// (holding a camera) navigation cards.
class CatMascot extends StatelessWidget {
  const CatMascot({
    super.key,
    this.size = 56,
    this.prop = CatProp.none,
    this.furColor = AppColors.catFur,
  });

  final double size;
  final CatProp prop;
  final Color furColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: switch (prop) {
        CatProp.mic => 'Cat mascot holding a microphone',
        CatProp.camera => 'Cat mascot holding a camera',
        CatProp.none => 'Cat mascot',
      },
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _CatMascotPainter(prop: prop, furColor: furColor),
        ),
      ),
    );
  }
}

class _CatMascotPainter extends CustomPainter {
  _CatMascotPainter({required this.prop, required this.furColor});

  final CatProp prop;
  final Color furColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h * 0.58);
    final headRadius = w * 0.30;

    final furPaint = Paint()..color = furColor;
    final inkPaint = Paint()..color = AppColors.catInk;
    final blushPaint = Paint()..color = AppColors.catBlush.withValues(alpha: 0.8);
    final whitePaint = Paint()..color = Colors.white;

    // Ears
    final earPath = Path()
      ..moveTo(center.dx - headRadius * 0.9, center.dy - headRadius * 0.4)
      ..lineTo(center.dx - headRadius * 0.35, center.dy - headRadius * 1.55)
      ..lineTo(center.dx - headRadius * 0.05, center.dy - headRadius * 0.55)
      ..close();
    final earPathRight = Path()
      ..moveTo(center.dx + headRadius * 0.9, center.dy - headRadius * 0.4)
      ..lineTo(center.dx + headRadius * 0.35, center.dy - headRadius * 1.55)
      ..lineTo(center.dx + headRadius * 0.05, center.dy - headRadius * 0.55)
      ..close();
    canvas.drawPath(earPath, furPaint);
    canvas.drawPath(earPathRight, furPaint);

    // Inner ears
    final innerEarPaint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - headRadius * 0.62, center.dy - headRadius * 0.55)
        ..lineTo(center.dx - headRadius * 0.35, center.dy - headRadius * 1.1)
        ..lineTo(center.dx - headRadius * 0.18, center.dy - headRadius * 0.62)
        ..close(),
      innerEarPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(center.dx + headRadius * 0.62, center.dy - headRadius * 0.55)
        ..lineTo(center.dx + headRadius * 0.35, center.dy - headRadius * 1.1)
        ..lineTo(center.dx + headRadius * 0.18, center.dy - headRadius * 0.62)
        ..close(),
      innerEarPaint,
    );

    // Head
    canvas.drawCircle(center, headRadius, furPaint);

    // Blush cheeks
    canvas.drawCircle(
      Offset(center.dx - headRadius * 0.62, center.dy + headRadius * 0.12),
      headRadius * 0.16,
      blushPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + headRadius * 0.62, center.dy + headRadius * 0.12),
      headRadius * 0.16,
      blushPaint,
    );

    // Eyes
    canvas.drawCircle(
      Offset(center.dx - headRadius * 0.34, center.dy - headRadius * 0.05),
      headRadius * 0.09,
      inkPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + headRadius * 0.34, center.dy - headRadius * 0.05),
      headRadius * 0.09,
      inkPaint,
    );

    // Nose + mouth
    final nose = Offset(center.dx, center.dy + headRadius * 0.18);
    canvas.drawOval(
      Rect.fromCenter(center: nose, width: headRadius * 0.16, height: headRadius * 0.1),
      inkPaint,
    );
    final mouthPaint = Paint()
      ..color = AppColors.catInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = headRadius * 0.05
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(nose.dx - headRadius * 0.12, nose.dy + headRadius * 0.08),
          width: headRadius * 0.28, height: headRadius * 0.22),
      0.2, 1.6, false, mouthPaint,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(nose.dx + headRadius * 0.12, nose.dy + headRadius * 0.08),
          width: headRadius * 0.28, height: headRadius * 0.22),
      1.35, 1.6, false, mouthPaint,
    );

    // Bow tie
    final bowCenter = Offset(center.dx, center.dy + headRadius * 1.0);
    canvas.drawPath(
      Path()
        ..moveTo(bowCenter.dx, bowCenter.dy)
        ..lineTo(bowCenter.dx - headRadius * 0.32, bowCenter.dy - headRadius * 0.18)
        ..lineTo(bowCenter.dx - headRadius * 0.32, bowCenter.dy + headRadius * 0.18)
        ..close(),
      Paint()..color = AppColors.liveRed,
    );
    canvas.drawPath(
      Path()
        ..moveTo(bowCenter.dx, bowCenter.dy)
        ..lineTo(bowCenter.dx + headRadius * 0.32, bowCenter.dy - headRadius * 0.18)
        ..lineTo(bowCenter.dx + headRadius * 0.32, bowCenter.dy + headRadius * 0.18)
        ..close(),
      Paint()..color = AppColors.liveRed,
    );
    canvas.drawCircle(bowCenter, headRadius * 0.09, Paint()..color = const Color(0xFFB91C1C));

    // Prop: mic or camera, held up beside the head
    switch (prop) {
      case CatProp.mic:
        final micCenter = Offset(center.dx + headRadius * 1.05, center.dy - headRadius * 0.15);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: micCenter, width: headRadius * 0.5, height: headRadius * 0.75),
            Radius.circular(headRadius * 0.25),
          ),
          Paint()..color = Colors.grey.shade200,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(micCenter.dx, micCenter.dy + headRadius * 0.55),
            width: headRadius * 0.08,
            height: headRadius * 0.35,
          ),
          Paint()..color = Colors.grey.shade400,
        );
        break;
      case CatProp.camera:
        final camCenter = Offset(center.dx + headRadius * 1.1, center.dy + headRadius * 0.05);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: camCenter, width: headRadius * 0.85, height: headRadius * 0.62),
            Radius.circular(headRadius * 0.12),
          ),
          Paint()..color = AppColors.tealStart,
        );
        canvas.drawCircle(camCenter, headRadius * 0.2, whitePaint);
        canvas.drawCircle(camCenter, headRadius * 0.13, Paint()..color = AppColors.tealEnd);
        break;
      case CatProp.none:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _CatMascotPainter oldDelegate) {
    return oldDelegate.prop != prop || oldDelegate.furColor != furColor;
  }
}
