import '../models/candle.dart';
import '../models/smc.dart';

class _Pivot {
  final int index;
  final double price;
  final bool isHigh;
  _Pivot(this.index, this.price, this.isHigh);
}

/// Huduma ya uchambuzi wa **Smart Money Concepts (SMC)**:
/// - Market structure (Uptrend / Downtrend / Range)
/// - Break of Structure (BOS) na Change of Character (CHoCH)
/// - Order Blocks (bullish/bearish)
/// - Fair Value Gaps (FVG / imbalance)
/// - Liquidity pools (equal highs/lows)
///
/// Kumbuka: haya ni "heuristics" za kawaida zinazotumika na wachambuzi wa SMC
/// (mfano dhana za ICT / LuxAlgo), si hesabu rasmi ya kihisabati - kama
/// viashiria vingine (RSI/MACD), haitoi uhakika wa 100%.
class SmartMoneyService {
  /// Idadi ya candles kushoto/kulia zinazohitajika kuthibitisha swing (fractal)
  static const int _lr = 2;

  /// Tolerance ya kulinganisha "equal highs/lows" kama % ya bei (mfano 0.06%)
  static const double _liquidityTolerancePct = 0.0006;

  static List<_Pivot> _findPivots(List<Candle> candles) {
    final raw = <_Pivot>[];
    for (int i = _lr; i < candles.length - _lr; i++) {
      bool isHigh = true;
      bool isLow = true;
      for (int j = i - _lr; j <= i + _lr; j++) {
        if (j == i) continue;
        if (candles[j].high >= candles[i].high) isHigh = false;
        if (candles[j].low <= candles[i].low) isLow = false;
      }
      if (isHigh) raw.add(_Pivot(i, candles[i].high, true));
      if (isLow) raw.add(_Pivot(i, candles[i].low, false));
    }
    raw.sort((a, b) => a.index.compareTo(b.index));

    // Unganisha pivots zinazofuatana za aina moja - baki na iliyokithiri zaidi
    // (ili tuwe na mfuatano unaobadilishana high/low)
    final merged = <_Pivot>[];
    for (final p in raw) {
      if (merged.isNotEmpty && merged.last.isHigh == p.isHigh) {
        final keepNew = p.isHigh ? p.price > merged.last.price : p.price < merged.last.price;
        if (keepNew) merged[merged.length - 1] = p;
      } else {
        merged.add(p);
      }
    }
    return merged;
  }

  static SmcResult analyze(List<Candle> candles) {
    if (candles.length < 2 * _lr + 5) {
      return SmcResult(
        trend: MarketTrend.ranging,
        structureEvents: const [],
        orderBlocks: const [],
        fairValueGaps: const [],
        liquidityPools: const [],
        score: 0,
      );
    }

    final pivots = _findPivots(candles);
    final highs = pivots.where((p) => p.isHigh).toList();
    final lows = pivots.where((p) => !p.isHigh).toList();

    final events = <StructureEvent>[];
    MarketTrend trend = MarketTrend.ranging;

    int hPtr = 0;
    int lPtr = 0;
    for (int i = 0; i < candles.length; i++) {
      while (hPtr < highs.length &&
          highs[hPtr].index + _lr <= i &&
          candles[i].close > highs[hPtr].price) {
        final type =
            trend == MarketTrend.bullish ? StructureEventType.bosBullish : StructureEventType.chochBullish;
        events.add(StructureEvent(type: type, index: i, price: candles[i].close));
        trend = MarketTrend.bullish;
        hPtr++;
      }
      while (lPtr < lows.length &&
          lows[lPtr].index + _lr <= i &&
          candles[i].close < lows[lPtr].price) {
        final type =
            trend == MarketTrend.bearish ? StructureEventType.bosBearish : StructureEventType.chochBearish;
        events.add(StructureEvent(type: type, index: i, price: candles[i].close));
        trend = MarketTrend.bearish;
        lPtr++;
      }
    }

    // ---------- ORDER BLOCKS ----------
    // Kwa kila tukio la structure, tafuta candle ya mwisho yenye mwelekeo kinyume
    // (bearish candle kabla ya BOS/CHoCH bullish, bullish candle kabla ya bearish)
    final orderBlocks = <SmcZone>[];
    final usedObAnchors = <int>{};
    for (final ev in events) {
      final wantBearishAnchor = ev.type.isBullish;
      int? anchor;
      for (int j = ev.index; j >= 0 && j >= ev.index - 12; j--) {
        final isBearishCandle = !candles[j].isBullish;
        if (wantBearishAnchor && isBearishCandle) {
          anchor = j;
          break;
        }
        if (!wantBearishAnchor && !isBearishCandle) {
          anchor = j;
          break;
        }
      }
      if (anchor == null || usedObAnchors.contains(anchor)) continue;
      usedObAnchors.add(anchor);

      final c = candles[anchor];
      final top = c.high;
      final bottom = c.low;
      bool mitigated = false;
      for (int k = ev.index + 1; k < candles.length; k++) {
        if (candles[k].low <= top && candles[k].high >= bottom) {
          mitigated = true;
          break;
        }
      }
      orderBlocks.add(SmcZone(
        type: wantBearishAnchor ? SmcZoneType.bullishOrderBlock : SmcZoneType.bearishOrderBlock,
        startIndex: anchor,
        endIndex: ev.index,
        top: top,
        bottom: bottom,
        mitigated: mitigated,
      ));
    }

    // ---------- FAIR VALUE GAPS (3-candle imbalance) ----------
    final fvgs = <SmcZone>[];
    for (int i = 1; i < candles.length - 1; i++) {
      final left = candles[i - 1];
      final right = candles[i + 1];
      if (left.high < right.low) {
        // bullish imbalance
        bool mitigated = false;
        for (int k = i + 2; k < candles.length; k++) {
          if (candles[k].low <= left.high) {
            mitigated = true;
            break;
          }
        }
        fvgs.add(SmcZone(
          type: SmcZoneType.bullishFvg,
          startIndex: i - 1,
          endIndex: i + 1,
          top: right.low,
          bottom: left.high,
          mitigated: mitigated,
        ));
      } else if (left.low > right.high) {
        // bearish imbalance
        bool mitigated = false;
        for (int k = i + 2; k < candles.length; k++) {
          if (candles[k].high >= left.low) {
            mitigated = true;
            break;
          }
        }
        fvgs.add(SmcZone(
          type: SmcZoneType.bearishFvg,
          startIndex: i - 1,
          endIndex: i + 1,
          top: left.low,
          bottom: right.high,
          mitigated: mitigated,
        ));
      }
    }

    // ---------- LIQUIDITY POOLS (equal highs / equal lows) ----------
    final liquidityPools = <LiquidityPool>[];
    liquidityPools.addAll(_clusterLiquidity(highs, isBuySide: true));
    liquidityPools.addAll(_clusterLiquidity(lows, isBuySide: false));

    // ---------- SCORE (-2..+2) ----------
    double score = 0;
    if (events.isNotEmpty) {
      final lastEvent = events.last;
      final recentBonus = (lastEvent.index >= candles.length - 10) ? 1.0 : 0.5;
      final isChoch = lastEvent.type == StructureEventType.chochBullish ||
          lastEvent.type == StructureEventType.chochBearish;
      final magnitude = isChoch ? 1.4 : 1.0;
      score += (lastEvent.type.isBullish ? 1 : -1) * magnitude * recentBonus;
    }

    // Bonasi ndogo kama bei ya sasa iko karibu/ndani ya OB au FVG isiyo mitigated
    final lastClose = candles.last.close;
    for (final z in orderBlocks) {
      if (z.mitigated) continue;
      final withinZone = lastClose <= z.top && lastClose >= z.bottom;
      if (withinZone) {
        score += z.type.isBullish ? 0.6 : -0.6;
      }
    }
    score = score.clamp(-2.0, 2.0);

    return SmcResult(
      trend: trend,
      structureEvents: events,
      orderBlocks: orderBlocks,
      fairValueGaps: fvgs,
      liquidityPools: liquidityPools,
      score: score,
    );
  }

  static List<LiquidityPool> _clusterLiquidity(
    List<_Pivot> pivots, {
    required bool isBuySide,
  }) {
    final pools = <LiquidityPool>[];
    final used = List<bool>.filled(pivots.length, false);
    for (int i = 0; i < pivots.length; i++) {
      if (used[i]) continue;
      final cluster = <_Pivot>[pivots[i]];
      used[i] = true;
      for (int j = i + 1; j < pivots.length; j++) {
        if (used[j]) continue;
        final tolerance = pivots[i].price * _liquidityTolerancePct;
        if ((pivots[j].price - pivots[i].price).abs() <= tolerance) {
          cluster.add(pivots[j]);
          used[j] = true;
        }
      }
      if (cluster.length >= 2) {
        final avgPrice = cluster.map((p) => p.price).reduce((a, b) => a + b) / cluster.length;
        pools.add(LiquidityPool(
          isBuySide: isBuySide,
          price: avgPrice,
          indices: cluster.map((p) => p.index).toList(),
        ));
      }
    }
    return pools;
  }
}
