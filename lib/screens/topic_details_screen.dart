import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/revision_item.dart';
import '../providers/app_state.dart';
import '../widgets/forgetting_curve_graph.dart';
import 'active_review_screen.dart';

class TopicDetailsScreen extends StatelessWidget {
  final RevisionItem item;

  const TopicDetailsScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final isDark = state.isDarkMode;
    
    double accuracy = item.stats.attempts > 0 
        ? (item.stats.successfulRecalls / item.stats.attempts) * 100 
        : 100.0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Details",
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildHeader(isDark),
          const SizedBox(height: 32),
          _buildStatsRow(accuracy, isDark),
          const SizedBox(height: 32),
          const Text(
            "Forgetting Curve",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigoAccent),
          ),
          const SizedBox(height: 12),
            ForgettingCurveGraph.individual(
              item: item,
              isDarkMode: Theme.of(context).brightness == Brightness.dark,
            ),
          const SizedBox(height: 32),
          _buildDescription(isDark),
          const SizedBox(height: 48),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.indigoAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            item.type.toUpperCase(),
            style: const TextStyle(color: Colors.indigoAccent, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item.title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(double accuracy, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _StatCard(
          label: "Accuracy",
          value: "${accuracy.toInt()}%",
          icon: Icons.track_changes,
          color: accuracy > 80 ? Colors.green : (accuracy < 40 ? Colors.red : Colors.orange),
          isDark: isDark,
        ),
        _StatCard(
          label: "Revisions",
          value: "${item.stats.attempts}",
          icon: Icons.history,
          color: Colors.blueAccent,
          isDark: isDark,
        ),
        _StatCard(
          label: "Level",
          value: "${item.intervalIndex + 1}",
          icon: Icons.trending_up,
          color: Colors.purpleAccent,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildDescription(bool isDark) {
    if (item.description == null || item.description!.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Content/Answer",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigoAccent),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Text(
            item.description!,
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 15),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ActiveReviewScreen(
            type: item.type,
            folderFilter: item.folder, // Still allow bunch context
          )));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigoAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: const Text("Revise Now", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
