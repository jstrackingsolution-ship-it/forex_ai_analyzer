import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/candle.dart';

/// Orodha ya jozi za forex zinazotumika sana
class ForexPairs {
  static const List<String> majors = [
    'EUR/USD',
    'GBP/USD',
    'USD/JPY',
    'USD/CHF',
    'AUD/USD',
    'USD/CAD',
    'NZD/USD',
    'EUR/GBP',
    'EUR/JPY',
    'GBP/JPY',
  ];

  /// Metali (Gold spot dhidi ya Dola) - "XAUUSD" kwenye Twelve Data
  static const List<String> metals = [
    'XAU/USD',
  ];

  /// Crypto - "BTCUSD" kwenye Twelve Data
  static const List<String> crypto = [
    'BTC/USD',
  ];

  /// Jozi zote (forex + metals + crypto) kwa ajili ya dropdown moja
  static const List<String> all = [
    ...majors,
    ...metals,
    ...crypto,
  ];

  /// Inarudisha jina la kundi la jozi husika (kwa UI grouping)
  static String categoryOf(String symbol) {
    if (metals.contains(symbol)) return 'Metali (Metals)';
    if (crypto.contains(symbol)) return 'Crypto';
    return 'Forex';
  }
}

/// Timeframes zinazosapotiwa na Twelve Data
class Timeframes {
  static const Map<String, String> options = {
    '15 Dakika': '15min',
    '30 Dakika': '30min',
    '1 Saa': '1h',
    '4 Masaa': '4h',
    '1 Siku': '1day',
  };
}

class ForexApiException implements Exception {
  final String message;
  ForexApiException(this.message);
  @override
  String toString() => message;
}

class ForexApiService {
  static const String _baseUrl = 'https://api.twelvedata.com';

  /// Twelve Data "demo" API key inayotolewa hadharani na Twelve Data kwenye
  /// nyaraka zao rasmi (https://twelvedata.com/docs) kwa madhumuni ya
  /// kujaribu API bila usajili.
  ///
  /// ⚠️ MIPAKA MUHIMU ya demo key:
  /// - Inafanya kazi kwa idadi ndogo tu ya alama (symbols) walizoziruhusu
  ///   Twelve Data (mfano baadhi ya forex/crypto examples) - SI alama zote.
  /// - Ina rate-limit kali zaidi kuliko akaunti ya bure iliyosajiliwa, na
  ///   inaweza kuzimwa au kubadilishwa na Twelve Data wakati wowote bila
  ///   taarifa - Anthropic/Claude hawaimiliki wala kuidhibiti.
  /// - Data ya XAU/USD (dhahabu) inahitaji akaunti ya "Basic" plan na juu
  ///   kwa historia kamili - huenda demo key isifanye kazi kwa symbol hii.
  /// - Kwa matumizi ya kweli/ya kuaminika, sajili akaunti yako BURE kwenye
  ///   https://twelvedata.com/pricing (Free plan: 800 credits/siku) na
  ///   uweke key yako mwenyewe kwenye app (kitufe cha 🔑 juu kulia).
  static const String demoApiKey = 'demo';

  /// Weka API key yako hapa, au itume kwa constructor.
  /// Pata key BURE kwa: https://twelvedata.com/pricing (Free plan)
  final String apiKey;

  ForexApiService({required this.apiKey});

  /// Inachukua candles za bei kwa jozi fulani (mfano "EUR/USD")
  /// na muda fulani (mfano "1h")
  Future<List<Candle>> fetchCandles({
    required String symbol,
    required String interval,
    int outputSize = 150,
  }) async {
    if (apiKey.isEmpty) {
      throw ForexApiException(
        'Tafadhali weka API key yako ya Twelve Data (angalia README.md)',
      );
    }

    final uri = Uri.parse(
      '$_baseUrl/time_series?symbol=$symbol&interval=$interval'
      '&outputsize=$outputSize&apikey=$apiKey&order=ASC',
    );

    final response = await http.get(uri).timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw ForexApiException(
            'Muda umeisha kuunganisha na server. Angalia mtandao wako.',
          ),
        );

    if (response.statusCode != 200) {
      throw ForexApiException('Server error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data['status'] == 'error') {
      throw ForexApiException(data['message'] ?? 'Hitilafu isiyojulikana');
    }

    final values = data['values'] as List<dynamic>?;
    if (values == null || values.isEmpty) {
      throw ForexApiException('Hakuna data iliyorudishwa kwa $symbol');
    }

    return values
        .map((v) => Candle.fromTwelveData(v as Map<String, dynamic>))
        .toList();
  }
}
