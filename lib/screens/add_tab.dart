import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/revision_item.dart';
import '../services/spaced_repetition.dart';

class AddTab extends StatefulWidget {
  final int initialIndex;
  const AddTab({super.key, this.initialIndex = 0});

  @override
  _AddTabState createState() => _AddTabState();
}

class _AddTabState extends State<AddTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialIndex);
  }

  void _saveItem(BuildContext context, String type) {
    if (_titleCtrl.text.trim().isEmpty) return;
    if (type == 'flashcard' && _descCtrl.text.trim().isEmpty) return;
    
    final state = Provider.of<AppState>(context, listen: false);
    
    final item = RevisionItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      description: type == 'flashcard' ? _descCtrl.text.trim() : null,
      type: type,
      createdAt: DateTime.now(),
      nextRevisionDate: DateTime.now(),
      intervalIndex: -1,
    );

    state.addItem(item);
    _titleCtrl.clear();
    _descCtrl.clear();

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${type == 'topic' ? 'Topic' : 'Flashcard'} saved!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Items"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.style), text: "Flashcard"),
            Tab(icon: Icon(Icons.checklist), text: "Simple Topic"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildForm('flashcard'),
          _buildForm('topic'),
        ],
      ),
    );
  }

  Widget _buildForm(String type) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Title / Concept', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          if (type == 'flashcard') ...[
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Answer / Description', border: OutlineInputBorder()),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
          ],
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text("Save to Library"),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            onPressed: () => _saveItem(context, type),
          )
        ],
      ),
    );
  }
}
