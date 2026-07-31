import 'package:flutter/material.dart';
import 'smc.dart';

enum SignalType { strongBuy, buy, neutral, sell, strongSell }

extension SignalTypeX on SignalType {
  String get label {
    switch (this) {
      case SignalType.strongBuy:
        return 'STRONG BUY';
      case SignalType.buy:
        return 'BUY';
      case SignalType.neutral:
        return 'NEUTRAL';
      case SignalType.sell:
        return 'SELL';
      case SignalType.strongSell:
        return 'STRONG SELL';
    }
  }

  Color get color {
    switch (this) {
      case SignalType.strongBuy:
        return const Color(0xFF00C853);
      case SignalType.buy:
        return const Color(0xFF69F0AE);
      case SignalType.neutral:
        return const Color(0xFF9E9E9E);
      case SignalType.sell:
        return const Color(0xFFFF8A80);
      case SignalType.strongSell:
        return const Color(0xFFD50000);
    }
  }

  IconData get icon {
    switch (this) {
      case SignalType.strongBuy:
      case SignalType.buy:
        return Icons.trending_up;
      case SignalType.neutral:
        return Icons.trending_flat;
      case SignalType.sell:
      case SignalType.strongSell:
        return Icons.trending_down;
    }
  }
}

/// Matokeo ya kiashiria kimoja (indicator) mfano RSI au MACD
class IndicatorSignal {
  final String name;
  final SignalType signal;
  final String reason;
  final double? value;

  IndicatorSignal({
    required this.name,
    required this.signal,
    required this.reason,
    this.value,
  });
}

/// Matokeo kamili ya uchambuzi - jumla ya viashiria vyote
class AnalysisResult {
  final SignalType overallSignal;
  final double confidenceScore; // 0.0 - 1.0
  final List<IndicatorSignal> indicators;
  final DateTime analyzedAt;
  final SmcResult? smc;

  AnalysisResult({
    required this.overallSignal,
    required this.confidenceScore,
    required this.indicators,
    required this.analyzedAt,
    this.smc,
  });
}
