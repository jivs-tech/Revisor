import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/revision_item.dart';

enum StatFilter { defaultView, lowestAccuracy, lowestSpan }

class StatsTab extends StatefulWidget {
  const StatsTab({super.key});

  @override
  _StatsTabState createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  StatFilter _filter = StatFilter.defaultView;

  List<RevisionItem> _applyFilter(List<RevisionItem> items) {
    List<RevisionItem> sorted = List.from(items);
    if (_filter == StatFilter.lowestAccuracy) {
      sorted.sort((a, b) {
        double accA = a.stats.attempts > 0 ? a.stats.successfulRecalls / a.stats.attempts : 0;
        double accB = b.stats.attempts > 0 ? b.stats.successfulRecalls / b.stats.attempts : 0;
        return accA.compareTo(accB);
      });
    } else if (_filter == StatFilter.lowestSpan) {
      sorted.sort((a, b) => a.intervalIndex.compareTo(b.intervalIndex));
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final cards = _applyFilter(state.items.where((i) => i.type == 'flashcard').toList());
        final topics = _applyFilter(state.items.where((i) => i.type == 'topic').toList());

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Insights",
                        style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: -0.5),
                      ),
                      PopupMenuButton<StatFilter>(
                        icon: const Icon(Icons.tune, color: Colors.white70),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        color: const Color(0xFF262626),
                        onSelected: (val) => setState(() => _filter = val),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: StatFilter.defaultView, child: Text("Default View", style: TextStyle(color: Colors.white))),
                          const PopupMenuItem(value: StatFilter.lowestAccuracy, child: Text("Lowest Accuracy First", style: TextStyle(color: Colors.white))),
                          const PopupMenuItem(value: StatFilter.lowestSpan, child: Text("Lowest Revision Span", style: TextStyle(color: Colors.white))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  if (_filter != StatFilter.defaultView) 
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.withValues(alpha: 0.3))),
                      child: Row(
                        children: [
                          const Icon(Icons.filter_alt, size: 16, color: Colors.amber),
                          const SizedBox(width: 8),
                          Text(
                            "Filtered: ${_filter == StatFilter.lowestAccuracy ? 'Lowest Accuracy First' : 'Lowest Span First'}",
                            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  
                  const Text("Flashcards", style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  _buildNotionTable(cards),

                  const SizedBox(height: 40),

                  const Text("Simple Topics", style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  _buildNotionTable(topics),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildNotionTable(List<RevisionItem> items) {
    if (items.isEmpty) return const Text("No items available.", style: TextStyle(color: Colors.white38));
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF202020),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Theme(
          data: ThemeData.dark().copyWith(
            dividerColor: Colors.white10,
          ),
          child: DataTable(
            headingTextStyle: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
            dataTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
            columns: const [
              DataColumn(label: Text('Item Name')),
              DataColumn(label: Text('Current Span')),
              DataColumn(label: Text('Accuracy')),
            ],
            rows: items.map((item) {
              final acc = item.stats.attempts > 0 ? ((item.stats.successfulRecalls / item.stats.attempts) * 100).round() : 0;
              return DataRow(
                cells: [
                  DataCell(Text(item.title, style: const TextStyle(fontWeight: FontWeight.w500))),
                  DataCell(Text('Lvl ${item.intervalIndex + 1}')),
                  DataCell(
                    Row(
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: acc > 75 ? Colors.greenAccent : (acc > 40 ? Colors.orangeAccent : Colors.redAccent),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('$acc%'),
                      ],
                    )
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
