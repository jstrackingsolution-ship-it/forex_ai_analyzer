import 'package:flutter/material.dart';

/// Aina za "zone" za Smart Money Concepts
enum SmcZoneType {
  bullishOrderBlock,
  bearishOrderBlock,
  bullishFvg,
  bearishFvg,
}

extension SmcZoneTypeX on SmcZoneType {
  String get label {
    switch (this) {
      case SmcZoneType.bullishOrderBlock:
        return 'Bullish Order Block';
      case SmcZoneType.bearishOrderBlock:
        return 'Bearish Order Block';
      case SmcZoneType.bullishFvg:
        return 'Bullish FVG';
      case SmcZoneType.bearishFvg:
        return 'Bearish FVG';
    }
  }

  bool get isBullish =>
      this == SmcZoneType.bullishOrderBlock || this == SmcZoneType.bullishFvg;

  Color get color => isBullish ? const Color(0xFF00C853) : const Color(0xFFD50000);
}

/// "Zone" moja muhimu (Order Block au Fair Value Gap) kwenye chati
class SmcZone {
  final SmcZoneType type;
  final int startIndex;
  final int endIndex;
  final double top;
  final double bottom;
  final bool mitigated; // bei tayari imerudi kugusa zone hii baada ya kuundwa

  SmcZone({
    required this.type,
    required this.startIndex,
    required this.endIndex,
    required this.top,
    required this.bottom,
    required this.mitigated,
  });
}

enum StructureEventType { bosBullish, bosBearish, chochBullish, chochBearish }

extension StructureEventTypeX on StructureEventType {
  String get label {
    switch (this) {
      case StructureEventType.bosBullish:
        return 'BOS (Bullish)';
      case StructureEventType.bosBearish:
        return 'BOS (Bearish)';
      case StructureEventType.chochBullish:
        return 'CHoCH (Bullish)';
      case StructureEventType.chochBearish:
        return 'CHoCH (Bearish)';
    }
  }

  bool get isBullish =>
      this == StructureEventType.bosBullish || this == StructureEventType.chochBullish;
}

/// Tukio la market structure: Break of Structure (BOS) au Change of Character (CHoCH)
class StructureEvent {
  final StructureEventType type;
  final int index;
  final double price;

  StructureEvent({required this.type, required this.index, required this.price});
}

enum MarketTrend { bullish, bearish, ranging }

extension MarketTrendX on MarketTrend {
  String get label {
    switch (this) {
      case MarketTrend.bullish:
        return 'UPTREND (Bullish Structure)';
      case MarketTrend.bearish:
        return 'DOWNTREND (Bearish Structure)';
      case MarketTrend.ranging:
        return 'RANGING (Hakuna Structure Wazi)';
    }
  }

  Color get color {
    switch (this) {
      case MarketTrend.bullish:
        return const Color(0xFF00C853);
      case MarketTrend.bearish:
        return const Color(0xFFD50000);
      case MarketTrend.ranging:
        return const Color(0xFF9E9E9E);
    }
  }
}

/// Kundi la liquidity (equal highs / equal lows) - maeneo ambayo "smart money"
/// mara nyingi huwinda stop-losses kabla ya kubadili mwelekeo
class LiquidityPool {
  final bool isBuySide; // true = juu ya bei (equal highs), false = chini (equal lows)
  final double price;
  final List<int> indices;

  LiquidityPool({required this.isBuySide, required this.price, required this.indices});
}

/// Matokeo kamili ya uchambuzi wa Smart Money Concepts
class SmcResult {
  final MarketTrend trend;
  final List<StructureEvent> structureEvents;
  final List<SmcZone> orderBlocks;
  final List<SmcZone> fairValueGaps;
  final List<LiquidityPool> liquidityPools;
  final double score; // -2..+2, itaunganishwa na viashiria vingine

  SmcResult({
    required this.trend,
    required this.structureEvents,
    required this.orderBlocks,
    required this.fairValueGaps,
    required this.liquidityPools,
    required this.score,
  });
}
