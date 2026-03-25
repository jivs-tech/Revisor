import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/star_logo.dart';
import '../utils/flip_page_route.dart';
import 'active_review_screen.dart';
import 'streak_calendar_screen.dart';
import 'add_tab.dart';
import '../services/spaced_repetition.dart';
import '../utils/quotes.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import '../models/reminder_item.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<AppState>(context, listen: false);
      if (state.hasIntroPlayed) {
        _introController.value = 1.0;
      } else {
        _introController.forward().then((_) => state.setIntroPlayed());
      }
    });
  }

  void _showMotivationalQuote() {
    final quote = motivationalQuotes[Random().nextInt(motivationalQuotes.length)];
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Quote",
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white12),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 5),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amberAccent, size: 40),
                  const SizedBox(height: 24),
                  Text(
                    quote,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Keep Grinding", style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
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
                      child: Stack(
                        children: [
                          child!,
                          // Notification Bell
                          Positioned(
                            top: 100,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.notifications_outlined, color: Colors.white54, size: 22),
                              onPressed: () => _showNotificationCenter(context, state),
                            ),
                          ),
                        ],
                      ),
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
                        _NotionActionBtn(icon: Icons.add_task_outlined, label: "New Task", onTap: () => _showAddReminderDialog(context, state, ReminderType.task)),
                        _NotionActionBtn(icon: Icons.notification_add_outlined, label: "New Reminder", onTap: () => _showAddReminderDialog(context, state, ReminderType.date)),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Reminders & To-Do System
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Personal Reminders", style: TextStyle(fontSize: 14, color: Colors.white54, fontWeight: FontWeight.w500)),
                        if (state.reminders.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("${(state.reminderCompletionProgress * 100).toInt()}% ", style: const TextStyle(fontSize: 12, color: Color(0xFF9155FD), fontWeight: FontWeight.bold)),
                              _CelebrationBolt(isCompleted: state.reminderCompletionProgress >= 1.0),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _CompletionRod(progress: state.reminderCompletionProgress),
                    const SizedBox(height: 20),
                    _ReminderListView(reminders: state.reminders),

                    const SizedBox(height: 40),

                    // Stats Section
                    const Text("Overview", style: TextStyle(fontSize: 14, color: Colors.white54, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StreakCalendarScreen())),
                            child: _NotionStatCard(label: "Learning Streak", value: "${state.streak} Days 🔥"),
                          ),
                        ),
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
                                _showMotivationalQuote();
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

void _showNotificationCenter(BuildContext context, AppState state) {
  final dueRevisionItems = state.items.where((i) => i.nextRevisionDate.isBefore(DateTime.now().add(const Duration(hours: 1)))).toList();
  final importantReminders = state.reminders.where((r) => r.isImportant && !r.isCompleted).toList();
  final upcomingReminders = state.reminders.where((r) => !r.isCompleted && !r.isImportant).toList();

  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1E1E1E),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Notification Center", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.white38)),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                if (dueRevisionItems.isNotEmpty) ...[
                  const _SectionHeader(title: "Ready for Revision"),
                  ...dueRevisionItems.map((i) => _AlertTile(
                    icon: i.type == 'topic' ? Icons.description_outlined : Icons.style_outlined,
                    title: i.title,
                    subtitle: "Due now",
                    color: Colors.orangeAccent,
                  )),
                  const SizedBox(height: 20),
                ],
                if (importantReminders.isNotEmpty) ...[
                  const _SectionHeader(title: "Important Today"),
                  ...importantReminders.map((r) => _AlertTile(
                    icon: Icons.star,
                    title: r.title,
                    subtitle: r.dateTime != null ? DateFormat('h:mm a').format(r.dateTime!) : "Priority Task",
                    color: Colors.yellowAccent,
                  )),
                  const SizedBox(height: 20),
                ],
                if (upcomingReminders.isNotEmpty) ...[
                  const _SectionHeader(title: "Upcoming Reminders"),
                  ...upcomingReminders.map((r) => _AlertTile(
                    icon: Icons.access_time,
                    title: r.title,
                    subtitle: r.dateTime != null ? DateFormat('MMM d, h:mm a').format(r.dateTime!) : "To-do",
                    color: Colors.white38,
                  )),
                ],
                if (dueRevisionItems.isEmpty && importantReminders.isEmpty && upcomingReminders.isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text("All caught up! ✨", style: TextStyle(color: Colors.white24)),
                  )),
              ],
            ),
          )
        ],
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _AlertTile({required this.icon, required this.title, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _showAddReminderDialog(BuildContext context, AppState state, ReminderType type) {
  final titleController = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(type == ReminderType.task ? "New Task" : "New Date Reminder", style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: type == ReminderType.task ? "What needs to be done?" : "Event name...",
                hintStyle: const TextStyle(color: Colors.white24),
                border: InputBorder.none,
              ),
            ),
            if (type == ReminderType.date) ...[
              const SizedBox(height: 16),
              const Text("Notification Time", style: TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(height: 8),
              Row(
                children: [
                   Expanded(
                     child: OutlinedButton.icon(
                       icon: const Icon(Icons.calendar_today, size: 14),
                       label: Text(selectedDate == null ? "Date" : DateFormat('MMM d').format(selectedDate!), style: const TextStyle(fontSize: 11)),
                       style: OutlinedButton.styleFrom(foregroundColor: Colors.white70, side: const BorderSide(color: Colors.white10)),
                       onPressed: () async {
                         final picked = await showDatePicker(
                           context: context, 
                           initialDate: DateTime.now(),
                           firstDate: DateTime.now(),
                           lastDate: DateTime.now().add(const Duration(days: 365)),
                         );
                         if (picked != null) setDialogState(() => selectedDate = picked);
                       },
                     ),
                   ),
                   const SizedBox(width: 8),
                   Expanded(
                     child: OutlinedButton.icon(
                       icon: const Icon(Icons.access_time, size: 14),
                       label: Text(selectedTime == null ? "Time" : selectedTime!.format(context), style: const TextStyle(fontSize: 11)),
                       style: OutlinedButton.styleFrom(foregroundColor: Colors.white70, side: const BorderSide(color: Colors.white10)),
                       onPressed: () async {
                         final picked = await showTimePicker(
                           context: context, 
                           initialTime: TimeOfDay.now(),
                           builder: (context, child) {
                             return MediaQuery(
                               data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
                               child: Theme(
                                 data: ThemeData.dark().copyWith(
                                   colorScheme: const ColorScheme.dark(
                                     primary: Colors.indigoAccent,
                                     onPrimary: Colors.white,
                                     surface: Color(0xFF1A1A1A),
                                     onSurface: Colors.white,
                                   ),
                                   timePickerTheme: const TimePickerThemeData(
                                     dayPeriodTextColor: Colors.white,
                                     dayPeriodColor: Colors.indigoAccent,
                                   ),
                                 ),
                                 child: child!,
                               ),
                             );
                           }
                         );
                         if (picked != null) setDialogState(() => selectedTime = picked);
                       },
                     ),
                   ),
                ],
              )
            ]
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              
              if (type == ReminderType.date && (selectedDate == null || selectedTime == null)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please select both date and time for the reminder!")),
                );
                return;
              }

              DateTime? finalDate;
              if (selectedDate != null && selectedTime != null) {
                finalDate = DateTime(
                  selectedDate!.year, selectedDate!.month, selectedDate!.day,
                  selectedTime!.hour, selectedTime!.minute
                );
              }

              state.addReminder(ReminderItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: titleController.text.trim(),
                type: type,
                dateTime: finalDate,
                createdAt: DateTime.now(),
              ));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent),
            child: const Text("Add", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    ),
  );
}

class _CelebrationBolt extends StatefulWidget {
  final bool isCompleted;
  const _CelebrationBolt({required this.isCompleted});

  @override
  State<_CelebrationBolt> createState() => _CelebrationBoltState();
}

class _CelebrationBoltState extends State<_CelebrationBolt> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _rotation;
  late Animation<double> _messageOpacity;
  bool _played = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 6.0).chain(CurveTween(curve: Curves.easeOutBack)), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 6.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 70),
    ]).animate(_controller);

    _rotation = Tween<double>(begin: 0, end: 4 * pi).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.8, curve: Curves.fastOutSlowIn)),
    );

    _messageOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);

    if (widget.isCompleted) {
      _controller.forward();
      _played = true;
    }
  }

  @override
  void didUpdateWidget(_CelebrationBolt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted && !_played) {
      _controller.forward(from: 0);
      _played = true;
    } else if (!widget.isCompleted) {
      _played = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotation.value,
              child: Transform.scale(
                scale: _scale.value,
                child: Text(
                  "⚡",
                  style: TextStyle(
                    fontSize: 12,
                    shadows: [
                      Shadow(
                        color: Colors.yellowAccent.withOpacity(0.8),
                        blurRadius: 10 * _scale.value,
                        offset: Offset.zero,
                      ),
                      Shadow(
                        color: Colors.orangeAccent.withOpacity(0.4),
                        blurRadius: 20 * _scale.value,
                        offset: Offset.zero,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        Positioned(
          top: -40,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _messageOpacity.value.clamp(0.0, 1.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.yellowAccent.withOpacity(0.3)),
                  ),
                  child: const Text(
                    "BRAVO ╰(°▽°)╯",
                    style: TextStyle(color: Colors.yellowAccent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CompletionRod extends StatelessWidget {
  final double progress;
  const _CompletionRod({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepPurple.withOpacity(0.6),
                Colors.purpleAccent.withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.purpleAccent.withOpacity(0.4 * progress),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderListView extends StatefulWidget {
  final List<ReminderItem> reminders;
  const _ReminderListView({required this.reminders});

  @override
  State<_ReminderListView> createState() => _ReminderListViewState();
}

class _ReminderListViewState extends State<_ReminderListView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reminders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF262626),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: const Center(child: Text("No reminders yet.", style: TextStyle(color: Colors.white24))),
      );
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent,
          indicatorColor: Colors.greenAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: const [Tab(text: "ALL"), Tab(text: "PENDING"), Tab(text: "DONE")],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildList(_sortReminders(widget.reminders)),
              _buildList(_sortReminders(widget.reminders.where((r) => !r.isCompleted).toList())),
              _buildList(_sortReminders(widget.reminders.where((r) => r.isCompleted).toList())),
            ],
          ),
        ),
      ],
    );
  }

  List<ReminderItem> _sortReminders(List<ReminderItem> list) {
    return List<ReminderItem>.from(list)..sort((a, b) {
      if (a.isImportant && !b.isImportant) return -1;
      if (!a.isImportant && b.isImportant) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  Widget _buildList(List<ReminderItem> items) {
    if (items.isEmpty) return const Center(child: Text("Nothing here.", style: TextStyle(color: Colors.white24)));
    
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onDoubleTap: () => Provider.of<AppState>(context, listen: false).toggleImportance(item.id),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF202020),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: item.isImportant ? Colors.yellowAccent.withOpacity(0.2) : Colors.white10),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: IconButton(
                icon: Icon(
                  item.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: item.isCompleted ? Colors.greenAccent : Colors.white38,
                ),
                onPressed: () => Provider.of<AppState>(context, listen: false).toggleReminder(item.id),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        color: item.isCompleted ? Colors.white38 : (item.isImportant ? Colors.yellowAccent.withOpacity(0.9) : Colors.white),
                        decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                        fontSize: 14,
                        fontWeight: item.isImportant ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (item.isImportant)
                    const Icon(Icons.star, color: Colors.yellowAccent, size: 14),
                ],
              ),
              subtitle: item.dateTime != null 
                ? Text(
                    DateFormat('MMM d, hh:mm a').format(item.dateTime!),
                    style: const TextStyle(color: Colors.white24, fontSize: 11),
                  )
                : null,
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 16, color: Colors.white24),
                onPressed: () => Provider.of<AppState>(context, listen: false).deleteReminder(item.id),
              ),
            ),
          ),
        );
      },
    );
  }
}

