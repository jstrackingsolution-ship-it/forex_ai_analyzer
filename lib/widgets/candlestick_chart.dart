import 'package:flutter/material.dart';
import '../models/candle.dart';
import '../services/technical_analysis_service.dart';

class CandlestickChart extends StatelessWidget {
  final List<Candle> candles;
  final double height;

  const CandlestickChart({
    super.key,
    required this.candles,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('Hakuna data ya kuonyesha')),
      );
    }

    final closes = candles.map((c) => c.close).toList();
    final sma20 = TechnicalAnalysisService.sma(closes, 20);
    final sma50 = TechnicalAnalysisService.sma(closes, 50);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _CandlestickPainter(
          candles: candles,
          sma20: sma20,
          sma50: sma50,
        ),
      ),
    );
  }
}

class _CandlestickPainter extends CustomPainter {
  final List<Candle> candles;
  final List<double?> sma20;
  final List<double?> sma50;

  _CandlestickPainter({
    required this.candles,
    required this.sma20,
    required this.sma50,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    double minPrice = candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    double maxPrice = candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);

    // Pia zingatia SMA katika range ili zisikatike nje ya chati
    for (final v in [...sma20, ...sma50]) {
      if (v != null) {
        if (v < minPrice) minPrice = v;
        if (v > maxPrice) maxPrice = v;
      }
    }

    final padding = (maxPrice - minPrice) * 0.08;
    minPrice -= padding;
    maxPrice += padding;
    final priceRange = (maxPrice - minPrice).clamp(0.00001, double.infinity);

    final chartWidth = size.width - 50; // acha nafasi kwa price labels
    final candleSlot = chartWidth / candles.length;
    final candleWidth = (candleSlot * 0.6).clamp(1.0, 14.0);

    double yFor(double price) {
      return size.height - ((price - minPrice) / priceRange) * size.height;
    }

    // ---- Grid lines na price labels ----
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 1;
    final textStyle = TextStyle(color: Colors.grey.shade400, fontSize: 10);

    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
      final price = maxPrice - (priceRange * i / 4);
      final tp = TextPainter(
        text: TextSpan(text: price.toStringAsFixed(4), style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(chartWidth + 4, y - 6));
    }

    // ---- Candlesticks ----
    for (int i = 0; i < candles.length; i++) {
      final c = candles[i];
      final x = i * candleSlot + candleSlot / 2;
      final color = c.isBullish ? const Color(0xFF00C853) : const Color(0xFFD50000);
      final paint = Paint()..color = color..strokeWidth = 1.5;

      // Wick (mstari wa high-low)
      canvas.drawLine(
        Offset(x, yFor(c.high)),
        Offset(x, yFor(c.low)),
        paint,
      );

      // Mwili wa candle (open-close)
      final bodyTop = yFor(c.open > c.close ? c.open : c.close);
      final bodyBottom = yFor(c.open > c.close ? c.close : c.open);
      final bodyHeight = (bodyBottom - bodyTop).clamp(1.0, double.infinity);

      canvas.drawRect(
        Rect.fromLTWH(x - candleWidth / 2, bodyTop, candleWidth, bodyHeight),
        paint,
      );
    }

    // ---- Moving Average lines ----
    _drawLine(canvas, sma20, candleSlot, yFor, const Color(0xFF448AFF));
    _drawLine(canvas, sma50, candleSlot, yFor, const Color(0xFFFFAB40));

    // ---- Legend ----
    _drawLegendItem(canvas, 'SMA20', const Color(0xFF448AFF), Offset(4, 4));
    _drawLegendItem(canvas, 'SMA50', const Color(0xFFFFAB40), Offset(70, 4));
  }

  void _drawLine(
    Canvas canvas,
    List<double?> values,
    double candleSlot,
    double Function(double) yFor,
    Color color,
  ) {
    final path = Path();
    bool started = false;

    for (int i = 0; i < values.length; i++) {
      final v = values[i];
      if (v == null) continue;
      final x = i * candleSlot + candleSlot / 2;
      final y = yFor(v);
      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
  }

  void _drawLegendItem(Canvas canvas, String label, Color color, Offset pos) {
    canvas.drawLine(pos, pos + const Offset(16, 0), Paint()..color = color..strokeWidth = 2.5);
    final tp = TextPainter(
      text: TextSpan(text: label, style: TextStyle(color: Colors.grey.shade300, fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos + const Offset(20, -6));
  }

  @override
  bool shouldRepaint(covariant _CandlestickPainter oldDelegate) => true;
}
