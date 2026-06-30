import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/legal/data/legal_repository.dart';
import '../../../../features/legal/domain/legal_page.dart';
import '../../../shared/theme/admin_theme.dart';

/// Create / edit dialog for one of the three legal pages. Always upserts
/// at the well-known doc id (e.g. `legalPages/privacy`), so there's no
/// risk of accidentally creating a second copy.
class EditLegalDialog extends ConsumerStatefulWidget {
  const EditLegalDialog({
    super.key,
    required this.pageId,
    required this.defaultTitle,
    this.existing,
  });

  final String pageId;
  final String defaultTitle;
  final LegalPage? existing;

  @override
  ConsumerState<EditLegalDialog> createState() => _EditLegalDialogState();
}

class _EditLegalDialogState extends ConsumerState<EditLegalDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _body;
  late final TextEditingController _version;
  late bool _published;
  bool _busy = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? widget.defaultTitle);
    _body = TextEditingController(text: e?.body ?? '');
    _version = TextEditingController(text: '${e?.version ?? 1}');
    _published = e?.published ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _version.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(legalRepositoryProvider);
      final page = LegalPage(
        id: widget.pageId,
        title: _title.text.trim(),
        body: _body.text,
        version: int.tryParse(_version.text) ?? 1,
        published: _published,
        effectiveFrom: DateTime.now(),
      );
      await repo.adminSave(page);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Page saved.' : 'Page created.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit
          ? 'Edit ${widget.defaultTitle}'
          : 'Create ${widget.defaultTitle}'),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Title is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _body,
                  decoration: const InputDecoration(
                    labelText: 'Body',
                    helperText:
                        'Plain text. Use blank lines to separate paragraphs. '
                        'Lines in ALL CAPS render as section headings.',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 18,
                  minLines: 12,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Body is required'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _version,
                        decoration: const InputDecoration(
                          labelText: 'Version',
                          helperText:
                              'Bump when the policy materially changes.',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SwitchListTile(
                        title: const Text('Published'),
                        subtitle: Text(
                          _published
                              ? 'Visible to users'
                              : 'Draft — hidden from users',
                        ),
                        value: _published,
                        contentPadding: EdgeInsets.zero,
                        onChanged: _busy
                            ? null
                            : (v) => setState(() => _published = v),
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style:
                          const TextStyle(color: AdminColors.danger)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEdit ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
