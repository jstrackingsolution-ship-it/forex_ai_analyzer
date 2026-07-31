import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/candle.dart';
import '../models/signal.dart';
import '../services/forex_api_service.dart';
import '../services/technical_analysis_service.dart';
import '../widgets/candlestick_chart.dart';
import '../widgets/indicator_chart.dart';
import '../widgets/signal_card.dart';
import '../widgets/smc_panel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedPair = 'EUR/USD';
  String _selectedTimeframeLabel = '1 Saa';
  String _apiKey = '';
  bool _usingDemoKey = false;

  List<Candle> _candles = [];
  AnalysisResult? _analysis;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('twelve_data_api_key');
    if (saved != null && saved.isNotEmpty) {
      setState(() {
        _apiKey = saved;
        _usingDemoKey = saved == ForexApiService.demoApiKey;
      });
    } else {
      // Hakuna key iliyohifadhiwa - tumia demo key ya Twelve Data kwa default
      // ili app iweze kuonyesha matokeo mara moja (angalia mipaka yake kwenye
      // ForexApiService.demoApiKey na kwenye banner ya UI hapa chini).
      setState(() {
        _apiKey = ForexApiService.demoApiKey;
        _usingDemoKey = true;
      });
    }
    _fetchAndAnalyze();
  }

  Future<void> _saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('twelve_data_api_key', key);
    setState(() {
      _apiKey = key;
      _usingDemoKey = key == ForexApiService.demoApiKey;
    });
  }

  Future<void> _promptForApiKey() async {
    final controller = TextEditingController(text: _apiKey);
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Weka Twelve Data API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pata API key yako BURE kwenye twelvedata.com/pricing kisha uibandike hapa.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              'Kwa sasa unaweza pia kutumia demo key ya Twelve Data ("${ForexApiService.demoApiKey}") '
              'kujaribu app, lakini ina mipaka kubwa (alama chache, rate-limit kali, huenda '
              'isifanye kazi vizuri kwa XAU/USD au BTC/USD). Tumia key yako mwenyewe kwa matokeo '
              'ya kuaminika.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'API Key',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, ForexApiService.demoApiKey),
            child: const Text('Tumia Demo Key'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Hifadhi'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _saveApiKey(result);
      _fetchAndAnalyze();
    }
  }

  Future<void> _fetchAndAnalyze() async {
    if (_apiKey.isEmpty) {
      _promptForApiKey();
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final service = ForexApiService(apiKey: _apiKey);
      final interval = Timeframes.options[_selectedTimeframeLabel]!;
      final candles = await service.fetchCandles(
        symbol: _selectedPair,
        interval: interval,
      );
      final analysis = TechnicalAnalysisService.analyze(candles);

      setState(() {
        _candles = candles;
        _analysis = analysis;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final closes = _candles.map((c) => c.close).toList();
    final rsiValues = closes.isNotEmpty
        ? TechnicalAnalysisService.rsi(closes)
        : <double?>[];
    final macdResult = closes.isNotEmpty
        ? TechnicalAnalysisService.macd(closes)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forex AI Analyzer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key_outlined),
            tooltip: 'Badilisha API Key',
            onPressed: _promptForApiKey,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Onyesha upya',
            onPressed: _loading ? null : _fetchAndAnalyze,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAndAnalyze,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSelectors(),
            if (_usingDemoKey) ...[
              const SizedBox(height: 12),
              _buildDemoKeyBanner(),
            ],
            const SizedBox(height: 16),
            if (_loading) const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            )
            else if (_error != null)
              _buildError()
            else if (_candles.isNotEmpty && _analysis != null) ...[
              Text(
                '$_selectedPair · $_selectedTimeframeLabel',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: CandlestickChart(candles: _candles),
                ),
              ),
              const SizedBox(height: 16),
              const Text('RSI (14)', style: TextStyle(fontWeight: FontWeight.bold)),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: RsiChart(values: rsiValues),
                ),
              ),
              const SizedBox(height: 16),
              const Text('MACD (12, 26, 9)', style: TextStyle(fontWeight: FontWeight.bold)),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: MacdChart(
                    macdLine: macdResult!.macdLine,
                    signalLine: macdResult.signalLine,
                    histogram: macdResult.histogram,
                  ),
                ),
              ),
              if (_analysis!.smc != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Smart Money Concepts (Market Structure)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SmcPanel(smc: _analysis!.smc!, candleCount: _candles.length),
              ],
              const SizedBox(height: 20),
              const Text(
                'Matokeo ya Uchambuzi (AI Signal)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              OverallSignalCard(result: _analysis!),
              const SizedBox(height: 16),
              const Text('Kila Kiashiria', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._analysis!.indicators.map((i) => IndicatorSignalTile(indicator: i)),
              const SizedBox(height: 20),
              Text(
                'Ilichambuliwa: ${_analysis!.analyzedAt.toString().substring(0, 19)}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
              const SizedBox(height: 12),
              _buildDisclaimer(),
            ] else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: Text('Bofya refresh kuanza uchambuzi')),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectors() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedPair,
            decoration: const InputDecoration(
              labelText: 'Jozi (Pair)',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: ForexPairs.all.map((p) {
              final category = ForexPairs.categoryOf(p);
              final suffix = category == 'Forex' ? '' : '  ·  $category';
              return DropdownMenuItem(value: p, child: Text('$p$suffix'));
            }).toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _selectedPair = v);
              _fetchAndAnalyze();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedTimeframeLabel,
            decoration: const InputDecoration(
              labelText: 'Muda',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: Timeframes.options.keys
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _selectedTimeframeLabel = v);
              _fetchAndAnalyze();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Hitilafu', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          ]),
          const SizedBox(height: 8),
          Text(_error ?? '', style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _fetchAndAnalyze, child: const Text('Jaribu Tena')),
        ],
      ),
    );
  }

  Widget _buildDemoKeyBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.lightBlueAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Unatumia Twelve Data "demo" API key (mipaka: alama chache, rate-limit kali, '
              'huenda isifanye kazi vizuri kwa XAU/USD au BTC/USD). Bofya 🔑 juu kuweka key '
              'yako mwenyewe ya BURE kutoka twelvedata.com/pricing.',
              style: TextStyle(fontSize: 11.5, color: Colors.blue.shade100),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: const Text(
        '⚠️ Onyo: Uchambuzi huu ni wa kiufundi (technical) tu na hautoi uhakika wa 100%. '
        'Forex trading ina hatari kubwa ya kupoteza fedha. Hii si ushauri wa kifedha - '
        'fanya utafiti wako mwenyewe kabla ya kufanya maamuzi yoyote ya trading.',
        style: TextStyle(fontSize: 12),
      ),
    );
  }
}
