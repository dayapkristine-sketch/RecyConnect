import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import 'admin_widgets.dart';

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('System settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionHeader('Material categories'),
          _EditableList(
            hint: 'New category (e.g. Rubber)',
            items: app.materialCategories,
            onAdd: app.addCategory,
            onRemove: app.removeCategory,
          ),
          const SectionHeader('Collection status labels'),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(label: Text('Posted')),
              Icon(Icons.arrow_forward, size: 16),
              Chip(label: Text('Accepted')),
              Icon(Icons.arrow_forward, size: 16),
              Chip(label: Text('Collected / Sold')),
              Chip(label: Text('Cancelled')),
            ],
          ),
          const SectionHeader('Cancellation reasons'),
          _EditableList(
            hint: 'New reason',
            items: app.cancellationReasons,
            onAdd: app.addReason,
            onRemove: app.removeReason,
          ),
        ],
      ),
    );
  }
}

class _EditableList extends StatefulWidget {
  const _EditableList({
    required this.hint,
    required this.items,
    required this.onAdd,
    required this.onRemove,
  });
  final String hint;
  final List<String> items;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  State<_EditableList> createState() => _EditableListState();
}

class _EditableListState extends State<_EditableList> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    widget.onAdd(_controller.text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final item in widget.items)
                  InputChip(
                    label: Text(item),
                    onDeleted: () => widget.onRemove(item),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _add(),
                    decoration: InputDecoration(hintText: widget.hint),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: AdminColors.mid),
                  onPressed: _add,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
