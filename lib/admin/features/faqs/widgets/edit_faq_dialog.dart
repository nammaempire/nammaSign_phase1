import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/help/data/faqs_repository.dart';
import '../../../../features/help/domain/help_faq.dart';
import '../../../shared/theme/admin_theme.dart';

/// Add-or-edit dialog. Pass `existing: faq` to edit; omit to create a new
/// one. Saves to `helpFaqs/{id}` via the admin repository.
class EditFaqDialog extends ConsumerStatefulWidget {
  const EditFaqDialog({super.key, this.existing});

  final HelpFaq? existing;

  @override
  ConsumerState<EditFaqDialog> createState() => _EditFaqDialogState();
}

class _EditFaqDialogState extends ConsumerState<EditFaqDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _question;
  late final TextEditingController _answer;
  late final TextEditingController _order;
  late FaqCategory _category;
  late bool _published;
  bool _busy = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _question = TextEditingController(text: e?.question ?? '');
    _answer = TextEditingController(text: e?.answer ?? '');
    _order = TextEditingController(text: '${e?.order ?? 10}');
    _category = e?.category ?? FaqCategory.booking;
    _published = e?.published ?? true;
  }

  @override
  void dispose() {
    _question.dispose();
    _answer.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(faqsRepositoryProvider);
      final faq = HelpFaq(
        id: widget.existing?.id ?? '',
        category: _category,
        question: _question.text.trim(),
        answer: _answer.text.trim(),
        order: int.tryParse(_order.text) ?? 10,
        published: _published,
        createdAt: widget.existing?.createdAt,
      );
      if (_isEdit) {
        await repo.adminUpdate(faq);
      } else {
        await repo.adminCreate(faq);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'FAQ updated.' : 'FAQ created.'),
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
      title: Text(_isEdit ? 'Edit FAQ' : 'Add new FAQ'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<FaqCategory>(
                  value: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final c in FaqCategory.displayOrder)
                      DropdownMenuItem(
                        value: c,
                        child: Row(
                          children: [
                            Icon(c.icon, size: 16),
                            const SizedBox(width: 8),
                            Text(c.label),
                          ],
                        ),
                      ),
                  ],
                  onChanged: _busy
                      ? null
                      : (v) => setState(
                            () => _category = v ?? FaqCategory.booking,
                          ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _question,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    hintText: 'e.g. How long does admin approval take?',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Question is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _answer,
                  decoration: const InputDecoration(
                    labelText: 'Answer',
                    hintText:
                        'Write the answer the way you would explain it to a customer.',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 6,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Answer is required'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _order,
                        decoration: const InputDecoration(
                          labelText: 'Display order',
                          helperText:
                              'Lower numbers appear first within their category.',
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
                  Text(
                    _error!,
                    style: const TextStyle(color: AdminColors.danger),
                  ),
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
              : Text(_isEdit ? 'Save changes' : 'Create FAQ'),
        ),
      ],
    );
  }
}
