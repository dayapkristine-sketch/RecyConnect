import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/feedback_model.dart';
import '../models/user_model.dart';
import '../providers/app_provider.dart';

const _starColor = Color(0xFFF5A623);

/// "Maria Santos" -> "Maria S."
String shortName(String full) {
  final parts = full.trim().split(RegExp(r'\s+'));
  if (parts.length < 2) return full.trim();
  return '${parts.first} ${parts.last[0]}.';
}

class StarDisplay extends StatelessWidget {
  const StarDisplay({super.key, required this.value, this.size = 16});
  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Icon(
            value >= i + 1
                ? Icons.star_rounded
                : value >= i + 0.5
                ? Icons.star_half_rounded
                : Icons.star_outline_rounded,
            size: size,
            color: _starColor,
          ),
      ],
    );
  }
}

class RatingLine extends StatelessWidget {
  const RatingLine({super.key, required this.average, required this.count});
  final double average;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return Text(
        'No ratings yet',
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StarDisplay(value: average),
        const SizedBox(width: 6),
        Text(
          '${average.toStringAsFixed(1)} ($count)',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class ReportChip extends StatelessWidget {
  const ReportChip(this.status, {super.key});
  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status == ReportStatus.open
        ? Colors.orange
        : status == ReportStatus.resolved
        ? const Color(0xFF2E9E57)
        : Colors.blueGrey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Rate sheet
// ---------------------------------------------------------------------
Future<void> showRateSheet(BuildContext context, AppUser provider) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _RateSheet(provider: provider),
  );
}

class _RateSheet extends StatefulWidget {
  const _RateSheet({required this.provider});
  final AppUser provider;

  @override
  State<_RateSheet> createState() => _RateSheetState();
}

class _RateSheetState extends State<_RateSheet> {
  final _comment = TextEditingController();
  int _stars = 0;
  bool _isUpdate = false;

  static const _labels = [
    'Tap a star',
    'Poor',
    'Fair',
    'Good',
    'Very good',
    'Excellent',
  ];

  @override
  void initState() {
    super.initState();
    final app = context.read<AppProvider>();
    final me = app.currentUser;
    final existing = me == null ? null : app.ratingBy(me, widget.provider);
    if (existing != null) {
      _stars = existing.stars;
      _comment.text = existing.comment;
      _isUpdate = true;
    }
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _submit() {
    final app = context.read<AppProvider>();
    final me = app.currentUser;
    if (me == null) return;
    final error = app.submitRating(
      from: me,
      to: widget.provider,
      stars: _stars,
      comment: _comment.text,
    );
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? 'Thanks! Your rating was saved.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isUpdate
                  ? 'Update your rating'
                  : 'Rate ${widget.provider.fullName}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_isUpdate)
              Text(
                widget.provider.fullName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    onPressed: () => setState(() => _stars = i),
                    icon: Icon(
                      i <= _stars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: _starColor,
                      size: 38,
                    ),
                  ),
              ],
            ),
            Text(_labels[_stars], textAlign: TextAlign.center),
            const SizedBox(height: 14),
            TextField(
              controller: _comment,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: 'Share your experience (optional)',
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _stars == 0 ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(_isUpdate ? 'Update rating' : 'Submit rating'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Report sheet
// ---------------------------------------------------------------------
Future<void> showReportSheet(BuildContext context, AppUser provider) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ReportSheet(provider: provider),
  );
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.provider});
  final AppUser provider;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _details = TextEditingController();
  String _reason = reportReasons.first;
  String? _error;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  void _submit() {
    if (_reason == 'Other' && _details.text.trim().length < 10) {
      setState(
        () => _error = 'Please describe the problem (at least 10 characters).',
      );
      return;
    }
    final app = context.read<AppProvider>();
    final me = app.currentUser;
    if (me == null) return;
    final error = app.submitReport(
      reporter: me,
      reported: widget.provider,
      reason: _reason,
      details: _details.text,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Report sent. The administrator will review it.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Report ${widget.provider.fullName}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Reports are private. Only the administrator can see them.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: muted),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _reason,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Reason',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              items: [
                for (final r in reportReasons)
                  DropdownMenuItem(value: r, child: Text(r)),
              ],
              onChanged: (v) => setState(() => _reason = v ?? _reason),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _details,
              maxLines: 4,
              maxLength: 300,
              decoration: const InputDecoration(
                hintText: 'Describe what happened',
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.send),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              label: const Text('Submit report'),
            ),
          ],
        ),
      ),
    );
  }
}
