# Forex AI Analyzer 📈

App ya Flutter inayofanya **uchambuzi wa kiufundi (technical analysis)** wa Forex,
Dhahabu (XAU/USD), na Bitcoin (BTC/USD) kwa kutumia RSI, MACD, Moving Averages
(SMA 20/50), na **Smart Money Concepts (SMC)** — market structure (BOS/CHoCH),
Order Blocks, Fair Value Gaps (FVG), na Liquidity pools — kisha kuzalisha
mapendekezo ya **BUY / SELL / NEUTRAL** kiotomatiki. Ni dashboard ya kuangalia
tu (view-only) — haifanyi trade yoyote moja kwa moja.

## Vipengele (Features)
- Dashboard yenye candlestick chart + SMA20/SMA50 overlay
- Chati za RSI (14) na MACD (12,26,9)
- **Smart Money Concepts (SMC)**: Market Structure trend, BOS (Break of
  Structure) na CHoCH (Change of Character), Order Blocks, Fair Value Gaps
  (FVG), na Liquidity pools (equal highs/lows) — inaonyeshwa kwenye paneli
  yake mwenyewe na inachangia kwenye "AI Signal" ya jumla
- "AI Signal" — inachanganya viashiria vyote (RSI, MACD, MA, SMC) kutoa signal
  moja ya jumla (STRONG BUY / BUY / NEUTRAL / SELL / STRONG SELL) pamoja na
  % ya uhakika
- **Auto-Analyze** — inachambua upya kiotomatiki kwa interval unayochagua
  (1s/5s/15s/30s/60s, default 1s), bila kuficha chati wakati wa background
  refresh; ina toggle ya kuzima/kuwasha na inaonyesha error kwa upole
  isipofanikiwa (bila kuvunja app)
- Uchaguzi wa jozi kuu 10 za forex (EUR/USD, GBP/USD, USD/JPY, n.k.), pamoja
  na **XAU/USD (Dhahabu/Gold)** na **BTC/USD (Bitcoin)**
- Uchaguzi wa timeframe (15min - 1day)
- API key inahifadhiwa kwenye kifaa (local storage); app inakuja na Twelve
  Data "demo" key kama default ili uweze kujaribu mara moja (angalia mipaka
  yake chini)
- Ruhusa za Android (`INTERNET`, `ACCESS_NETWORK_STATE`) zimewekwa kwenye
  `AndroidManifest.xml` ili app iweze kufikia mtandao/data na kuchukua bei
  moja kwa moja kwenye simu za Android (bila hii, HTTP requests zote
  zingeshindwa kimya kimya kwenye release build)

## Muundo wa Mradi
```
lib/
  models/
    candle.dart          # OHLC candle model
    signal.dart           # Signal types na AnalysisResult
    smc.dart               # Smart Money Concepts models (zones, structure events, trend)
  services/
    forex_api_service.dart          # Kuchukua data kutoka Twelve Data (forex/metals/crypto)
    technical_analysis_service.dart # RSI, MACD, SMA/EMA + signal logic (inajumuisha SMC)
    smart_money_service.dart        # Uchambuzi wa Smart Money Concepts (BOS/CHoCH, OB, FVG, liquidity)
  widgets/
    candlestick_chart.dart  # Custom-painted candlestick chart
    indicator_chart.dart    # RSI & MACD charts (fl_chart)
    signal_card.dart        # UI za kuonyesha signals
    smc_panel.dart          # UI ya Smart Money Concepts (structure, order blocks, FVG, liquidity)
  screens/
    dashboard_screen.dart   # Screen kuu
  main.dart
```

## Jinsi ya Kuanza

### 1. API Key ya Twelve Data
App hii inakuja na **demo API key** ya Twelve Data (`demo`) iliyowekwa kama
default, ili uweze kufungua app na kuona matokeo mara moja bila usajili.

> ⚠️ **Mipaka ya demo key**: ni key ya umma inayotolewa na Twelve Data wenyewe
> kwenye [nyaraka zao](https://twelvedata.com/docs) kwa majaribio - si key ya
> kudumu wala ya kutegemewa kwa matumizi ya kweli. Ina rate-limit kali, na
> inafanya kazi kwa idadi ndogo tu ya alama (symbols). Huenda **isifanye kazi**
> kwa **XAU/USD** (dhahabu inahitaji Twelve Data "Basic" plan na juu kwa
> historia kamili) au **BTC/USD** kutegemeana na mipaka ya sasa ya Twelve Data.

Kwa matumizi ya kuaminika ya jozi zote (ikiwemo XAU/USD na BTC/USD), pata API
key yako mwenyewe BURE:
Nenda [twelvedata.com/pricing](https://twelvedata.com/pricing) → chagua **Free Plan**
(800 credits/siku, 8 requests/dakika - inatosha kabisa kwa app hii) → signup →
copy API key yako → bofya kitufe cha 🔑 juu ya app kuiweka.

> Unaweza pia kutumia providers zingine (Alpha Vantage, Polygon.io, OANDA) —
> utahitaji tu kubadilisha `forex_api_service.dart` kulingana na response format yao.

### 2. Install Dependencies
```bash
cd forex_ai_analyzer
flutter pub get
```

### 3. Endesha App
```bash
flutter run
```
Wakati app itaanza, itatumia demo key moja kwa moja na kuonyesha matokeo.
Unaweza kubadilisha kwenda API key yako mwenyewe wakati wowote kwa kubofya
kitufe cha 🔑 juu kulia (itahifadhiwa kwenye kifaa chako kwa matumizi yajayo).

## Auto-Analyze (Uchambuzi wa Kiotomatiki)

App inaweza kuchambua upya kiotomatiki bila wewe kubofya refresh, kwa
kutumia kitufe cha "Auto-Analyze" juu ya dashboard. Default ni **ON, kila
sekunde 1** kama ulivyoomba, lakini kuna mambo muhimu ya kuzingatia:

> ⚠️ **Muhimu kuhusu rate limits**: Twelve Data Free plan inaruhusu **8
> requests/dakika** tu (demo key ina mipaka kali zaidi). Interval ya sekunde
> 1 inamaanisha requests 60/dakika — hii **itafikia rate-limit haraka sana**
> na utaanza kupata error za "429 Too Many Requests". App inashughulikia hili
> vizuri (haivunjiki, inaendelea kuonyesha data ya mwisho iliyofanikiwa na
> banner ndogo ya onyo), lakini kwa matumizi ya kawaida ni bora kubadilisha
> interval kwenda **15s au 30s+** kwenye dropdown iliyo karibu na switch ya
> Auto-Analyze. Ukiwa na akaunti ya kulipia (Grow/Pro plan ya Twelve Data
> yenye credits nyingi zaidi kwa dakika), sekunde 1 inaweza kufanya kazi
> vizuri zaidi.

Jinsi inavyofanya kazi kiufundi: `Timer.periodic` inaita `fetchCandles` +
`analyze` kwa interval uliochagua; wakati wa auto-refresh (baada ya data ya
kwanza kuonekana), chati **haifutiki** — spinner ndogo tu inaonekana juu
kulia wakati inasasisha, ili usipoteze muktadha wa kile unachokiangalia.

## Ruhusa za Android (Permissions)

`android/app/src/main/AndroidManifest.xml` sasa ina:
- `android.permission.INTERNET` — bila hii, app haiwezi kufanya HTTP
  requests kabisa kwenye Android release build (hii ilikuwa sababu kubwa
  app isingeweza kuchukua data kwenye simu halisi ya Android hapo awali).
- `android.permission.ACCESS_NETWORK_STATE` — inaruhusu app kuangalia hali
  ya mtandao.

API key na mipangilio mingine (pair uliyochagua, timeframe) huhifadhiwa
kwa kutumia `shared_preferences`, ambayo inatumia **internal app storage**
ya Android/iOS — hii **haihitaji ruhusa yoyote maalum** kwenye Android ya
kisasa (hakuna haja ya `WRITE_EXTERNAL_STORAGE`, ambayo pia ingezuiwa na
Play Store kama isiyo na sababu ya msingi). Data hii ni ya kifaa chako tu
na haitumwi popote isipokuwa kwenye Twelve Data API kuomba bei.

## Jinsi Signal Inavyohesabiwa

Kila kiashiria kinatoa alama:
- **RSI** (-1 hadi +1): >70 = overbought (sell), <30 = oversold (buy)
- **MACD** (-1.5 hadi +1.5): crossover ya MACD line na Signal line (bullish/bearish)
- **MA Crossover** (-1 hadi +1): uhusiano kati ya bei, SMA20, na SMA50 (trend direction)
- **Smart Money Concepts** (-2 hadi +2): mwelekeo wa mwisho wa BOS/CHoCH
  (CHoCH ina uzito zaidi kwa sababu inaashiria mabadiliko ya trend), pamoja na
  bonasi ndogo endapo bei ya sasa iko ndani ya Order Block au FVG isiyo
  "mitigated"

Alama zote zinajumlishwa (jumla ya kinadharia ni takriban -6 hadi +6) na
kugawanywa kuwa score ya -1.0 hadi +1.0, kisha:
- `>= 0.5` → STRONG BUY
- `>= 0.15` → BUY
- `-0.15` hadi `0.15` → NEUTRAL
- `<= -0.15` → SELL
- `<= -0.5` → STRONG SELL

### Kuhusu Smart Money Concepts (SMC)
Uchambuzi wa SMC unatumia "heuristics" za kawaida zinazotumiwa na wachambuzi
wa SMC/ICT:
- **Swing points**: kutambuliwa kwa fractal ya candles 2 kushoto na 2 kulia
- **BOS (Break of Structure)**: bei inapovunja swing high/low ya awali
  ikiendeleza trend iliyopo
- **CHoCH (Change of Character)**: bei inapovunja swing high/low kinyume na
  trend iliyopo - ishara ya mabadiliko ya mwelekeo
- **Order Blocks**: candle ya mwisho yenye mwelekeo kinyume kabla ya
  BOS/CHoCH
- **Fair Value Gaps (FVG)**: "imbalance" ya candles 3 ambapo candle ya kwanza
  na ya tatu hazigusani
- **Liquidity pools**: maeneo yenye "equal highs/lows" - sehemu ambazo mara
  nyingi bei huvutwa kabla ya kubadili mwelekeo

Kama viashiria vingine, SMC ni uchambuzi wa kiufundi tu na si utabiri wa
uhakika wa 100%.

## Kuboresha Baadaye (Ideas za Kupanua)
- Ongeza Bollinger Bands, Stochastic Oscillator, ATR
- Onyesha Order Blocks na FVG moja kwa moja juu ya candlestick chart (overlay)
- Weka backend (Cloud Function) inayotumia LLM (kama Claude API) kusoma
  habari za forex na kuongeza "sentiment score" kwenye uchambuzi
- Weka arifa za push (notifications) pale signal mpya ya STRONG BUY/SELL
  au BOS/CHoCH mpya inapotokea
- Historia ya signals (backtest) kuonyesha usahihi wa zamani
- Multi-timeframe confirmation (angalia 1h na 4h kwa pamoja)
- Ongeza jozi zaidi za metals/crypto (XAG/USD, ETH/USD, n.k.)

## ⚠️ Onyo Muhimu
App hii ni kwa **madhumuni ya kielimu na uchambuzi tu**. Si ushauri wa
kifedha. Forex trading ina hatari kubwa ya kupoteza fedha — fanya utafiti
wako mwenyewe na tumia risk management sahihi kabla ya kufanya maamuzi
yoyote ya kweli ya trading.
# yussmsai
