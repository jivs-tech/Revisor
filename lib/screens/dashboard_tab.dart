import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/star_logo.dart';
import '../utils/flip_page_route.dart';
import 'active_review_screen.dart';
import 'add_tab.dart';
import '../services/spaced_repetition.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  _DashboardTabState createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> with SingleTickerProviderStateMixin {
  late AnimationController _introController;
  late Animation<double> _starScale;
  late Animation<Alignment> _starAlignment;
  late Animation<double> _uiOpacity;
  late Animation<Offset> _uiSlide;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));

    _starScale = Tween<double>(begin: 3.5, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: const Interval(0.2, 0.6, curve: Curves.easeInOutCubic)),
    );

    _starAlignment = AlignmentTween(begin: Alignment.center, end: Alignment.topLeft).animate(
      CurvedAnimation(parent: _introController, curve: const Interval(0.2, 0.6, curve: Curves.easeInOutCubic)),
    );

    _uiOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: const Interval(0.6, 1.0, curve: Curves.easeIn)),
    );

    _uiSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _introController, curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic)),
    );

    _introController.forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, state, child) {
      final dueItems = state.items.where((t) => SpacedRepetition.isDueToday(t.nextRevisionDate));
      final dueTopicsCount = dueItems.where((t) => t.type == 'topic').length;
      final dueCardsCount = dueItems.where((t) => t.type == 'flashcard').length;

      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              // The UI Content (Fades and Slides in)
              AnimatedBuilder(
                animation: _introController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _uiOpacity.value,
                    child: SlideTransition(
                      position: _uiSlide,
                      child: child,
                    ),
                  );
                },
                child: ListView(
                  padding: const EdgeInsets.only(top: 100.0, left: 24.0, right: 24.0, bottom: 24.0),
                  children: [
                    const Text(
                      "NeuroRevise / Home",
                      style: TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Dashboard",
                      style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 32),

                    // Quick Actions (Notion Aesthetic Grid)
                    const Text("Quick Actions", style: TextStyle(fontSize: 14, color: Colors.white54, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _NotionActionBtn(icon: Icons.style_outlined, label: "Add Card", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTab(initialIndex: 0)))),
                        _NotionActionBtn(icon: Icons.text_snippet_outlined, label: "Add Topic", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTab(initialIndex: 1)))),
                        _NotionActionBtn(icon: Icons.all_inclusive, label: "Infinity Test", onTap: () => Navigator.push(context, FlipPageRoute(page: const ActiveReviewScreen(type: 'flashcard', isInfinityMode: true)))),
                        _NotionActionBtn(icon: Icons.psychology_outlined, label: "Daily Recall", onTap: () => Navigator.push(context, FlipPageRoute(page: const ActiveReviewScreen(type: 'flashcard')))),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Stats Section
                    const Text("Overview", style: TextStyle(fontSize: 14, color: Colors.white54, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _NotionStatCard(label: "Learning Streak", value: "${state.streak} Days 🔥")),
                        const SizedBox(width: 16),
                        Expanded(child: _NotionStatCard(label: "Total Points", value: "${state.points} Pts ★")),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Active Tasks
                    const Text("Today's Tasks", style: TextStyle(fontSize: 14, color: Colors.white54, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    _NotionTaskItem(
                      title: "Flashcard Recall",
                      subtitle: "$dueCardsCount cards pending",
                      onTap: () => Navigator.push(context, FlipPageRoute(page: const ActiveReviewScreen(type: 'flashcard'))),
                    ),
                    const SizedBox(height: 8),
                    _NotionTaskItem(
                      title: "Topic Revisions",
                      subtitle: "$dueTopicsCount topics pending",
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActiveReviewScreen(type: 'topic'))),
                    ),
                  ],
                ),
              ),

              // The Star Logo (Animated across screen)
              AnimatedBuilder(
                animation: _introController,
                builder: (context, child) {
                  return Align(
                    alignment: _starAlignment.value,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                      child: Transform.scale(
                        scale: _starScale.value,
                        child: SizedBox(
                          height: 60,
                          width: 60,
                          child: StarLogo(
                            onFlipTriggered: () {
                              if (_introController.isCompleted) {
                                Navigator.push(context, FlipPageRoute(page: const ActiveReviewScreen(type: 'flashcard')));
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _NotionActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NotionActionBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF262626), // Notion subtle elevated gray
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white70),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _NotionStatCard extends StatelessWidget {
  final String label;
  final String value;

  const _NotionStatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }
}

class _NotionTaskItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NotionTaskItem({required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF202020),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white54)),
              ],
            ),
            const Icon(Icons.arrow_forward, size: 16, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
