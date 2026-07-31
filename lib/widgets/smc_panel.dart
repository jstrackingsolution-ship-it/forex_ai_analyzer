import 'package:flutter/material.dart';
import '../models/smc.dart';

/// Paneli inayoonyesha muhtasari wa Smart Money Concepts:
/// Market Structure (trend + BOS/CHoCH ya karibuni), Order Blocks, FVGs, Liquidity.
class SmcPanel extends StatelessWidget {
  final SmcResult smc;
  final int candleCount;

  const SmcPanel({super.key, required this.smc, required this.candleCount});

  @override
  Widget build(BuildContext context) {
    final activeObs = smc.orderBlocks.where((z) => !z.mitigated).toList();
    final activeFvgs = smc.fairValueGaps.where((z) => !z.mitigated).toList();
    final lastEvent = smc.structureEvents.isNotEmpty ? smc.structureEvents.last : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: smc.trend.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: smc.trend.color.withOpacity(0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.account_tree_outlined, color: smc.trend.color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      smc.trend.label,
                      style: TextStyle(color: smc.trend.color, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
              if (lastEvent != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Tukio la mwisho: ${lastEvent.type.label} kwenye candle #${lastEvent.index + 1} '
                  'ya $candleCount (bei ${lastEvent.price.toStringAsFixed(5)})',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade400),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _statChip('Order Blocks hai', activeObs.length, Icons.crop_square)),
            const SizedBox(width: 8),
            Expanded(child: _statChip('FVG hai', activeFvgs.length, Icons.blur_linear)),
            const SizedBox(width: 8),
            Expanded(
              child: _statChip('Liquidity Pools', smc.liquidityPools.length, Icons.waves),
            ),
          ],
        ),
        if (activeObs.isNotEmpty || activeFvgs.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...activeObs.take(3).map((z) => _zoneTile(z.type.label, z.type.color, z.top, z.bottom)),
          ...activeFvgs.take(3).map((z) => _zoneTile(z.type.label, z.type.color, z.top, z.bottom)),
        ],
      ],
    );
  }

  Widget _statChip(String label, int value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(height: 4),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _zoneTile(String label, Color color, double top, double bottom) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          Text(
            '${bottom.toStringAsFixed(5)} - ${top.toStringAsFixed(5)}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
