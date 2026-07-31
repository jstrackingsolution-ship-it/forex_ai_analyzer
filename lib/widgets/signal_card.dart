import 'package:flutter/material.dart';
import '../models/signal.dart';

class OverallSignalCard extends StatelessWidget {
  final AnalysisResult result;

  const OverallSignalCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final signal = result.overallSignal;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [signal.color.withOpacity(0.25), signal.color.withOpacity(0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: signal.color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(signal.icon, color: signal.color, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  signal.label,
                  style: TextStyle(
                    color: signal.color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Uhakika (Confidence): ${(result.confidenceScore * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: result.confidenceScore,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    color: signal.color,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class IndicatorSignalTile extends StatelessWidget {
  final IndicatorSignal indicator;

  const IndicatorSignalTile({super.key, required this.indicator});

  @override
  Widget build(BuildContext context) {
    final signal = indicator.signal;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: signal.color, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(signal.icon, color: signal.color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      indicator.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      signal.label,
                      style: TextStyle(color: signal.color, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  indicator.reason,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
