import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/revision_item.dart';
import 'active_review_screen.dart';

class RevisionsTab extends StatefulWidget {
  const RevisionsTab({super.key});

  @override
  _RevisionsTabState createState() => _RevisionsTabState();
}

class _RevisionsTabState extends State<RevisionsTab> {
  String? _selectedFolder;

  void _createBunch(BuildContext context, AppState state, List<RevisionItem> flashcards) {
    if (flashcards.isEmpty) return;
    
    final toBunch = flashcards.where((e) => e.folder == null || e.folder!.isEmpty).toList();

    showDialog(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          backgroundColor: const Color(0xFF262626),
          title: const Text("Create Flashcard Bunch", style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: ctrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: "Bunch Name", hintStyle: TextStyle(color: Colors.white38)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                final name = ctrl.text.trim();
                if (name.isNotEmpty) Navigator.pop(ctx, name);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent, foregroundColor: Colors.white),
              child: const Text("Next"),
            )
          ],
        );
      }
    ).then((bunchName) {
      if (bunchName != null && bunchName is String && toBunch.isNotEmpty) {
        _showSelectionDialog(context, state, toBunch, bunchName);
      } else if (bunchName != null && toBunch.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No un-grouped flashcards available to bunch!")));
      }
    });
  }

  void _showSelectionDialog(BuildContext context, AppState state, List<RevisionItem> pool, String bunchName) {
    Set<String> selectedIds = {};
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              backgroundColor: const Color(0xFF202020),
              title: Text("Select items for '$bunchName'", style: const TextStyle(color: Colors.white, fontSize: 16)),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CheckboxListTile(
                      value: selectedIds.length == pool.length,
                      activeColor: Colors.indigoAccent,
                      title: const Text("Select All", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onChanged: (val) {
                        setStateSB(() {
                          if (val == true) {
                            selectedIds = pool.map((e) => e.id).toSet();
                          } else {
                            selectedIds.clear();
                          }
                        });
                      }
                    ),
                    const Divider(color: Colors.white10),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: pool.length,
                        itemBuilder: (c, i) {
                          final item = pool[i];
                          final isSel = selectedIds.contains(item.id);
                          return CheckboxListTile(
                            value: isSel,
                            activeColor: Colors.indigoAccent,
                            title: Text(item.title, style: const TextStyle(color: Colors.white)),
                            onChanged: (val) {
                              setStateSB(() {
                                if (val == true) selectedIds.add(item.id);
                                else selectedIds.remove(item.id);
                              });
                            }
                          );
                        }
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                 TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                 ElevatedButton(
                   onPressed: () {
                     List<RevisionItem> modified = [];
                     for (var item in pool) {
                       if (selectedIds.contains(item.id)) {
                         item.folder = bunchName;
                         modified.add(item);
                       }
                     }
                     if (modified.isNotEmpty) state.updateItems(modified);
                     Navigator.pop(ctx);
                   },
                   style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent, foregroundColor: Colors.white),
                   child: const Text("Group"),
                 )
              ]
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        final flashcards = state.items.where((e) => e.type == 'flashcard').toList();
        final topics = state.items.where((e) => e.type == 'topic').toList();
        final folders = flashcards.map((e) => e.folder).where((f) => f != null && f!.isNotEmpty).toSet().cast<String>().toList();
        
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text("Library", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
            actions: [
              IconButton(icon: const Icon(Icons.create_new_folder), onPressed: () => _createBunch(context, state, flashcards)),
            ],
          ),
          body: _selectedFolder == null 
             ? _buildRootView(folders, flashcards, topics)
             : _buildFolderView(state, _selectedFolder!, flashcards.where((e) => e.folder == _selectedFolder).toList()),
        );
      },
    );
  }

  Widget _buildRootView(List<String> folders, List<RevisionItem> allCards, List<RevisionItem> allTopics) {
    final uncategorizedCards = allCards.where((c) => c.folder == null || c.folder!.isEmpty).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        const Text("Flashcard Bunches", style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 16),
        _FolderTile(
           title: "All Flashcards", 
           count: allCards.length, 
           isAll: true,
           onTap: () => setState(() => _selectedFolder = "ALL_FLASHCARDS")
        ),
        ...folders.map((f) => _FolderTile(
           title: f, 
           count: allCards.where((c) => c.folder == f).length,
           onTap: () => setState(() => _selectedFolder = f),
        )),
        
        const SizedBox(height: 32),
        const Text("Uncategorized Flashcards", style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        if (uncategorizedCards.isEmpty) const Text("All cards are grouped!", style: TextStyle(color: Colors.white38)),
        ...uncategorizedCards.map((c) => _ItemTile(item: c)),

        const SizedBox(height: 32),
        const Text("Simple Topics", style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        if (allTopics.isEmpty) const Text("No topics structured.", style: TextStyle(color: Colors.white38)),
        ...allTopics.map((t) => _ItemTile(item: t)),
      ],
    );
  }

  Widget _buildFolderView(AppState state, String folderName, List<RevisionItem> items) {
    final isAll = folderName == "ALL_FLASHCARDS";
    final displayItems = isAll ? state.items.where((e) => e.type == 'flashcard').toList() : items;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _selectedFolder = null)),
              const SizedBox(width: 8),
              Expanded(child: Text(isAll ? "All Flashcards" : folderName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow, size: 16),
                label: const Text("Revise Bunch"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent, foregroundColor: Colors.white),
                onPressed: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => ActiveReviewScreen(
                      type: 'flashcard', 
                      folderFilter: isAll ? null : folderName,
                      isInfinityMode: false,
                   )));
                }
              )
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: displayItems.length,
            itemBuilder: (c, i) => _ItemTile(item: displayItems[i])
          ),
        )
      ],
    );
  }
}

class _FolderTile extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback onTap;
  final bool isAll;

  const _FolderTile({required this.title, required this.count, required this.onTap, this.isAll = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isAll ? const Color(0xFF3730A3).withValues(alpha: 0.3) : const Color(0xFF262626),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isAll ? Colors.indigoAccent.withValues(alpha: 0.5) : Colors.white10),
      ),
      child: ListTile(
        leading: Icon(isAll ? Icons.all_inbox : Icons.folder, color: isAll ? Colors.indigoAccent : Colors.amber),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        subtitle: Text("$count Cards", style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final RevisionItem item;
  const _ItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF202020),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        title: Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 14)),
        subtitle: Text("Level ${item.intervalIndex + 1} • Due: ${item.nextRevisionDate.month}/${item.nextRevisionDate.day}", style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ),
    );
  }
}
