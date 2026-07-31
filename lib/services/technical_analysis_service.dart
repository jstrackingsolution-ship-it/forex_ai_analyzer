import '../models/candle.dart';
import '../models/signal.dart';
import '../models/smc.dart';
import 'smart_money_service.dart';

class MacdResult {
  final List<double?> macdLine;
  final List<double?> signalLine;
  final List<double?> histogram;

  MacdResult({
    required this.macdLine,
    required this.signalLine,
    required this.histogram,
  });
}

/// Huduma ya kuhesabu viashiria vya kiufundi (technical indicators)
/// na kuzalisha mapendekezo ya BUY / SELL kwa kuchanganya matokeo yake.
class TechnicalAnalysisService {
  // ---------- MOVING AVERAGES ----------

  static List<double?> sma(List<double> prices, int period) {
    final result = List<double?>.filled(prices.length, null);
    for (int i = period - 1; i < prices.length; i++) {
      final window = prices.sublist(i - period + 1, i + 1);
      result[i] = window.reduce((a, b) => a + b) / period;
    }
    return result;
  }

  static List<double?> ema(List<double> prices, int period) {
    final result = List<double?>.filled(prices.length, null);
    if (prices.length < period) return result;

    final multiplier = 2 / (period + 1);
    // Anzisha kwa SMA ya kwanza
    double prevEma =
        prices.sublist(0, period).reduce((a, b) => a + b) / period;
    result[period - 1] = prevEma;

    for (int i = period; i < prices.length; i++) {
      final currentEma = (prices[i] - prevEma) * multiplier + prevEma;
      result[i] = currentEma;
      prevEma = currentEma;
    }
    return result;
  }

  // ---------- RSI (Relative Strength Index) ----------

  static List<double?> rsi(List<double> prices, {int period = 14}) {
    final result = List<double?>.filled(prices.length, null);
    if (prices.length <= period) return result;

    double gainSum = 0;
    double lossSum = 0;

    for (int i = 1; i <= period; i++) {
      final change = prices[i] - prices[i - 1];
      if (change >= 0) {
        gainSum += change;
      } else {
        lossSum += -change;
      }
    }

    double avgGain = gainSum / period;
    double avgLoss = lossSum / period;
    result[period] = _rsiFromAvg(avgGain, avgLoss);

    for (int i = period + 1; i < prices.length; i++) {
      final change = prices[i] - prices[i - 1];
      final gain = change > 0 ? change : 0.0;
      final loss = change < 0 ? -change : 0.0;

      avgGain = (avgGain * (period - 1) + gain) / period;
      avgLoss = (avgLoss * (period - 1) + loss) / period;

      result[i] = _rsiFromAvg(avgGain, avgLoss);
    }
    return result;
  }

  static double _rsiFromAvg(double avgGain, double avgLoss) {
    if (avgLoss == 0) return 100;
    final rs = avgGain / avgLoss;
    return 100 - (100 / (1 + rs));
  }

  // ---------- MACD ----------

  static MacdResult macd(
    List<double> prices, {
    int fastPeriod = 12,
    int slowPeriod = 26,
    int signalPeriod = 9,
  }) {
    final fastEma = ema(prices, fastPeriod);
    final slowEma = ema(prices, slowPeriod);

    final macdLine = List<double?>.filled(prices.length, null);
    for (int i = 0; i < prices.length; i++) {
      if (fastEma[i] != null && slowEma[i] != null) {
        macdLine[i] = fastEma[i]! - slowEma[i]!;
      }
    }

    // Signal line = EMA(signalPeriod) ya macdLine (ikipuuza null za mwanzo)
    final validMacd = macdLine.where((v) => v != null).map((v) => v!).toList();
    final emaOfMacd = ema(validMacd, signalPeriod);

    final signalLine = List<double?>.filled(prices.length, null);
    final histogram = List<double?>.filled(prices.length, null);

    int validIndex = 0;
    for (int i = 0; i < prices.length; i++) {
      if (macdLine[i] != null) {
        if (validIndex < emaOfMacd.length && emaOfMacd[validIndex] != null) {
          signalLine[i] = emaOfMacd[validIndex];
          histogram[i] = macdLine[i]! - signalLine[i]!;
        }
        validIndex++;
      }
    }

    return MacdResult(
      macdLine: macdLine,
      signalLine: signalLine,
      histogram: histogram,
    );
  }

  // ---------- SIGNAL GENERATION (Uchambuzi wa AI) ----------

  /// Inachanganya RSI, MACD, na Moving Average Crossover kuzalisha
  /// mapendekezo ya jumla (BUY/SELL/NEUTRAL) na kiwango cha uhakika.
  static AnalysisResult analyze(List<Candle> candles) {
    final closes = candles.map((c) => c.close).toList();
    final indicators = <IndicatorSignal>[];

    // Haja ya angalau candles za kutosha kuhesabu MACD(26) + Signal(9)
    if (closes.length < 40) {
      return AnalysisResult(
        overallSignal: SignalType.neutral,
        confidenceScore: 0,
        indicators: [
          IndicatorSignal(
            name: 'Data',
            signal: SignalType.neutral,
            reason: 'Data haitoshi kufanya uchambuzi (chagua muda mrefu zaidi)',
          )
        ],
        analyzedAt: DateTime.now(),
      );
    }

    double score = 0; // -2..+2 kwa kila kiashiria, jumla itagawanywa

    // ---- 1. RSI ----
    final rsiValues = rsi(closes, period: 14);
    final lastRsi = rsiValues.last;
    if (lastRsi != null) {
      SignalType rsiSignal;
      String reason;
      double rsiScore;
      if (lastRsi >= 70) {
        rsiSignal = SignalType.sell;
        reason = 'RSI ni ${lastRsi.toStringAsFixed(1)} - soko liko overbought';
        rsiScore = -1;
      } else if (lastRsi <= 30) {
        rsiSignal = SignalType.buy;
        reason = 'RSI ni ${lastRsi.toStringAsFixed(1)} - soko liko oversold';
        rsiScore = 1;
      } else if (lastRsi > 50) {
        rsiSignal = SignalType.neutral;
        reason = 'RSI ni ${lastRsi.toStringAsFixed(1)} - momentum chanya lakini si extreme';
        rsiScore = 0.3;
      } else {
        rsiSignal = SignalType.neutral;
        reason = 'RSI ni ${lastRsi.toStringAsFixed(1)} - momentum hasi lakini si extreme';
        rsiScore = -0.3;
      }
      indicators.add(IndicatorSignal(
        name: 'RSI (14)',
        signal: rsiSignal,
        reason: reason,
        value: lastRsi,
      ));
      score += rsiScore;
    }

    // ---- 2. MACD ----
    final macdResult = macd(closes);
    final lastMacd = macdResult.macdLine.last;
    final lastSignal = macdResult.signalLine.last;
    final prevMacd = macdResult.macdLine.length > 1
        ? macdResult.macdLine[macdResult.macdLine.length - 2]
        : null;
    final prevSignal = macdResult.signalLine.length > 1
        ? macdResult.signalLine[macdResult.signalLine.length - 2]
        : null;

    if (lastMacd != null &&
        lastSignal != null &&
        prevMacd != null &&
        prevSignal != null) {
      final crossedUp = prevMacd <= prevSignal && lastMacd > lastSignal;
      final crossedDown = prevMacd >= prevSignal && lastMacd < lastSignal;

      SignalType macdSignal;
      String reason;
      double macdScore;

      if (crossedUp) {
        macdSignal = SignalType.strongBuy;
        reason = 'MACD imevuka juu ya Signal line - bullish crossover';
        macdScore = 1.5;
      } else if (crossedDown) {
        macdSignal = SignalType.strongSell;
        reason = 'MACD imevuka chini ya Signal line - bearish crossover';
        macdScore = -1.5;
      } else if (lastMacd > lastSignal) {
        macdSignal = SignalType.buy;
        reason = 'MACD iko juu ya Signal line - momentum chanya inaendelea';
        macdScore = 0.7;
      } else {
        macdSignal = SignalType.sell;
        reason = 'MACD iko chini ya Signal line - momentum hasi inaendelea';
        macdScore = -0.7;
      }
      indicators.add(IndicatorSignal(
        name: 'MACD (12,26,9)',
        signal: macdSignal,
        reason: reason,
        value: lastMacd,
      ));
      score += macdScore;
    }

    // ---- 3. Moving Average Crossover (SMA 20 vs SMA 50) ----
    final sma20 = sma(closes, 20);
    final sma50 = sma(closes, 50);
    final lastSma20 = sma20.last;
    final lastSma50 = sma50.last;

    if (lastSma20 != null && lastSma50 != null) {
      SignalType maSignal;
      String reason;
      double maScore;
      final lastPrice = closes.last;

      if (lastSma20 > lastSma50 && lastPrice > lastSma20) {
        maSignal = SignalType.buy;
        reason = 'Bei iko juu ya SMA20 na SMA20 > SMA50 - uptrend';
        maScore = 1;
      } else if (lastSma20 < lastSma50 && lastPrice < lastSma20) {
        maSignal = SignalType.sell;
        reason = 'Bei iko chini ya SMA20 na SMA20 < SMA50 - downtrend';
        maScore = -1;
      } else {
        maSignal = SignalType.neutral;
        reason = 'Hakuna trend dhahiri kati ya SMA20 na SMA50';
        maScore = 0;
      }
      indicators.add(IndicatorSignal(
        name: 'MA Crossover (20/50)',
        signal: maSignal,
        reason: reason,
        value: lastSma20,
      ));
      score += maScore;
    } else {
      // SMA50 haipatikani (data haitoshi) - tumia SMA20 tu kama muktadha
      if (lastSma20 != null) {
        indicators.add(IndicatorSignal(
          name: 'MA (20)',
          signal: closes.last > lastSma20 ? SignalType.buy : SignalType.sell,
          reason: closes.last > lastSma20
              ? 'Bei iko juu ya SMA20'
              : 'Bei iko chini ya SMA20',
          value: lastSma20,
        ));
      }
    }

    // ---- 4. Smart Money Concepts (Market Structure, Order Blocks, FVG, Liquidity) ----
    final smc = SmartMoneyService.analyze(candles);
    if (smc.structureEvents.isNotEmpty) {
      final lastEvent = smc.structureEvents.last;
      final isChoch = lastEvent.type == StructureEventType.chochBullish ||
          lastEvent.type == StructureEventType.chochBearish;
      final smcSignal = lastEvent.type.isBullish
          ? (isChoch ? SignalType.strongBuy : SignalType.buy)
          : (isChoch ? SignalType.strongSell : SignalType.sell);
      final obCount = smc.orderBlocks.where((z) => !z.mitigated).length;
      final fvgCount = smc.fairValueGaps.where((z) => !z.mitigated).length;
      indicators.add(IndicatorSignal(
        name: 'Smart Money Concepts',
        signal: smcSignal,
        reason: '${smc.trend.label} · ${lastEvent.type.label} kwenye candle #${lastEvent.index + 1}. '
            'Zones hai: $obCount Order Block(s), $fvgCount FVG(s).',
        value: smc.score,
      ));
    } else {
      indicators.add(IndicatorSignal(
        name: 'Smart Money Concepts',
        signal: SignalType.neutral,
        reason: '${smc.trend.label} - hakuna BOS/CHoCH dhahiri bado kwenye data hii.',
        value: smc.score,
      ));
    }
    score += smc.score;

    // ---- Jumlisha kuwa signal moja ya mwisho ----
    // score range ya kinadharia takriban -6..+6 (RSI ±1, MACD ±1.5, MA ±1, SMC ±2)
    final normalized = (score / 6).clamp(-1.0, 1.0);
    final confidence = normalized.abs();

    SignalType overall;
    if (normalized >= 0.5) {
      overall = SignalType.strongBuy;
    } else if (normalized >= 0.15) {
      overall = SignalType.buy;
    } else if (normalized <= -0.5) {
      overall = SignalType.strongSell;
    } else if (normalized <= -0.15) {
      overall = SignalType.sell;
    } else {
      overall = SignalType.neutral;
    }

    return AnalysisResult(
      overallSignal: overall,
      confidenceScore: confidence,
      indicators: indicators,
      analyzedAt: DateTime.now(),
      smc: smc,
    );
  }
}
