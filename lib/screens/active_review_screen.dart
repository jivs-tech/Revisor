import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/app_state.dart';
import '../models/revision_item.dart';
import '../services/spaced_repetition.dart';

class ActiveReviewScreen extends StatefulWidget {
  final String type; // 'flashcard' or 'topic'
  final bool isInfinityMode;
  final String? folderFilter;
  final String? smartFilter; // 'NEEDS_REVISION', 'KEEP_GOING', 'MASTERED'

  const ActiveReviewScreen({
    super.key, 
    required this.type, 
    this.isInfinityMode = false,
    this.folderFilter,
    this.smartFilter,
  });

  @override
  _ActiveReviewScreenState createState() => _ActiveReviewScreenState();
}

class _ActiveReviewScreenState extends State<ActiveReviewScreen> with SingleTickerProviderStateMixin {
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  bool _isAnswerRevealed = false;
  int _currentIndex = 0;
  List<RevisionItem> _dueTopics = [];

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _reveal() {
    if (widget.type == 'topic') return; // Simple topics don't flip
    if (_isAnswerRevealed) return;
    setState(() => _isAnswerRevealed = true);
    _flipCtrl.forward();
  }

  void _processOutcome(bool success, AppState state) {
    if (_dueTopics.isEmpty) return;
    final item = _dueTopics[_currentIndex];
    
    if (success) {
      item.stats.successfulRecalls++;
      item.intervalIndex++;
      // Track history for the streak calendar & graph (Success)
      item.revisionHistory.add(RevisionHistoryEntry(date: DateTime.now(), isSuccess: true));
      state.addPoints(widget.type == 'flashcard' ? 10 : 5);
    } else {
      item.intervalIndex = 0;
      // Track history for the graph (Failure/Forgot)
      item.revisionHistory.add(RevisionHistoryEntry(date: DateTime.now(), isSuccess: false));
    }
    
    item.stats.attempts++;
    final result = SpacedRepetition.calculateNextRevision(item.intervalIndex, success, state.intervals);
    item.nextRevisionDate = result['nextRevisionDate'] as DateTime;
    item.intervalIndex = result['intervalIndex'] as int;
    
    state.updateItem(item);
    
    setState(() {
      _isAnswerRevealed = false;
      _currentIndex++;
      
      // Infinity Loop Logic
      if (widget.isInfinityMode && _currentIndex >= _dueTopics.length) {
        _dueTopics.shuffle();
        _currentIndex = 0;
      }
    });

    _flipCtrl.reset();
  }

  void _nextCard(bool success, AppState state) {
    if (_dueTopics.isEmpty) return;
    
    // In standard mode, we process outcomes. In infinite/bunch mode, we also process if user wants progress.
    // User requested "allow them to revise as many times as they want" - so we stay in the loop.
    _processOutcome(success, state);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        // Initial population
        if (_currentIndex == 0 && _dueTopics.isEmpty) {
          var pool = state.items.where((t) => t.type == widget.type);
          
          if (widget.smartFilter != null) {
            if (widget.smartFilter == 'NEEDS_REVISION') {
              _dueTopics = state.needsRevisionItems..shuffle();
            } else if (widget.smartFilter == 'KEEP_GOING') {
              _dueTopics = state.keepGoingItems..shuffle();
            } else if (widget.smartFilter == 'MASTERED') {
              _dueTopics = state.masteredItems..shuffle();
            }
          } else {
            if (widget.folderFilter != null) {
              pool = pool.where((t) => t.folder == widget.folderFilter);
            }
            
            if (widget.isInfinityMode || widget.folderFilter != null) {
              _dueTopics = pool.toList()..shuffle();
            } else {
              _dueTopics = pool.where((t) => SpacedRepetition.isDueToday(t.nextRevisionDate)).toList();
            }
          }
        }

        // Empty handling / Completion
        if (_dueTopics.isEmpty || _currentIndex >= _dueTopics.length) {
          // Find the actual next revision item for soft prompting
          var upcomingPool = state.items.where((t) => t.type == widget.type && t.nextRevisionDate.isAfter(DateTime.now())).toList();
          if (widget.folderFilter != null) {
            upcomingPool = upcomingPool.where((t) => t.folder == widget.folderFilter).toList();
          }
          upcomingPool.sort((a,b) => a.nextRevisionDate.compareTo(b.nextRevisionDate));
          
          final String upcomingMsg = upcomingPool.isNotEmpty 
            ? "Upcoming revision: '${upcomingPool.first.title}' on ${upcomingPool.first.nextRevisionDate.month}/${upcomingPool.first.nextRevisionDate.day}"
            : "No future revisions scheduled.";

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.task_alt, size: 64, color: Colors.greenAccent),
                  const SizedBox(height: 24),
                  const Text("Session Complete", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Text(
                      upcomingMsg, 
                      style: const TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 0.5), 
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_dueTopics.isNotEmpty)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text("Revise Again", style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigoAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            setState(() {
                              _currentIndex = 0;
                              _dueTopics.shuffle();
                            });
                          },
                        )
                      else if (state.items.where((t) => t.type == widget.type).isNotEmpty)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.play_circle_outline),
                          label: const Text("Practice All", style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigoAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            setState(() {
                              _dueTopics = state.items.where((t) => t.type == widget.type).toList()..shuffle();
                              _currentIndex = 0;
                            });
                          },
                        ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_back),
                        label: const Text("Return", style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF262626),
                          foregroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        }

        final item = _dueTopics[_currentIndex];

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
            title: Text(widget.isInfinityMode ? "Infinity ${widget.type == 'topic' ? 'Topics' : 'Cards'} (∞)" : "${_currentIndex + 1} / ${_dueTopics.length}", 
                        style: const TextStyle(fontSize: 14, color: Colors.white54, letterSpacing: 1.2)),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              children: [
                Expanded(
                  child: widget.type == 'flashcard' ? _buildFlashcard(item) : _buildSimpleTopic(item),
                ),
                const SizedBox(height: 32),
                AnimatedOpacity(
                  opacity: (widget.type == 'flashcard' && !_isAnswerRevealed) ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.exit_to_app, color: Colors.white54, size: 16),
                          label: const Text("Exit", style: TextStyle(color: Colors.white54, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            side: const BorderSide(color: Colors.white10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: (widget.type == 'topic' || _isAnswerRevealed) ? () => _nextCard(false, state) : null,
                          icon: const Icon(Icons.thumb_down, color: Colors.redAccent, size: 16),
                          label: const Text("Forgot", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20), 
                            side: const BorderSide(color: Colors.redAccent, width: 0.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (widget.type == 'topic' || _isAnswerRevealed) ? () => _nextCard(true, state) : null,
                          icon: const Icon(Icons.thumb_up, color: Colors.greenAccent, size: 16),
                          label: const Text("Got It", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent.withValues(alpha: 0.1), 
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFlashcard(RevisionItem item) {
    return GestureDetector(
      onTap: _reveal,
      child: AnimatedBuilder(
        animation: _flipAnim,
        builder: (context, child) {
          final angle = _flipAnim.value * math.pi;
          final isFront = angle <= math.pi / 2;
          return Transform(
            transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(angle),
            alignment: Alignment.center,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF262626), 
                borderRadius: BorderRadius.circular(20), 
                border: Border.all(color: Colors.white10),
                boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 10), blurRadius: 30)],
              ),
              padding: const EdgeInsets.all(32),
              child: isFront
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item.title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: Colors.white), textAlign: TextAlign.center),
                        const SizedBox(height: 40),
                        const Text("Tap to reveal", style: TextStyle(color: Colors.white38, letterSpacing: 2, fontSize: 12)),
                      ],
                    )
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(item.title, style: const TextStyle(fontSize: 14, color: Colors.white38, letterSpacing: 1.0)),
                            const SizedBox(height: 24),
                            Text(item.description ?? '', style: const TextStyle(fontSize: 20, height: 1.6, color: Colors.white), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSimpleTopic(RevisionItem item) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: const Color(0xFF262626), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book, color: Colors.teal, size: 48),
          const SizedBox(height: 24),
          Text(item.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          const Text("Did you study this topic today?", style: TextStyle(color: Colors.white54, fontSize: 14)),
        ],
      ),
    );
  }
}
