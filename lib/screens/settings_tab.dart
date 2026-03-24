import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  void _addInterval(BuildContext context, AppState state) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Add Level (Days)", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: "Enter number of days"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(ctrl.text);
              if (val != null && val > 0) {
                final newIntervals = List<int>.from(state.intervals);
                newIntervals.add(val);
                newIntervals.sort();
                state.updateIntervals(newIntervals);
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _editInterval(BuildContext context, AppState state, int index) {
    final ctrl = TextEditingController(text: state.intervals[index].toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Edit Interval (Days)", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(ctrl.text);
              if (val != null && val > 0) {
                final newIntervals = List<int>.from(state.intervals);
                newIntervals[index] = val;
                newIntervals.sort();
                state.updateIntervals(newIntervals);
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, state, child) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Text("Spaced Repetition Intervals", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Configure the days between each successful recall level.", style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 24),
            ...List.generate(state.intervals.length, (index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: ListTile(
                  title: Text("Level ${index + 1}"),
                  subtitle: Text("${state.intervals[index]} Days"),
                  trailing: const Icon(Icons.edit, color: Colors.white38),
                  onTap: () => _editInterval(context, state, index),
                ),
              );
            }),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _addInterval(context, state),
                icon: const Icon(Icons.add),
                label: const Text("Add New Level"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigoAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
    });
  }
}
