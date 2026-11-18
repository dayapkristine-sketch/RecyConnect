import 'package:flutter/material.dart';

/// Replace with the admin-configurable list later (WBS 1.9.9).
const kCancelReasons = [
  'Changed my mind',
  'Materials already sold or given away',
  'Schedule conflict',
  'Price not agreed',
  'Could not be reached',
  'Wrong quantity or material type',
  'Other',
];

/// Returns the reason, or null if the user backed out.
Future<String?> askCancelReason(BuildContext context) => showDialog<String>(
  context: context,
  builder: (_) => const _CancelReasonDialog(),
);

class _CancelReasonDialog extends StatefulWidget {
  const _CancelReasonDialog();

  @override
  State<_CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<_CancelReasonDialog> {
  String _reason = kCancelReasons.first;
  final _other = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  void _confirm() {
    final r = _reason == 'Other' ? _other.text.trim() : _reason;
    if (r.isEmpty) {
      setState(() => _error = 'A reason is required.');
      return;
    }
    Navigator.pop(context, r);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel collection'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _reason,
            isExpanded: true,
            items: kCancelReasons
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (v) => setState(() {
              _reason = v ?? _reason;
              _error = null;
            }),
          ),
          if (_reason == 'Other') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _other,
              decoration: InputDecoration(
                hintText: 'Enter the reason',
                errorText: _error,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Keep'),
        ),
        FilledButton(onPressed: _confirm, child: const Text('Confirm cancel')),
      ],
    );
  }
}
