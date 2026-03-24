import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/revision_item.dart';
import 'package:intl/intl.dart';

class StreakCalendarScreen extends StatefulWidget {
  const StreakCalendarScreen({super.key});

  @override
  State<StreakCalendarScreen> createState() => _StreakCalendarScreenState();
}

class _StreakCalendarScreenState extends State<StreakCalendarScreen> {
  DateTime _focusedDay = DateTime.now();

  void _showStudiedItems(BuildContext context, DateTime date, List<RevisionItem> items) {
    // Filter items studied on this exact day (ignoring time)
    final studied = items.where((item) {
      return item.revisionHistory.any((d) => 
        d.year == date.year && d.month == date.month && d.day == date.day
      );
    }).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Theme.of(context).dividerColor)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('MMMM d, yyyy').format(date), style: TextStyle(fontSize: 14, color: Theme.of(context).hintColor)),
            const Text("You Studied", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: studied.isEmpty 
          ? Text("No materials studied on this day.", style: TextStyle(color: Theme.of(context).hintColor))
          : SizedBox(
              width: double.maxFinite,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: studied.length,
                separatorBuilder: (_, __) => Divider(color: Theme.of(context).dividerColor),
                itemBuilder: (c, i) {
                  final item = studied[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(item.type == 'flashcard' ? Icons.style : Icons.article, color: Colors.indigoAccent, size: 20),
                    title: Text(item.title, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                    subtitle: Text(item.type.toUpperCase(), style: TextStyle(color: Theme.of(context).hintColor, fontSize: 10)),
                  );
                },
              ),
            ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startingWeekday = firstDayOfMonth.weekday;
    final leadingEmptyCells = startingWeekday - 1; 

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Learning Streak"),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: Consumer<AppState>(
        builder: (context, state, child) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _focusedDay,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _focusedDay = DateTime(picked.year, picked.month));
                      },
                      child: Row(
                        children: [
                          Text(
                            DateFormat('MMMM yyyy').format(_focusedDay),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down, size: 20),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1)),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) => 
                    Expanded(child: Center(child: Text(d, style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12, fontWeight: FontWeight.bold))))
                  ).toList(),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: leadingEmptyCells + daysInMonth,
                  itemBuilder: (context, index) {
                    if (index < leadingEmptyCells) return const SizedBox();
                    
                    final day = index - leadingEmptyCells + 1;
                    final date = DateTime(_focusedDay.year, _focusedDay.month, day);
                    final isToday = date.year == DateTime.now().year && date.month == DateTime.now().month && date.day == DateTime.now().day;
                    
                    final hasStudied = state.items.any((item) => 
                      item.revisionHistory.any((h) => h.year == date.year && h.month == date.month && h.day == date.day)
                    );

                    return GestureDetector(
                      onDoubleTap: () => _showStudiedItems(context, date, state.items),
                      child: Container(
                        decoration: BoxDecoration(
                          color: hasStudied ? Colors.greenAccent.withValues(alpha: 0.35) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isToday ? Colors.indigoAccent : (hasStudied ? Colors.greenAccent.withValues(alpha: 0.6) : Theme.of(context).dividerColor),
                            width: isToday ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            day.toString(),
                            style: TextStyle(
                              color: isToday ? Colors.indigoAccent : (hasStudied ? (state.isDarkMode ? Colors.greenAccent : Colors.green[800]) : Theme.of(context).hintColor),
                              fontWeight: isToday || hasStudied ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Theme.of(context).hintColor),
                    const SizedBox(width: 8),
                    Text("Double tap a date to see studied materials", style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}
