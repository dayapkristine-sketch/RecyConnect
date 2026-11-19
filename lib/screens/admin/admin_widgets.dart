import 'package:flutter/material.dart';

import '../../models/user_model.dart';

class AdminColors {
  static const deep = Color(0xFF14573A);
  static const mid = Color(0xFF238B45);
  static const mint = Color(0xFFE3F3E8);
}

IconData roleIcon(UserRole role) {
  switch (role) {
    case UserRole.household:
      return Icons.home_outlined;
    case UserRole.collector:
      return Icons.local_shipping_outlined;
    case UserRole.junkShop:
      return Icons.storefront_outlined;
    case UserRole.admin:
      return Icons.admin_panel_settings_outlined;
  }
}

Color statusColor(AccountStatus s) {
  switch (s) {
    case AccountStatus.pending:
      return Colors.orange;
    case AccountStatus.approved:
      return const Color(0xFF2E9E57);
    case AccountStatus.rejected:
      return Colors.red;
    case AccountStatus.suspended:
      return Colors.blueGrey;
  }
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String formatDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

String formatDateTime(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  final ap = d.hour >= 12 ? 'PM' : 'AM';
  return '${formatDate(d)} • $h:$m $ap';
}

String timeAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hr ago';
  if (diff.inDays < 7) return '${diff.inDays} d ago';
  return formatDate(d);
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final AccountStatus status;

  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.actionLabel, this.onAction});
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: danger
              ? FilledButton.styleFrom(backgroundColor: Colors.red)
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Card showing one uploaded document (thumbnail + name). Tap to open viewer.
class DocumentTile extends StatelessWidget {
  const DocumentTile({super.key, required this.label, required this.document});
  final String label;
  final UploadedDoc? document;

  @override
  Widget build(BuildContext context) {
    final doc = document;
    if (doc == null) {
      return Card(
        color: Colors.red.withValues(alpha: 0.10),
        child: ListTile(
          leading: const Icon(Icons.error_outline, color: Colors.red),
          title: Text(label),
          subtitle: const Text('Not submitted'),
        ),
      );
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DocumentViewerPage(title: label, document: doc),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: doc.isImage
                      ? doc.remoteUrl != null
                            ? Image.network(
                                doc.remoteUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const Icon(Icons.broken_image_outlined),
                              )
                            : Image.memory(
                                doc.bytes,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const Icon(Icons.broken_image_outlined),
                              )
                      : Container(
                          color: AdminColors.mint,
                          child: Icon(
                            doc.isPdf
                                ? Icons.picture_as_pdf
                                : Icons.description_outlined,
                            color: AdminColors.deep,
                            size: 30,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      doc.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      doc.isImage
                          ? '${doc.sizeLabel} • Tap to view'
                          : '${doc.sizeLabel} • Preview not available',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.open_in_full, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen, pinch-to-zoom viewer for uploaded documents.
class DocumentViewerPage extends StatelessWidget {
  const DocumentViewerPage({
    super.key,
    required this.title,
    required this.document,
  });
  final String title;
  final UploadedDoc document;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: document.isImage
          ? InteractiveViewer(
              minScale: 0.5,
              maxScale: 6,
              child: Center(
                child: document.remoteUrl != null
                    ? Image.network(
                        document.remoteUrl!,
                        errorBuilder: (_, _, _) => const Text(
                          'This image could not be displayed.',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : Image.memory(
                        document.bytes,
                        errorBuilder: (_, _, _) => const Text(
                          'This image could not be displayed.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      document.isPdf
                          ? Icons.picture_as_pdf
                          : Icons.description_outlined,
                      color: Colors.white70,
                      size: 72,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      document.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${document.isPdf ? 'PDF' : 'Word'} preview is not available yet. '
                      'Ask the user to upload a clear photo (JPG/PNG) of the document so it can be verified.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
